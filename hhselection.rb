require 'net/http'
require 'json'
require 'axlsx'

def load_page(page)
  params = { area: 88, specialization: 1.221, only_with_salary: true, page: page }
  uri = URI.parse("https://api.hh.ru/vacancies")
  uri.query = URI.encode_www_form(params)
  JSON.load(Net::HTTP.get(uri))
end

def compute_salary(item)
  salary_to = item["salary"]["to"]
  salary_from = item["salary"]["from"]
  salary_to.nil? ? salary_from : salary_from.nil? ? salary_to : (salary_to + salary_from)/2
end

items = []
page_num = 0
loop do
  page = load_page(page_num)
  items.concat(page["items"])
  page_num += 1
  break if page_num == page["pages"]
end

languages = ['PHP', 'Python', 'C++', 'Java', 'Delphi', 'C', 'Javascript', '1C', '1С', 'C#', 'Ruby', 'Kotlin', 'Go', 'Haskell', 'Scala', 'Rust', 'OCaml', 'Perl', 'JS']

web = ['PHP', 'Pyhon', 'HTML', 'CSS', 'Ruby', 'Perl', 'Javascript', 'jQuery', 'ajax', 'JS', 'angular', 'фронт', 'фронт-енд', 'фронтенд', 'Yii', 'Laravel', 'Symfony', 'http', 'socket', 'cookie', 'nginx']
system_programming = ['C++', 'С++', 'с++', 'C', '1C', '1С', 'C#', 'Haskell', 'Java', 'Kotlin', 'Go', 'Scala', 'Rust', 'OCaml', 'Delphi']
web_counter = {zeroseven: 0, greater: 0}
sp_counter = {zeroseven: 0, greater: 0}
Axlsx::Package.new do |p|

  p.workbook.add_worksheet(name: "HHselection") do |sheet|
    sheet.add_row ['web', 'sp', 'всего']
    items.each do |item|
      created_at = DateTime.parse(item["created_at"])
      requirement = item['snippet']['requirement']
      p requirement
      web.each do |keyword|
        regexp = Regexp.new(/[^a-zA-Zа-яА-Я]+#{Regexp.escape(keyword)}[^a-zA-Zа-яА-Я#+]+/i)
        if !requirement.nil? and !requirement.match(regexp).nil?
          if (DateTime.now.to_time - created_at.to_time) / 24 / 60 / 60 > 7
            web_counter[:greater] += 1
          else
            web_counter[:zeroseven] += 1
          end
          break
        end
      end

      system_programming.each do |keyword|
        regexp = Regexp.new(/[^a-zA-Zа-яА-Я]+#{Regexp.escape(keyword)}[^a-zA-Zа-яА-Я#+]+/i)
        if !requirement.nil?
          requirement.match(regexp)
        end
        if !requirement.nil? and !requirement.match(regexp).nil?
          if (DateTime.now.to_time - created_at.to_time) / 24 / 60 / 60 > 7
            sp_counter[:greater] += 1
          else
            sp_counter[:zeroseven] += 1
          end
          break
        end

      end
      p web_counter
      p sp_counter
    end
    sheet.add_row [web_counter[:zeroseven], sp_counter[:zeroseven], web_counter[:zeroseven] + sp_counter[:zeroseven], '1-7 дней']
    sheet.add_row [web_counter[:greater], sp_counter[:greater], web_counter[:greater] + sp_counter[:greater], '8-INF дней']
    sheet.add_row [web_counter[:zeroseven] + web_counter[:greater], sp_counter[:greater] + sp_counter[:zeroseven], web_counter[:greater] + sp_counter[:greater] + web_counter[:zeroseven] + sp_counter[:zeroseven], 'всего']
  end

  p.serialize('hhselection.xlsx')
end

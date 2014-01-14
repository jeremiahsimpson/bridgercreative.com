require 'yaml'
require 'awesome_print'

input_file = File.join(File.dirname(__FILE__), '../_data/portfolios.yml')
output_dir = File.join(File.dirname(__FILE__), '../_projects')

portfolios = YAML.load(File.read(input_file))

portfolios.each do |portfolio|
  parts = portfolio['title'].downcase.gsub(/\s+/,'_').gsub(/\W+/,'').split('_')
  parts.insert(0, portfolio['date'].to_date.to_s)
  name = parts.join('-')
  file_name = File.join(output_dir, "#{name}.yml")
  portfolio['layout'] = 'project'
  File.open(file_name, 'w') { |f| YAML.dump(portfolio, f) }
end


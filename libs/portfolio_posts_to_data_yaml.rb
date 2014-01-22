require 'yaml'
# require 'awesome_print'

input_dir  = File.join(File.dirname(__FILE__), '../_posts/portfolio-item')
output_dir = File.join(File.dirname(__FILE__), '../_data')
delim = '---'
portfolios = []

Dir.glob("#{input_dir}/*").each do |path|
  item = File.read(path)
  contents = item.split(delim)
  front_matter = YAML.load(contents[1])

  puts "Treating #{front_matter['title']}..."
  
  # Remove keys we don't care for
  %w(layout status author author_login author_email wordpress_id wordpress_url comments).each do |key|
    front_matter.delete(key)
  end
  
  front_matter['description'] = contents.last
  
  portfolios << front_matter
end

File.open("#{output_dir}/portfolios.yml", 'w') { |f| YAML.dump(portfolios, f) }
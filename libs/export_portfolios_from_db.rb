require 'yaml'
require 'mysql2'
require 'awesome_print'
require 'html2markdown'
require 'json'

def client
  @client ||= Mysql2::Client.new({
    "database"   => "bridger",
    "username"     => "bridger",
    "password" => "Pav-ot-yish-O",
    "host"     => "localhost",
  })
end

def imgs_from_post_ids(ids)
  sql  = "select guid from wp_posts where ID in (#{ids.join(',')})"
  imgs = client.query(sql).map{ |i| {
    'type' => 'image',
    'url' => i['guid']
  }}
end

def import!
  portfolios = client.query("select * from wp_posts where post_type = 'portfolio-item' and post_status = 'publish'")
  portfolios.each do |p|
  
    content = {
      'layout' => "project", 
      'published' => true,
      'title' => p['post_title'],
      'name'  => p['post_name'],
      'description' => p['post_content'],
      'date' => p['post_date'],
      'categories' => [],
      'tags' => [],
      'credits' => [],
      'media' => [],
      'thumbnail' => nil,
      'banner' => nil,
      'banner_color' => nil,
      'banner_bg_image' => nil,
      'repeat_background' => false
    }
  
    # Get meta data
    meta_keys = %w(credits portfolio_image portfolio_item_images _thumbnail_id background_color repeatable_background_image)
    meta_sql  = "select * from wp_postmeta where post_id = #{p['ID']} and meta_key in ('#{meta_keys.join("','")}') and meta_value is not null and meta_value != ''"
    metas = client.query(meta_sql)
    metas.each do |meta|

      val = meta['meta_value']
      next if val.nil? || val.empty?
      
      case meta['meta_key'].to_sym
      when :credits
        # Deserialize and convert to markdown
        content['credits'] = JSON::parse(val).map {|c| HTMLPage.new(:contents =>c).markdown }
      
      when :portfolio_image
        content['thumbnail'] = imgs_from_post_ids([val]).first
      
      when :portfolio_item_images
        ids = JSON::parse(val)
        content['media'] = imgs_from_post_ids(ids)
      
      when :_thumbnail_id
        content['banner'] = imgs_from_post_ids([val]).first

      when :background_color
        content['banner_color'] = val
      
      when :repeatable_background_image
        content['banner_bg_image'] = imgs_from_post_ids([val]).first
      end
    
    end
  
    # Categories & Tags (lifted from the jekyll-import gem)
    cats_sql =
      "SELECT
         terms.name AS `name`,
         ttax.taxonomy AS `type`
       FROM
         wp_terms AS `terms`,
         wp_term_relationships AS `trels`,
         wp_term_taxonomy AS `ttax`
       WHERE
         trels.object_id = '#{p['ID']}' AND
         trels.term_taxonomy_id = ttax.term_taxonomy_id AND
         terms.term_id = ttax.term_id"
      
    categories = client.query(cats_sql)
    categories.each do |term|
      if term['type'] == "category"
        content['categories'] << term['name']
      elsif term['type'] == "post_tag"
        content['tags'] << term['name']
      end
    end
  
    output_file = "#{content['date'].to_date}-#{content['name']}.yml"
    output_path = File.join(File.dirname(__FILE__), '../_projects/', output_file)
  
    puts "Saving '#{output_file}'..."
    File.open(output_path, 'w') { |f| YAML.dump(content, f) }
  
  end
end

import!
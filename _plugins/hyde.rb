
module Jekyll
  module HydeFilter

    def int(input)
      input.to_int
    end
  
    def slug(obj)
      obj.to_s.downcase.gsub(/\W+/,'-').gsub(/(^-|-$)/,'')
    end

    def category_link(input)
      "<a href='#{site.config['category_dir']}#{slug(input)}'>#{input}</a>"
    end

    private
    
    def site
      @site ||= begin
        config = File.join(File.dirname(__FILE__), "../_config.yml")
        Jekyll::Site.new(Jekyll::Configuration::DEFAULTS.merge(YAML.load_file(config)))
      end
    end

  end
end

Liquid::Template.register_filter(Jekyll::HydeFilter)
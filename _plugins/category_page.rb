module Jekyll

  class CategoryPage < Page
    def initialize(site, base, dir, category, posts)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'post_category.html')
      self.data['category'] = category
      self.data['posts'] = posts

      category_title_prefix = site.config['category_title_prefix'] || 'Category: '
      self.data['title'] = "#{category_title_prefix}#{category}"
    end
    
  end

  class CategoryPageGenerator < Generator
    safe true

    def generate(site)
      if site.layouts.key? 'post_category'
        dir = site.config['category_dir'] || 'categories'
        site.categories.each do |category, posts|
          site.pages << CategoryPage.new(site, site.source, File.join(dir, slug(category)), category, posts)
        end
      end
    end

    private
    
    def slug(input)
      input.downcase.gsub(/\W+/,'-').gsub(/(^-|-$)/,'')
    end
    

  end

end
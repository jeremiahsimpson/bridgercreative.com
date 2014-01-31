require 'pry'

module Jekyll
  
  module ProjectsData

    def get_projects(site, taxonomy_singular = nil, taxonomy_plural = nil)
      {}.tap do |projects|
        dir = File.join(@base, './_projects/*.yml')
        Dir[dir].sort.reverse.each do |path|
          name   = File.basename(path, '.yml')
          config = YAML.load(File.read(path))
          if config['published']
            if taxonomy_plural.nil? || config_has_taxonomy(config, taxonomy_singular, taxonomy_plural)
              projects[name] = config
            end
          end
        end
      end
    end
    
    def slug(input)
      input.downcase.gsub(/\W+/,'-').gsub(/(^-|-$)/,'')
    end
    
    def taxonomy_dir(dir, collection_name, input)
      File.join(dir, collection_name, slug(input))
    end
    
    def config_has_taxonomy(config, singular, plural)
      term = self.data[singular]
      config[plural] && config[plural].include?(term)
    end
    
  end
  
  class PortfolioIndex < Page
    
    include ProjectsData
    
    def initialize(site, base, dir)
      @site = site
      @base = base
      @dir  = dir
      @name = "index.html"

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'portfolio.html')
      self.data['all_projects'] = get_projects(site)
      self.data['projects'] = self.data['all_projects']

      set_taxonomy('categories')
      set_taxonomy('tags')

    end

    def set_taxonomy(key)
      # Get uniq sorted list of matching terms
      collection = self.data['all_projects'].values.map{|p| p[key] }.flatten.uniq.sort
      # Format into nice name/url hashes for use in views
      self.data[key] = collection.map{ |t|
        {
          'name' => t,
          'url'  => taxonomy_dir('/our-work', key, t)
        }
      }
    end
    
  end

  class PortfolioCategoryIndex < PortfolioIndex

    def initialize(site, base, dir, category)
      @site     = site
      @base     = base
      @dir      = taxonomy_dir(dir, 'categories', category)
      @name     = "index.html"
      self.data = {}

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'project_category.html')

      self.data['category'] = category
      self.data['all_projects'] = get_projects(site)
      self.data['projects'] = get_projects(site, 'category', 'categories')

      set_taxonomy('categories')
      set_taxonomy('tags')

    end
    
  end

  class PortfolioTagIndex < PortfolioIndex
    def initialize(site, base, dir, tag)
      @site     = site
      @base     = base
      @dir      = taxonomy_dir(dir, 'tags', tag)
      @name     = "index.html"
      self.data = {}

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'project_category.html')

      self.data['tag'] = tag
      self.data['all_projects'] = get_projects(site)
      self.data['projects'] = get_projects(site, 'tag', 'tags')

      set_taxonomy('categories')
      set_taxonomy('tags')
      
    end
  end
  
  class Project < Page

    include ProjectsData
    
    def initialize(site, base, dir, path)
      @site     = site
      @base     = base
      @dir      = dir
      @name     = "index.html"
      self.data = YAML.load(File.read(File.join(@base, path)))

      # Merge in related projects
      self.data['related_projects'] = related_projects
      self.process(@name) if self.data['published']
    end
    
    def related_projects
      
      projects = get_projects(@site)
      tags = self.data['tags'] || []
      
      tag_freq = projects_tag_freq(projects)
      highest_freq = tag_freq.values.max
      
      related_scores = {}
      projects.each do |name, project|
        project['tags'].each do |tag|
          if tags.include?(tag) && project['title'] != self.data['title']
            cat_freq = tag_freq[tag]
            related_scores[name] = related_scores[name].to_i + (1+highest_freq-cat_freq)
          end
        end
      end
      
      sort_related_projects(related_scores, projects)
      
    end
    
    # Calculate the frequency of each tag.
    #
    # Returns {tag => freq, tag => freq, ...}
    def projects_tag_freq(projects)
      @tag_freq ||= begin
        @tag_freq = {}
        projects.each do |name, project|
          project['tags'].each {|tag| @tag_freq[tag] = @tag_freq[tag].to_i + 1}
        end
        @tag_freq
      end
    end

    # Sort the related projects in order of their score and date
    # and return just the projects
    def sort_related_projects(related_scores, projects)
      sorted_names = related_scores.sort_by { |name, score| score }.reverse
      sorted_names.map {|proj| 
        projects[proj.first]['path'] = proj.first # Insert the name/slug/path into the project hash
        projects[proj.first] 
      }
    end
    
  end

  class GeneratePortfolio < Generator
    safe true
    priority :normal

    def generate(site)
      self.write_portfolio(site)
    end

    # Loops through the list of project pages and processes each one.
    def write_portfolio(site)
      if Dir.exists?('_projects')
        Dir.chdir('_projects')
        Dir["*.yml"].each do |path|
          name = File.basename(path, '.yml')
          self.write_project_index(site, "_projects/#{path}", name)
        end

        Dir.chdir(site.source)
        self.write_portfolio_index(site)
        
      end
    end

    def write_portfolio_index(site)
      portfolio = PortfolioIndex.new(site, site.source, "/our-work")
      portfolio.render(site.layouts, site.site_payload)
      portfolio.write(site.dest)

      site.pages << portfolio
      site.static_files << portfolio
      
      self.write_portfolio_taxonomy_indexes(site, portfolio.data['categories'], PortfolioCategoryIndex)
      self.write_portfolio_taxonomy_indexes(site, portfolio.data['tags'], PortfolioTagIndex)
      
    end

    def write_portfolio_taxonomy_indexes(site, collection, klass)
      collection.each do |term|
        index = klass.new(site, site.source, "/our-work", term['name'])
        index.render(site.layouts, site.site_payload)
        index.write(site.dest)
        site.pages << index
        site.static_files << index
      end
    end
    
    def write_project_index(site, path, name)
      project = Project.new(site, site.source, "/our-work/#{name}", path)

      if project.data['published']
        project.render(site.layouts, site.site_payload)
        project.write(site.dest)

        site.pages << project
        site.static_files << project
      end
    end
  end
end

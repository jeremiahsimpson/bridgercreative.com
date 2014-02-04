# Title: Jekyll Image Tag
# Authors: Rob Wierzbowski : @robwierzbowski
#
# Description: Better images for Jekyll.
#
# Download: https://github.com/robwierzbowski/jekyll-image-tag
# Documentation: https://github.com/robwierzbowski/jekyll-image-tag/readme.md
# Issues: https://github.com/robwierzbowski/jekyll-image-tag/issues
#
# Syntax:  {% image [preset or WxH] path/to/img.jpg [attr="value"] %}
# Example: {% image poster.jpg alt="The strange case of Dr. Jekyll" %}
#          {% image gallery poster.jpg alt="The strange case of Dr. Jekyll" class="gal-img" data-selected %}
#          {% image 350xAUTO poster.jpg alt="The strange case of Dr. Jekyll" class="gal-img" data-selected %}
#
# See the documentation for full configuration and usage instructions.

require 'fileutils'
require 'pathname'
require 'digest/md5'
require 'mini_magick'
require 'fastimage'

# require 'pry'

module Jekyll

  module ImageGenerator

    def generate_image(instance, site_source, site_dest, image_source, image_dest)
      if instance[:src].match(/^http/)
        generate_remote_image(instance, site_source, site_dest, image_source, image_dest)
      else
        generate_local_image(instance, site_source, site_dest, image_source, image_dest)
      end
    end
    
    # Download remote files and pass onto local file thumbnail generator
    def generate_remote_image(instance, site_source, site_dest, image_source, image_dest)
      uri = URI(instance[:src])
      res = Net::HTTP.get_response(uri)

      # Raise if unable to download the image
      raise "Image Tag: Unable to fetch \"#{uri}\"! Please confirm the correct image URL: #{res.message}" unless res.class == Net::HTTPOK
      
      file_name  = File.basename(uri.path)
      image_path = File.join(site_source, image_source, file_name)
      
      # Write to a local file
      if !File.exists?(image_path)
        File.open(image_path, 'w') {|f| f.puts res.body }
      end
      
      instance[:src] = file_name
      
      generate_local_image(instance, site_source, site_dest, image_source, image_dest)
      
    end
    
    # Generate thumbnails for local images
    def generate_local_image(instance, site_source, site_dest, image_source, image_dest)
      image_path = File.join(site_source, image_source, instance[:src])

      raise "Image Tag: \"#{image_path}\" does not exist!" unless File.exist?(image_path)

      size = FastImage.size(image_path);

      image_dir = File.dirname(instance[:src])
      ext = File.extname(instance[:src])
      basename = File.basename(instance[:src], ext)

      orig_width = size[0].to_f
      orig_height = size[1].to_f
      orig_ratio = orig_width/orig_height

      gen_width = 0
      gen_height = 0

      # Handles the case where both width and height are auto
      if instance[:width] == "auto" && instance[:height] == "auto"

        gen_width = orig_width
        gen_height = orig_height

      # Otherwise processes per the config data
      else

        gen_width = instance[:width].to_f
        gen_height = instance[:height].to_f

        if gen_width == 0 and gen_height > 0   # Assumes auto for width
          gen_width = orig_ratio * gen_height
        elsif gen_width > 0 and gen_height == 0  # Assumes auto for height
          gen_height = gen_width / orig_ratio
        end
        gen_ratio = gen_width/gen_height

        # Don't allow upscaling. If the image is smaller than the requested dimensions, recalculate.
        if orig_width < gen_width || orig_height < gen_height
          undersize = true
          gen_width = if orig_ratio < gen_ratio then orig_width else orig_height * gen_ratio end
          gen_height = if orig_ratio > gen_ratio then orig_height else orig_width/gen_ratio end
        end

      end

      image_file = File.open(image_path, "r")
      image_file_contents = image_file.read

      digest = Digest::MD5.hexdigest(image_file_contents).slice!(0..5)

      gen_name = "#{basename}-#{gen_width.round}x#{gen_height.round}-#{digest}#{ext}"
      gen_dest_dir = File.join(site_dest, image_dest, image_dir)
      gen_dest_file = File.join(gen_dest_dir, gen_name)

      # Generate resized files
      unless File.exists?(gen_dest_file)

        image = MiniMagick::Image.open(File.join(site_source, image_source, instance[:src]))

        warn "Image Tag: #{instance[:src]} is smaller than the requested output file. It will be resized without upscaling." if undersize

        #  If the destination directory doesn't exist, create it
        FileUtils.mkdir_p(gen_dest_dir) unless File.exist?(gen_dest_dir)

        # Let people know their images are being generated
        puts "Generating #{gen_name}"

        # Scale and crop
        image.combine_options do |i|
          i.resize "#{gen_width}x#{gen_height}^"
          i.gravity "center"
          i.crop "#{gen_width}x#{gen_height}+0+0"
        end

        image.write gen_dest_file
      end

      # Return path relative to the site root for html
      Pathname.new(File.join('/', image_dest, image_dir, gen_name)).cleanpath
    end
    
    def dimensions_from_string(input)
      /^(?:(?<width>\d+)|auto)(?:x)(?:(?<height>\d+)|auto)$/i.match(input)
    end
    

  end
  
  class Image < Liquid::Tag
    
    include ImageGenerator
    
    def initialize(tag_name, markup, tokens)
      @markup = markup
      super
    end

    def render(context)

      # Render any liquid variables in tag arguments and unescape template code
      render_markup = Liquid::Template.parse(@markup).render(context).gsub(/\\\{\\\{|\\\{\\%/, '\{\{' => '{{', '\{\%' => '{%')

      # Gather settings
      site = context.registers[:site]
      settings = site.config['image']
      markup = /^(?:(?<preset>[^\s.:\/]+)\s+)?(?<image_src>[^\s]+\.[a-zA-Z0-9]{3,4})\s*(?<html_attr>[\s\S]+)?$/.match(render_markup)

      raise "Image Tag: can't read this tag. Try {% image [preset or WxH] path/to/img.jpg [attr=\"value\"] %}." unless markup

      preset = if settings.key?('presets') && settings['presets'].is_a?(Hash)
        settings['presets'][ markup[:preset] ]
      end

      # Assign defaults
      settings['source'] ||= '.'
      settings['output'] ||= 'generated'

      # Prevent Jekyll from erasing our generated files
      site.config['keep_files'] << settings['output'] unless site.config['keep_files'].include?(settings['output'])

      # Process instance
      instance = if preset
        {
          :width => preset['width'],
          :height => preset['height'],
          :src => markup[:image_src]
        }
      elsif dim = dimensions_from_string(markup[:preset])
        {
          :width => dim['width'],
          :height => dim['height'],
          :src => markup[:image_src]
        }
      else
        { :src => markup[:image_src] }
      end

      # Process html attributes
      html_attr = if markup[:html_attr]
        Hash[ *markup[:html_attr].scan(/(?<attr>[^\s="]+)(?:="(?<value>[^"]+)")?\s?/).flatten ]
      else
        {}
      end

      if preset && preset['attr']
        html_attr = preset['attr'].merge(html_attr)
      end

      html_attr_string = html_attr.inject('') { |string, attrs|
        if attrs[1]
          string << "#{attrs[0]}=\"#{attrs[1]}\" "
        else
          string << "#{attrs[0]} "
        end
      }

      # Raise some exceptions before we start expensive processing
      raise "Image Tag: can't find the \"#{markup[:preset]}\" preset. Check image: presets in _config.yml for a list of presets." unless preset || dim ||  markup[:preset].nil?

      # Generate resized images
      generated_path = generate_image(instance, site.source, site.dest, settings['source'], settings['output'])

      # Generate the string represenation of the total path
      if settings['use_full_url']
        generated_src = site.config['url'] + generated_path.to_s
      else
        generated_src = generated_path.to_s
      end

      # Return the markup!
      "<img src=\"#{generated_src}\" #{html_attr_string}>"
    end

  end
  
  module ImageURL

    include ImageGenerator
    
    def image_url(path, size = nil)

      return if path.nil?

      # instance => {:width=>"280", :height=>nil, :src=>"/portfolio/gallery_cr_1.jpg"}
      # site.source => "/Users/supagroova/Development/html/bridger"
      # settings['source'] => "assets/site_images/"
      # settings['output'] => "img"
      settings = site.config['image']
      preset = if settings.key?('presets') && settings['presets'].is_a?(Hash)
        settings['presets'][path]
      end

      # Assign defaults
      settings['source'] ||= '.'
      settings['output'] ||= 'generated'

      instance = { :src => path }
      sizes    = if preset
        {
          :width => preset['width'],
          :height => preset['height'],
        }
      elsif size && dim = dimensions_from_string(size)
        {
          :width => dim['width'],
          :height => dim['height']
        }
      else
        {}
      end
      instance.merge!(sizes)

      # Generate resized images
      generated_path = generate_image(instance, site.config['source'], site.config['destination'], settings['source'], settings['output'])

      # Generate the string represenation of the total path
      if settings['use_full_url']
        site.config['url'] + generated_path.to_s
      else
        generated_path.to_s
      end

    end
    
    private
    
    def config
      @config ||= begin
        file = File.join(File.dirname(__FILE__), "../_config.yml")
        Jekyll::Configuration::DEFAULTS.merge(YAML.load_file(file))
      end
    end
    

  end
  
end

Liquid::Template.register_tag('image', Jekyll::Image)
Liquid::Template.register_filter(Jekyll::ImageURL)
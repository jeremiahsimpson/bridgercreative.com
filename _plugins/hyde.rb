
module Jekyll
  module HydeFilter

    def int(input)
      input.to_int
    end
  
    def slug(obj)
      obj.to_s.downcase.gsub(/\W+/,'-').gsub(/(^-|-$)/,'')
    end


  end
end

Liquid::Template.register_filter(Jekyll::HydeFilter)
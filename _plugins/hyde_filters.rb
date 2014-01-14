module HydeLiquidFilters

  def to_int(input)
    input.to_int
  end
  
end

Liquid::Template.register_filter HydeLiquidFilters
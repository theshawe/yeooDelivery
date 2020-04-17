require 'json'

module Jekyll
  class MapTag < Liquid::Tag

    MapData = Struct.new(:title, :latitude, :longitude, :layers, :locations, :zoom)

    def initialize(name, params, tokens)
      @config = Jekyll.configuration({})['mapping']
      @engine = @config['provider']
      @key    = @config['api_key']

      if @config.has_key?('zoom')
        @zoom = @config['zoom']
      else
        @zoom = '10'
      end

      default_width  = '400'
      default_height = '400'

      if @config['dimensions']
        @width  = @config['dimensions']['width'] || default_width
        @height = @config['dimensions']['height'] || default_height
      end

      unless params.empty?
        params_hash = split_params(params)
        @width  = params_hash['width'] if params_hash['width']
        @height = params_hash['height'] if params_hash['height']
        @map_to_render = params_hash['title']
      end

      super
    end

    def split_params(params)
      params_hash = {}
      params.split(',').map(&:strip).each do |param|
        key, value = param.split(':').map(&:strip)
        params_hash[key] = value
      end
      params_hash
    end

    def render(context)
      maps = []
      mapping_options = context['page']['mapping']

      if mapping_options
        if mapping_options.is_a? Hash
          m           = MapData.new
          m.title     = mapping_options['title'] || context['page']['title']
          m.latitude  = mapping_options['latitude']
          m.longitude = mapping_options['longitude']
          m.layers    = json_string(mapping_options['layers'])
          m.locations = json_string(mapping_options['locations'])
          m.zoom      = mapping_options.has_key?('zoom') ? mapping_options['zoom'] : @zoom
          maps.push m
        elsif mapping_options.is_a? Array
          mapping_options.each do |map_data|
            m           = MapData.new
            m.title     = map_data['title'] || context['page']['title']
            m.latitude  = map_data['latitude']
            m.longitude = map_data['longitude']
            m.layers    = json_string(map_data['layers'])
            m.locations = json_string(map_data['locations'])
            m.zoom      = map_data.has_key?('zoom') ? map_data['zoom'] : @zoom
            maps.push m
          end
        end

        if @map_to_render
          maps.select { |item| item.title.match(/#{@map_to_render.downcase.strip}/i) }.each do |map_data|
            return map_markup(map_data)
          end
        else
          output = ""
          maps.each do |map_data|
            output += map_markup(map_data)
          end
          output
        end
      end
    end

    def json_string(obj)
      JSON.generate(obj).to_s if obj
    end

    def map_markup(map_data)
      if @engine == 'google_static'
        "<img src=\"http://maps.googleapis.com/maps/api/staticmap?markers=#{map_data.latitude},#{map_data.longitude}&size=#{@width}x#{@height}&zoom=#{map_data.zoom}&sensor=false\">"
      elsif (@engine == 'google_js') || (@engine == 'openstreetmap')
        "<div class='jekyll-mapping'
              data-latitude='#{map_data.latitude}'
              data-longitude='#{map_data.longitude}'
              data-layers='#{map_data.layers}'
              data-locations='#{map_data.locations}'
              data-title='#{map_data.title}'
              data-zoom='#{map_data.zoom}'
              style='height:#{@height}px;width:#{@width}px;'></div>"
      end
    end
  end
end

Liquid::Template.register_tag('render_maps', Jekyll::MapTag)

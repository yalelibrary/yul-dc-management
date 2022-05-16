# frozen_string_literal: true

class Geojson
  attr_reader :valid, :coords, :type

  def initialize(n, e, s, w)
    p1 = convert_point([e, n])
    p2 = convert_point([w, s])

    if valid_point?(p1)
      @valid = true
      if !valid_point?(p2) || (p1 == p2)
        @type = "Point"
        @coords = p1
      else
        @type = "Polygon"
        @coords = to_polygon(p1, p2)
      end
    else
      @valid = false
      @coords = []
    end
  end

  def convert_point(p)
    p.each_with_index do |v, i|
      if v.class.equal?(String)
        if v.starts_with?('N', 'S', 'E', 'W')
          p[i] = Float(v[1..3] + '.' + v[4..-1], exception: false)
        elsif v =~ /[0-9]+[.]?[0-9]*/
          p[i] = Float(v, exception: false)
        end
      end
    end
  end

  def valid_point?(p)
    p.each do |c|
      return false unless value_is_numeric(c)
    end
    return false if (p[1] > 90) || (p[1] < -90) || (p[0] > 180) || (p[0] < -180) || p.length != 2
    true
  end

  def value_is_numeric(v)
    v && (v.class.equal?(Float) || v.class.equal?(Integer))
  end

  def to_polygon(c1, c2)
    poly = []
    poly << [c1[0], c1[1]]
    poly << [c2[0], c1[1]]
    poly << [c2[0], c2[1]]
    poly << [c1[0], c2[1]]
    poly << [c1[0], c1[1]]
    [poly]
  end

  def as_featurecollection
    return [] unless @valid
    {
      'type' => 'FeatureCollection',
      'features' => [
        {
          'type' => 'Feature',
          'properties' => {},
          'geometry' => {
            'type' => @type,
            'coordinates' => @coords
          }
        }
      ]
    }
  end
end

class Geojson
  attr_reader :valid, :coords, :type

  def initialize(n, e, s, w)
    p1 = convert_point([n,e])
    p2 = convert_point([s,w])

    if valid_point?(p1)
      @valid = true
      if !valid_point?(p2) or (p1 == p2)
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
    p.each_with_index do |v,i|
      if v.class.equal?(String)
        if v.starts_with?('N','S','E','W')
          p[i] = Float(v[1..3] + '.' + v[4..-1])
        elsif v.match(/[0-9]+[.]?[0-9]*/)
          p[i] = Float(v)
        end
      end
    end
  end

  def valid_point?(p)
    return false unless p.length == 2
    p.each do |c|
      return false unless c and (c.class.equal?(Float) or c.class.equal?(Integer))
    end
    return false if p[0] > 90 or p[0] < -90
    return false if p[1] > 180 or p[1] < -180
    true
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
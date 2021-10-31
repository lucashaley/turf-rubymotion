# https://github.com/DevRhys/iosvoronoi/blob/master/Example/iosvoronoi/BHEVoronoiCellTower.h
class Pylon < Site # move away from the Site superclass?
  attr_accessor :location,
                :color,
                :title, # not sure what this is for
                :lifespan

  def self.initWithLocation(location, color = "1.0 0.1 0.1 0.3", title = "MungMung")
    # puts "\nPylon::initWithLocation location:#{location}, color: #{color}"
    p = Pylon.alloc.init
    # puts "New Pylon: #{p.description}"
    p.location = location

    # Double-wrapping the color because Apple
    p.color = UIColor.alloc.initWithCIColor(CIColor.alloc.initWithString(color))
    p.title = title
    # check if location is a CLLocation?
    # @location = location
    # map_point = MKMapPointForCoordinate(@location)
    # self = self.initWithCoord(CGPointMake(map_point.x, map_point.y))

    # @title = title
    # @color = color
    # uuID = NSUUID.UUID()

    # map_point = MKMapPointForCoordinate(location.coordinate)
    # map_point = MKMapPointForCoordinate(location)
    # setCoord(CGPointMake(map_point.x, map_point.y))
    map_point = MKMapPointForCoordinate(location)
    # self.setCoord(CGPointMake(map_point.x, map_point.y))
    # puts "Pylon::initialize coord:#{self.coord.x}, #{self.coord.y}"

    p.setCoord(CGPointMake(map_point.x, map_point.y))
    return p
  end

  def distance_from_pylon(pylon)
    # puts "Pylon::distance_from_pylon"
    unless @location.nil?
      return distance_from_location(pylon.location)
    end
    return -1
  end
  alias :distanceFromPylon :distance_from_pylon

  def distance_from_location(location)
    # puts "Pylon::distance_from_location"
    unless @location.nil?
      return @location.distance_from_location(location)
    end
    return -1
  end
  alias :distanceFromLocation :distance_from_location

  def to_s
    "Pylon: UUID: #{uuID.UUIDString}; Location: #{@location.latitude}, #{@location.longitude}; Coord: #{coord.x}, #{coord.y}; Color: #{@color}"
  end

  def setLocation(location)
    # puts "Pylon::setLocation"
    map_point = MKMapPointForCoordinate(location)
    setCoord(CGPointMake(map_point.x, map_point.y))
    @location = location
  end

  def to_hash
    _hue, _saturation, _brightness, _alpha = Pointer.new(:double)
    _r, _g, _b, _a = Pointer.new(:double)
    _h = Hash.new
    _h[:title] = @title
    puts "color raw: #{@color.CIColor}"
    # _result = @color.getHue(_hue, saturation:_saturation, brightness:_brightness, alpha:_alpha)
    # puts _result
    # puts _hue.value
    # puts _saturation.value
    # puts _brightness.value
    # puts _alpha.value
    # puts "color: #{hue}, #{_saturation}"
    # _h[:color] = { "hue"=>_hue[0], "saturation"=>_saturation[0], "brightness"=>_brightness[0], "alpha"=>_alpha[0] }
    # _result = @color.getRed(_r, green:_g, blue:_b, alpha:_a)
    # puts _result
    # puts _r.value
    # puts _g.value
    # puts _b.value
    # puts _a.value
    # _h[:color] = {"r"=>_r.value, "g"=>_g.value, "b"=>_b.value, "a"=>_a.value}
    puts @color.CIColor.stringRepresentation
    _h[:color] = @color.CIColor.stringRepresentation
    _h[:location] = { "latitude"=>@location.latitude, "longitude"=>@location.longitude }
    _h
  end
end

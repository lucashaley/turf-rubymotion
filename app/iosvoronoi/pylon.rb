# https://github.com/DevRhys/iosvoronoi/blob/master/Example/iosvoronoi/BHEVoronoiCellTower.h
class Pylon < Site # move away from the Site superclass?
  attr_accessor :location,
                :color,
                :title, # not sure what this is for
                :lifespan,
                :birthdate

  def self.initWithLocation(location, color = "1.0 0.1 0.1 0.3", title = "MungMung")
    p = Pylon.alloc.init
    p.location = location

    # Double-wrapping the color because Apple
    p.color = UIColor.alloc.initWithCIColor(CIColor.alloc.initWithString(color))
    p.title = title

    map_point = MKMapPointForCoordinate(location)
    # self.setCoord(CGPointMake(map_point.x, map_point.y))
    # puts "Pylon::initialize coord:#{self.coord.x}, #{self.coord.y}"

    p.setCoord(CGPointMake(map_point.x, map_point.y))
    p.birthdate = Time.now
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
    _h[:color] = @color.CIColor.stringRepresentation
    _h[:location] = { "latitude"=>@location.latitude, "longitude"=>@location.longitude }
    _h[:birthdate] = @birthdate.utc.to_a
    _h
  end
end

# https://github.com/DevRhys/iosvoronoi/blob/master/Example/iosvoronoi/BHEVoronoiCellTower.h
class Pylon < Site # move away from the Site superclass?
  attr_accessor :location, :color, :title # not sure what this is for

  def self.initWithLocation(location, color = UIColor.systemRedColor)
    puts "\nPylon::initWithLocation location:#{location}, color: #{color}"
    p = Pylon.alloc.init
    puts "New Pylon: #{p.description}"
    p.location = location
    p.color = color
    p.title = "MungMung"
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
    puts "Pylon::distance_from_pylon"
    unless @location.nil?
      return distance_from_location(pylon.location)
    end
    return -1
  end
  alias :distanceFromPylon :distance_from_pylon

  def distance_from_location(location)
    puts "Pylon::distance_from_location"
    unless @location.nil?
      return @location.distance_from_location(location)
    end
    return -1
  end
  alias :distanceFromLocation :distance_from_location

  def to_s
    "UUID: #{uuID.UUIDString}; Location: #{@location.latitude}, #{@location.longitude}; Coord: #{coord.x}, #{coord.y}; Color: #{@color}\n\n"
  end

  def setLocation(location)
    puts "Pylon::setLocation"
    map_point = MKMapPointForCoordinate(location)
    setCoord(CGPointMake(map_point.x, map_point.y))
    @location = location
  end
end

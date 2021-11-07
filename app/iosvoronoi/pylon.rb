# https://github.com/DevRhys/iosvoronoi/blob/master/Example/iosvoronoi/BHEVoronoiCellTower.h
class Pylon < Site # move away from the Site superclass?
  attr_accessor :location,
                :color,
                :title, # not sure what this is for
                :lifespan,
                :birthdate,
                :lifespan_multiplier,
                :machine

  def self.initWithHash(args = {})
    puts "Pylon initialize"
    puts "args: #{args}"
    puts "latitude: #{args[:location][:latitude]}"
    p = Pylon.alloc.init
    p.location = args[:location]?
      CLLocationCoordinate2DMake(
        args[:location][:latitude],
        args[:location][:longitude])
      : CLLocationCoordinate2DMake(37.33189332651307, -122.03128724123847)
    p.color = args[:color]? UIColor.alloc.initWithCIColor(CIColor.alloc.initWithString(args[:color])) : UIColor.systemYellowColor
    p.title = args[:title] || "MungMung"
    p.lifespan = args[:lifespan] || 10
    p.lifespan_multiplier = 0.3
    p.birthdate = args[:birthdate] || Time.now

    _map_point = MKMapPointForCoordinate(p.location)
    p.setCoord(CGPointMake(_map_point.x, _map_point.y))

    p.machine= StateMachine::Base.new start_state: :active, verbose: true
    p.machine.when :active do |state|
      # state.on_entry { puts "PYLON MACHINE ENTRY" }
      # state.on_exit { puts "PYLON MACHINE EXIT" }
      state.transition_to :dying,
        after: p.lifespan * 0.5,
        action: Proc.new { App.notification_center.post 'PylonChange' }
    end
    p.machine.when :dying do |state|
      state.on_entry { p.lifespan_multiplier = 0.15 }
      state.transition_to :inactive,
        after: p.lifespan * 0.5,
        action: Proc.new { App.notification_center.post 'PylonChange' }
    end
    p.machine.when :inactive do |state|
      state.on_entry { p.lifespan_multiplier = 0.05 }
    end
    p.machine.start!
    App.notification_center.post 'PylonChange'
    return p
  end

  # REFACTOR convert to *args
  def self.initWithLocation(location, color = "1.0 0.1 0.1 0.3", title = "MungMung")
    puts "Pylon initWithLocation"
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
    p.lifespan = 10
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

  def lifespan_color
    @lifespan_multiplier? @color.colorWithAlphaComponent(@lifespan_multiplier) : @color
    # return @color.colorWithAlphaComponent(@lifespan_multiplier)
  end

  def set_uuid(new_uuid)
    self.uuID = NSUUID.alloc.initWithUUIDString(new_uuid)
  end
end

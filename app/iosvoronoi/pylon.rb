# https://github.com/DevRhys/iosvoronoi/blob/master/Example/iosvoronoi/BHEVoronoiCellTower.h
class Pylon < Site # move away from the Site superclass?
  attr_accessor :location,
                :annotation,
                :color,
                :title, # not sure what this is for
                :lifespan,
                :birthdate,
                :lifespan_multiplier,
                :machine

  DEBUGGING = false

  def self.initWithHash(args = {})
    puts "PYLON: INITWITHHASH".green if DEBUGGING
    puts "args: #{args}".green if DEBUGGING

    p = Pylon.alloc.init

    # But sometimes we do pass a Location
    case args[:location]
      when CLLocationCoordinate2D
        # puts "CLLocationCoordinate2D"
        p.location = args[:location]
      when Hash
        # puts "Hash"
        p.location = CLLocationCoordinate2DMake(
          args[:location][:latitude],
          args[:location][:longitude])
      else
        # puts "Empty?"
        p.location = CLLocationCoordinate2DMake(37.33189332651307, -122.03128724123847)
    end
    # switching to CIColor
    # p.color = args[:color]? UIColor.alloc.initWithCIColor(CIColor.alloc.initWithString(args[:color])) : UIColor.systemYellowColor
    p.color = args[:color]? CIColor.alloc.initWithString(args[:color]) : CIColor.alloc.initWithColor(UIColor.systemYellowColor)
    p.title = args[:title] || "MungMung"
    p.lifespan = args[:lifespan] || 10
    p.lifespan_multiplier = 0.3
    p.birthdate = args[:birthdate] || Time.now
    # p.uuID = args[:uuid] || NSUUID.alloc.init # don't need this, Site super takes care of it?

    _map_point = MKMapPointForCoordinate(p.location)
    p.setCoord(CGPointMake(_map_point.x, _map_point.y))

    p.machine= StateMachine::Base.new start_state: :active, verbose: DEBUGGING
    p.machine.when :active do |state|
      # state.on_entry { puts "PYLON MACHINE ENTRY" }
      # state.on_exit { puts "PYLON MACHINE EXIT" }
      state.transition_to :dying,
        after: p.lifespan * 0.5,
        if: proc { p.lifespan > 0 },
        action: Proc.new { App.notification_center.post 'PylonChange' }
    end
    p.machine.when :dying do |state|
      state.on_entry { p.lifespan_multiplier = 0.15 }
      state.transition_to :inactive,
        after: p.lifespan * 0.5,
        action: Proc.new { App.notification_center.post 'PylonChange' }
    end
    p.machine.when :inactive do |state|
      # state.on_entry { p.lifespan_multiplier = 0.01 }
      state.on_entry do
        p.lifespan_multiplier = 0.01
        puts "\nPylon Death: #{p}\n"
        App.notification_center.post('PylonDeath', object:p)
      end
    end
    p.machine.start!

    return p
  end

  # REFACTOR convert to *args
  def self.initWithLocation(location, color = "1.0 0.1 0.1 0.3", title = "MungMung")
    puts "PYLON: INITWITHLOCATION".green if DEBUGGING
    p = Pylon.alloc.init
    p.location = location

    # Double-wrapping the color because Apple
    # p.color = UIColor.alloc.initWithCIColor(CIColor.alloc.initWithString(color))
    p.color = CIColor.alloc.initWithString(color)
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
    "Pylon: UUID: #{uuID.UUIDString}; Location: #{@location.latitude}, #{@location.longitude}; Coord: #{coord.x}, #{coord.y}; Color: #{@color}; Annotation: #{annotation}"
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
    # _h[:color] = @color.CIColor.stringRepresentation
    _h[:color] = @color.stringRepresentation
    _h[:location] = { "latitude"=>@location.latitude, "longitude"=>@location.longitude }
    _h[:birthdate] = @birthdate.utc.to_a
    _h
  end

  def lifespan_color
    puts "PYLON: LIFESPAN_COLOR".blue if DEBUGGING
    # @lifespan_multiplier? @color.colorWithAlphaComponent(@lifespan_multiplier) : @color
    # return @color.colorWithAlphaComponent(@lifespan_multiplier)

    # Switching to CIColor
    _color = UIColor.alloc.initWithCIColor(@color)
    return @lifespan_multiplier? _color.colorWithAlphaComponent(@lifespan_multiplier) : _color
  end

  def set_uuid(new_uuid)
    self.uuID = NSUUID.alloc.initWithUUIDString(new_uuid)
  end

  def set_annotation(new_annotation)
    puts "PYLON SET_ANNOTATION".blue if DEBUGGING
    @annotation = new_annotation # if new_annotation.class == MKAnnotation
  end

  def get_uicolor
    UIColor.colorWithCIColor(@color)
    # UIColor.alloc.initWithCIColor(@color)
  end
end

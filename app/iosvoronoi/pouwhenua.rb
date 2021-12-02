# == POUWHENUA
# This is the marker, which has a particular location. This location contributes
# to the creation of the Voronoi map through the Wakawaka area.
class Pouwhenua < Site # Fake subclass of Site
  extend Debugging

  attr_accessor :location,
    :annotation,
    :color,
    :title, # not sure what this is for
    :lifespan,
    :birthdate,
    :lifespan_multiplier,
    :machine

    DEBUGGING = true

    # == INITIALIZE
    # This is the basic way of creating a Pouwhenua.
    # It expects at least latitude and longitude, which ends up as a CGPoint
    # And accepts a Hash for options.
    # The potential options include:
    # - color as an RGBA string
    # - title as a string
    # - lifespan as a number
    # - birthdate as a DateTime
    def initialize(coords, args = {})
      puts "POUWHENUA INITIALIZE".green if DEBUGGING

      puts "coords: #{coords}".green if DEBUGGING
      puts "args: #{args}".green if DEBUGGING
      symbol_args = args ? recursive_symbolize_keys(args) : {}
      puts "Pouwhenua symbol_args: #{symbol_args}".red if DEBUGGING

      # @site = Site.new

      # check for what kind of coords we got
      case coords
        when CLLocationCoordinate2D
          puts "CLLocationCoordinate2D"
          # @location = CLLocation.alloc.initWithLatitude(coords.latitude, longitude: coords.longitude)
          @location = coords
        when Hash
          puts "Hash"
          puts coords["latitude"]
          puts coords["longitude"]
          # @location = CLLocation.alloc.initWithLatitude(
          #   coords["latitude"], longitude: coords["longitude"]
          # )
          @location = CLLocationCoordinate2DMake(coords["latitude"], coords["longitude"])
        else
          puts "Empty?"
          # @location = CLLocation.alloc.initWithLatitude(37.33190, longitude: -122.03129)
          @location = CLLocationCoordinate2DMake(37.33190, longitude: -122.03129)
      end
      map_point = MKMapPointForCoordinate(@location)
      super(CGPointMake(map_point.x, map_point.y))

      @color = symbol_args[:color] ? CIColor.alloc.initWithString(args[:color]) : CIColor.alloc.initWithColor(UIColor.systemYellowColor)
      @title = symbol_args[:title] || "Pouwhenua"
      @lifespan = symbol_args[:lifespan] || 0
      @lifespan_multiplier = 0.3
      @birthdate = symbol_args[:birthdate] || Time.now

      # Set up the machine
      @machine = StateMachine::Base.new start_state: :active, verbose: DEBUGGING
      @machine.when :active do |state|
        # state.on_entry { puts "PYLON MACHINE ENTRY" }
        # state.on_exit { puts "PYLON MACHINE EXIT" }
        state.transition_to :dying,
          after: @lifespan * 0.5,
          if: proc { @lifespan > 0 },
          action: proc { App.notification_center.post "PylonChange" }
      end
      @machine.when :dying do |state|
        state.on_entry { p.lifespan_multiplier = 0.15 }
        state.transition_to :inactive,
          after: @lifespan * 0.5,
          action: proc { App.notification_center.post "PylonChange" }
      end
      @machine.when :inactive do |state|
        # state.on_entry { p.lifespan_multiplier = 0.01 }
        state.on_entry do
          p.lifespan_multiplier = 0.01
          puts "\nPylon Death: #{self}\n"
          App.notification_center.post("PylonDeath", object: self)
        end
      end
      @machine.start!
    end

    ### Shit from Pylon ###

    def distance_from_pylon(pylon)
      puts "POUWHENUA DISTANCE_FROM_PYLON".blue if DEBUGGING

      return distance_from_location(pylon.location) unless @location.nil?
      -1
    end
    alias :distanceFromPylon :distance_from_pylon

    def distance_from_location(location)
      puts "POUWHENUA DISTANCE_FROM_LOCATION".blue if DEBUGGING

      return @location.distance_from_location(location) unless @location.nil?
      -1
    end
    alias :distanceFromLocation :distance_from_location

    def set_location(location)
      puts "POUWHENUA SET_LOCATION".blue if DEBUGGING

      map_point = MKMapPointForCoordinate(location)
      setCoord(CGPointMake(map_point.x, map_point.y))
      @location = location
    end
    alias :setLocation :set_location

    def lifespan_color
      puts "POUWHENUA LIFESPAN_COLOR".blue if DEBUGGING

      color = UIColor.alloc.initWithCIColor(@color)
      return @lifespan_multiplier ? color.colorWithAlphaComponent(@lifespan_multiplier) : color
    end

    def set_uuid(new_uuid)
      puts "POUWHENUA SET_UUID".blue if DEBUGGING

      puts "new_uuid: #{new_uuid}"
      # @site.uuID = NSUUID.alloc.initWithUUIDString(new_uuid)
      @uuid = NSUUID.alloc.initWithUUIDString(new_uuid)
      puts "uuid: #{@uuid}"
    end
    # def uuid
    #   @site.uuID
    # end
    # alias :uuID :uuid
    # def uuid_string
    #   @site.uuID.UUIDString
    # end

    def set_annotation(new_annotation)
      puts "POUWHENUA SET_ANNOTATION".blue if DEBUGGING

      @annotation = new_annotation # if new_annotation.class == MKAnnotation
    end

    def get_uicolor
      puts "POUWHENUA GET_UICOLOR".blue if DEBUGGING

      UIColor.colorWithCIColor(@color)
    end

    def to_hash
      puts "POUWHENUA TO_HASH".blue if DEBUGGING

      pouwhenua_hash = {}
      pouwhenua_hash[:title] = @title
      pouwhenua_hash[:color] = @color.stringRepresentation
      # pouwhenua_hash[:location] = {latitude: @location.coordinate.latitude,
        # longitude: @location.coordinate.longitude}
      pouwhenua_hash[:location] = {latitude: @location.latitude, longitude: @location.longitude}
      pouwhenua_hash[:birthdate] = @birthdate.utc.to_a
      pouwhenua_hash
    end

    def recursive_symbolize_keys(h)
      case h
      when Hash
        Hash[
          h.map do |k, v|
            [ k.respond_to?(:to_sym) ? k.to_sym : k, recursive_symbolize_keys(v) ]
          end
        ]
      when Enumerable
        h.map { |v| recursive_symbolize_keys(v) }
      else
        h
      end
    end


    # ### Shit from Site ###
    # def init_with_coord(tempCoord)
    #   puts "POUWHENUA INIT_WITH_COORD".green if DEBUGGING
    # end
    # alias :initWithCoord :init_with_coord
    #
    # def init_with_value(valueWithCoord)
    #   puts "POUWHENUA INIT_WITH_VALUE".green if DEBUGGING
    # end
    # alias :initWithValue :init_with_value
    #
    # def set_coord(tempCoord)
    #   puts "POUWHENUA SET_COORD".blue if DEBUGGING
    #   @site.setCoord(tempCoord)
    # end
    # alias :setCoord :set_coord
    # def coord
    #   puts "POUWHENUA COORD".blue if DEBUGGING
    #   @site.coord
    # end
    #
    # def set_coord_as_value(value_with_coord)
    #   puts "POUWHENUA SET_COORD_AS_VALUE".blue if DEBUGGING
    #   @site.setCoordAsValue(value_with_coord)
    # end
    # alias :setCoordAsValue :set_coord_as_value
    # def coord_as_value
    #   puts "POUWHENUA COORD_AS_VALUE".blue if DEBUGGING
    #   @site.coordAsValue
    # end
    # alias :coordAsValue :coord_as_value
    #
    # def set_x(temp_x)
    #   puts "POUWHENUA SET_X".blue if DEBUGGING
    #   @site.setX(temp_x)
    # end
    # alias :setX :set_x
    # def x
    #   puts "POUWHENUA X".blue if DEBUGGING
    #   @site.x
    # end
    #
    # def set_y(temp_y)
    #   puts "POUWHENUA SET_Y".blue if DEBUGGING
    #   @site.setY(temp_y)
    # end
    # alias :setY :set_y
    # def y
    #   puts "POUWHENUA Y".blue if DEBUGGING
    #   @site.y
    # end
    #
    # def sort_sites(site_array)
    #   puts "POUWHENUA SORT_SITES".blue if DEBUGGING
    #   @site.sort_sites(site_array)
    # end
    # alias :sortSites :sort_sites
    # def compare(s)
    #   puts "POUWHENUA COMPARE".blue if DEBUGGING
    #   @site.compare(s)
    # end
    #
    # def setVoronoiId(in_value)
    #   puts "POUWHENUA SETVORONOIID".blue if DEBUGGING
    #   puts "in_value: #{in_value}"
    #   @site.setVoronoiId(in_value)
    # end
    # def voronoiId
    #   @site.voronoiId
    # end
end

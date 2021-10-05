class GameController < UIViewController
  extend IB

  outlet :map_view, MKMapView
  outlet :button_pylon, UIButton

  def viewDidLoad
    # https://stackoverflow.com/questions/6020612/mkmapkit-not-showing-userlocation
    map_view.showsUserLocation = true

    location = CLLocationCoordinate2D.new
    location.latitude = -41.302220
    location.longitude = 174.775456
    puts "Location: #{location}"

    span = MKCoordinateSpan.new
    span.latitudeDelta = 0.005
    span.longitudeDelta = 0.005
    puts "Span: #{span}"

    region = MKCoordinateRegion.new
    region.span = span
    region.center = location

    map_view.setRegion(region, animated:true)
    map_view.regionThatFits(region)

    @button_fsm = StateMachine::Base.new start_state: :up, verbose: true
    @button_fsm.when :up do |state|
      state.on_entry { set_button_color(UIColor.systemBlueColor) }
      state.transition_to :down,
        on: :button_down
    end
    @button_fsm.when :down do |state|
      state.on_entry { set_button_color(UIColor.systemRedColor) }
      state.transition_to :primed,
        after: 5
      state.transition_to :up,
        on: :button_up
    end
    @button_fsm.when :primed do |state|
      state.on_entry { set_button_color(UIColor.systemGreenColor) }
      state.transition_to :up,
        on: :button_up
    end

    @button_fsm.start!
  end

  def locationUpdate(location)
    loc = location.coordinate
    map_view.setCenterCoordinate(loc)
  end

  def touch_down
    puts "touch down"
    @button_fsm.event(:button_down)
  end

  def touch_up
    puts "touch up"
    @button_fsm.event(:button_up)
  end

  def touch_out
    puts "touch out"
    @button_fsm.event(:button_up)
  end

  def set_button_color(color)
    button_pylon.tintColor = color
  end
end

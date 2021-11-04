class GameController < UIViewController
  extend IB
  include VoronoiUtilities

  outlet :map_view, MKMapView
  outlet :button_pylon, UIButton

  attr_accessor :voronoi_map,
                :player_location

  def viewWillAppear(animated)
    puts "\n\nGameController::viewWillAppear\n\n"
    # https://stackoverflow.com/questions/6020612/mkmapkit-not-showing-userlocation
    map_view.showsUserLocation = true
    map_view.showsPitchControl = true
    initialize_location_manager
    add_overlays_and_annotations

    @local_player = Player.new

    # AUDIO SETUP
    boundary_audio = player_for_audio("boundary")

    # THIS WORKED
    # Machine.instance.db_game_ref.child("pylons/pylon-03").setValue("Hairline")
    Machine.instance.db_game_ref.observeEventType(FIRDataEventTypeValue, withBlock:Machine.instance.handleDataResult)

    # Testing NSNotifications
    # PYLON CHANGE
    @pylon_observer = App.notification_center.observe "PylonChange" do |notification|
      puts "PYLON CHANGE"

      # render the wakawaka and annotations
      renderOverlays
    end
    # BOUNDARY EXIT
    @exit_observer = App.notification_center.observe "BoundaryExit" do |notification|
      puts "BOUNDARY EXIT"

      # trying sounds
      puts "Playing Sound"
      boundary_audio.play

      # set the player state

      # disable the pylon button
      button_pylon.enabled = false

      # mark the player's last location
    end
    # BOUNDARY ENTER
    @enter_observer = App.notification_center.observe "BoundaryEnter" do |notification|
      puts "BOUNDARY ENTER"

      # set the player state

      # enable the pylon button
      button_pylon.enabled = true

      # remove the players last location
    end
    # PLAYER DISAPPEAR
    @disappear_observer = App.notification_center.observe "PlayerDisappear" do |notification|
      puts "PLAYER DISAPPEAR"

      # set the player state

      # disable the pylon button
      # button_pylon.enabled = false

      # mark the player's last location
    end
    # PLAYER APPEAR
    @appear_observer = App.notification_center.observe "PlayerAppear" do |notification|
      puts "PLAYER APPEAR"

      # set the player state

      # enable the pylon button
      button_pylon.enabled = true

      # remove the players last location
    end
  end

  def viewDidLoad
    puts "\n\nGameController::viewDidLoad\n\n"

    region = create_play_region
    map_view.setRegion(region, animated:false)
    # map_view.regionThatFits(region) # this adjusts the region to fir the current view
    Machine.instance.bounding_box = mkmaprect_for_coord_region(region)
    @voronoi_map = VoronoiMap.new

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
        on: :button_up,
        action: proc { create_new_pylon }
    end

    puts "Starting button state machine\n\n"
    @button_fsm.start!

    # TEST PYLONS
    test_dict = Hash.new
    test_pylon_01 = Pylon.initWithHash({:location=>CLLocationCoordinate2DMake(37.33374960204376, -122.03019990835675), :color=>"0.1 0.1 1.0 0.3", :title=>"Jenny"})
    test_pylon_02 = Pylon.initWithHash({:location=>CLLocationCoordinate2DMake(37.333062054067, -122.03113705459889), :color=>"0.1 0.1 1.0 0.3", :title=>"Lame-o", :lifespan=>6})
    test_pylon_03 = Pylon.initWithLocation(CLLocationCoordinate2DMake(37.33224134831166, -122.03311472880185), "0.1 0.1 1.0 0.3", "Jenny")
    test_pylon_04 = Pylon.initWithLocation(CLLocationCoordinate2DMake(37.33077886077367, -122.03048131661657), "0.1 0.1 1.0 0.3", "Gilbert")
    test_pylon_05 = Pylon.initWithLocation(CLLocationCoordinate2DMake(37.33316896808407, -122.02850863291272))
    test_pylon_06 = Pylon.initWithLocation(CLLocationCoordinate2DMake(37.33085252713372, -122.02833842959912), "0.1 0.1 1.0 0.3", "Gilbert")
    test_pylon_07 = Pylon.initWithLocation(CLLocationCoordinate2DMake(37.33432727342505, -122.03242334715573))
    test_pylon_08 = Pylon.initWithLocation(CLLocationCoordinate2DMake(37.33096123684747, -122.03426217107544))
    test_pylon_09 = Pylon.initWithLocation(CLLocationCoordinate2DMake(37.3357776539391, -122.02908752007481))
    test_dict[test_pylon_01.uuID] = test_pylon_01
    test_dict[test_pylon_02.uuID] = test_pylon_02
    test_dict[test_pylon_03.uuID] = test_pylon_03
    test_dict[test_pylon_04.uuID] = test_pylon_04
    test_dict[test_pylon_05.uuID] = test_pylon_05
    test_dict[test_pylon_06.uuID] = test_pylon_06
    test_dict[test_pylon_07.uuID] = test_pylon_07
    test_dict[test_pylon_08.uuID] = test_pylon_08
    test_dict[test_pylon_09.uuID] = test_pylon_09

    # test_dict.each do |k, v|
    #   puts "\ntest_dict::pylon: #{k.UUIDString}\n#{v}"
    # end
    # @pylon_annotation_view = MKAnnotationView.initWithAnnotation(PylonAnnotation, reuseIdentifier: "PylonAnnotationView")
    map_view.registerClass(PylonAnnotation, forAnnotationViewWithReuseIdentifier: "PylonAnnotation")
    test_dict.each do |k, v|
      @voronoi_map.pylons.setObject(v, forKey:k)
      map_view.addAnnotation(PylonAnnotation.new(v).annotation)
    end

    vcells = @voronoi_map.voronoi_cells_from_pylons(test_dict)

    vcells.each do |vc|
      map_view.addOverlay(vc.overlay)
    end
  end


  ### LOCATION MANAGER DELEGATES ###
  # https://github.com/HipByte/RubyMotionSamples/blob/a387842594fd0ac9d8560d2dc64eff4d87534093/ios/Locations/app/locations_controller.rb
  def locationManager(manager, didUpdateToLocation:newLocation, fromLocation:oldLocation)
    # puts "GameController.didUpdateLocation: #{newLocation} to: #{oldLocation}"

    # Check if we are outside the bounds of play
    # unless MKMapRectContainsPoint(Machine.instance.bounding_box, MKMapPointForCoordinate(newLocation.coordinate))
    #   App.notification_center.post 'BoundaryExit'
    # end
    if MKMapRectContainsPoint(Machine.instance.bounding_box, MKMapPointForCoordinate(newLocation.coordinate))
      @local_player.machine.event(:enter_bounds)
    else
      @local_player.machine.event(:exit_bounds)
    end
    locationUpdate(newLocation)
  end

  def locationManager(manager, didFailWithError:error)
    puts "\n\nOOPS LOCATION MANAGER FAIL\n\n"
    App.notification_center.post "PlayerDisappear"
  end

  def locationUpdate(location)
    loc = location.coordinate
    @player_location = location.coordinate
    @local_player.location = location
    # map_view.setCenterCoordinate(loc)
  end

  PylonViewIdentifier = 'PylonViewIdentifier'
  def mapView(map_view, viewForAnnotation:annotation)
    # puts "\n\nviewForAnnotation"
    # if annotation.kind_of?
    if annotation == map_view.userLocation
      puts "PLAYER"
      return nil
    end
    # puts "viewForAnnotation: #{annotation.class}"
    # check to see if it exists and has been queued
    if annotation_view = map_view.dequeueReusableAnnotationViewWithIdentifier(PylonViewIdentifier)
      # puts "using existing view"
      annotation_view.annotation = pylon
    else
      # create a new one
      # MKPinAnnotationView is depreciated
      # puts "create new view"
      # annotation_view = MKMarkerAnnotationView.alloc.initWithAnnotation(annotation, reuseIdentifier:PylonViewIdentifier)
      annotation_view = MKAnnotationView.alloc.initWithAnnotation(annotation, reuseIdentifier:PylonViewIdentifier)
      annotation_view.image = UIImage.imageNamed("pylon_test_01.png")
      annotation_view.canShowCallout = false
    end
    annotation_view
  end

  def mapView(map_view, didAddAnnotationViews:views)
    # puts "didAddAnnotationViews!!"
  end

  def mapView(map_view, rendererForOverlay:overlay)
    # puts "rendererForOverlay: #{overlay}"
    rend = MKPolygonRenderer.alloc.initWithOverlay(overlay)
    rend.lineWidth = 0.75
    rend.strokeColor = UIColor.colorWithHue(0.5, saturation: 0.9, brightness: 0.9, alpha: 1.0)
    # overlay.fillColor = UIColor.systemGreenColor
    rend.fillColor = UIColor.colorWithHue(0.2, saturation: 0.9, brightness: 0.9, alpha: 0.3)
    unless overlay.overlayColor.nil?
      rend.fillColor = overlay.overlayColor
    end
    rend.lineJoin = KCGLineJoinMiter

    return rend
  end

  # REFACTOR with method below?
  def renderOverlays
    # puts "\n\nrenderOverlays"
    overlaysToRemove = map_view.overlays.mutableCopy
    map_view.removeOverlays(overlaysToRemove)

    vcells = @voronoi_map.voronoiCells

    vcells.each do |cell|
      map_view.addOverlay(cell.overlay)
    end
  end

  def create_new_pylon
    puts "create_new_pylon"
    # Ahh this is the cultprit
    # p = Pylon.initWithLocation(map_view.centerCoordinate)
    p = Pylon.initWithLocation(@player_location)
    @voronoi_map.pylons.setObject(p, forKey:p.uuID)
    map_view.addAnnotation(PylonAnnotation.new(p).annotation)
    self.renderOverlays
    new_path = "pylons/#{p.uuID.UUIDString}"
    puts "new_path: #{new_path}"
    Machine.instance.db_game_ref.child(new_path).setValue(p.to_hash)
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

  def initialize_location_manager
    puts "initialize_location_manager"
    @location_manager ||= CLLocationManager.alloc.init.tap do |lm|
      lm.requestWhenInUseAuthorization

      # constant needs to be capitalized because?
      lm.desiredAccuracy = KCLLocationAccuracyBest
      lm.startUpdatingLocation
      lm.delegate = self
    end
  end

  def add_overlays_and_annotations
    puts "add_overlays_and_annotations"
    add_overlays
    add_annotations
  end
  def add_overlays
    puts "add_overlays"
    @voronoi_map.voronoi_cells.each do |cell|
      map_view.addOverlay(cell.overlay)
    end
  end
  def add_annotations
    puts "add_annotations"
    map_view.addAnnotations(@voronoi_map.annotations)
  end

  def create_play_region(args = {})
    puts "create_play_region"
    location = args[:location] || CLLocationCoordinate2DMake(37.33189332651307, -122.03128724123847)
    span = args[:span] || MKCoordinateSpanMake(0.01, 0.01)
    region = MKCoordinateRegionMake(location, span)
  end

  def player_for_audio(filename)
    sound_path = NSBundle.mainBundle.pathForResource(filename, ofType:"mp3")
    sound_url = NSURL.fileURLWithPath(sound_path)
    error_ptr = Pointer.new(:object)
    player_audio = AVAudioPlayer.alloc.initWithContentsOfURL(sound_url, error:error_ptr)
    puts "AVAudioPlayer error: #{error_ptr[0]}"
    return player_audio
  end
end

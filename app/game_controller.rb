class GameController < UIViewController
  extend IB
  extend Debugging
  include VoronoiUtilities

  outlet :map_view, MKMapView
  outlet :button_pylon, UIButton

  attr_accessor :voronoi_map,
                :game,
                :player_location

  DEBUGGING = true

  def viewWillAppear(animated)
    puts "GAME_CONTROLLER: VIEWWILLAPPEAR".light_blue
    # https://stackoverflow.com/questions/6020612/mkmapkit-not-showing-userlocation
    map_view.showsUserLocation = true
    map_view.showsPitchControl = true
    initialize_location_manager
    add_overlays_and_annotations


    # Start observing
    puts "Trying to start observing"
    Machine.instance.game.start_observing_pylons

    @local_player = Player.new

    # AUDIO SETUP
    boundary_audio = player_for_audio("boundary")

    # THIS WORKED
    # Machine.instance.db_game_ref.child("pylons/pylon-03").setValue("Hairline")
    # Machine.instance.db_game_ref.observeEventType(FIRDataEventTypeValue,
    #   withBlock: Machine.instance.handleDataResult)

    # Testing NSNotifications
    # PYLON NEW
    @pylon_new_observer = App.notification_center.observe "PylonNew" do |notification|
      puts "PYLON NEW".yellow

      handle_new_pylon({:uuID => notification.object.key}.merge notification.object.value)
    end
    # PYLON CHANGE
    @pylon_observer = App.notification_center.observe "PylonChange" do |notification|
      puts "PYLON CHANGE".yellow

      # render the wakawaka and annotations
      renderOverlays
    end
    @pylon_death_observer = App.notification_center.observe "PylonDeath" do |notification|
      puts "PYLON DEATH".yellow
      puts "notification: #{notification.object[:object]}"
      # remove the pylon from the array
      # test_dict.delete(notification.object.uuid)
      _removed_pylon = @voronoi_map.pylons.delete(notification.object[:object].uuID)
      puts "_removed_pylon: #{_removed_pylon}"
      # redraw everything
      puts "\nRemoving annotation? #{notification.object[:object].annotation}"
      map_view.removeAnnotation(notification.object[:object].annotation)
      renderOverlays
      add_overlays_and_annotations
    end
    # BOUNDARY EXIT
    @exit_observer = App.notification_center.observe "BoundaryExit" do |notification|
      puts "BOUNDARY EXIT".yellow

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
      puts "BOUNDARY ENTER".yellow

      # set the player state

      # enable the pylon button
      button_pylon.enabled = true

      # remove the players last location
    end
    # PLAYER DISAPPEAR
    @disappear_observer = App.notification_center.observe "PlayerDisappear" do |notification|
      puts "PLAYER DISAPPEAR".yellow

      # set the player state

      # disable the pylon button
      # button_pylon.enabled = false

      # mark the player's last location
    end
    # PLAYER APPEAR
    @appear_observer = App.notification_center.observe "PlayerAppear" do |notification|
      puts "PLAYER APPEAR".yellow

      # set the player state

      # enable the pylon button
      button_pylon.enabled = true

      # remove the players last location
    end
  end

  def viewDidLoad
    puts "GAMECONTROLLER: VIEWDIDLOAD".light_blue
    Machine.instance.current_view = self

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

    add_overlays_and_annotations

  end


  ### LOCATION MANAGER DELEGATES ###

  ### Start up the Location Manager ###
  ### This has now moved into the Machine ###
  # def initialize_location_manager
  #   puts "initialize_location_manager"
  #   @location_manager ||= CLLocationManager.alloc.init.tap do |lm|
  #     lm.requestWhenInUseAuthorization
  #
  #     # constant needs to be capitalized because?
  #     lm.desiredAccuracy = KCLLocationAccuracyBest
  #     lm.startUpdatingLocation
  #     lm.delegate = self
  #   end
  #   map_view.registerClass(PylonAnnotation, forAnnotationViewWithReuseIdentifier: "PylonAnnotation")
  # end

  ### Get new location information ###
  ### This has now moved into the Machine ###
  # https://github.com/HipByte/RubyMotionSamples/blob/a387842594fd0ac9d8560d2dc64eff4d87534093/ios/Locations/app/locations_controller.rb
  # def locationManager(manager, didUpdateToLocation:newLocation, fromLocation:oldLocation)
  #   # puts "GameController.didUpdateLocation: #{newLocation} to: #{oldLocation}"
  #
  #   # Check if we are outside the bounds of play
  #   # unless MKMapRectContainsPoint(Machine.instance.bounding_box, MKMapPointForCoordinate(newLocation.coordinate))
  #   #   App.notification_center.post 'BoundaryExit'
  #   # end
  #   if MKMapRectContainsPoint(Machine.instance.bounding_box, MKMapPointForCoordinate(newLocation.coordinate))
  #     @local_player.machine.event(:enter_bounds)
  #   else
  #     @local_player.machine.event(:exit_bounds)
  #   end
  #   locationUpdate(newLocation)
  # end
  #
  # def locationManager(manager, didFailWithError:error)
  #   puts "\n\nOOPS LOCATION MANAGER FAIL\n\n"
  #   App.notification_center.post "PlayerDisappear"
  # end
  #
  # def locationUpdate(location)
  #   loc = location.coordinate
  #   @player_location = location.coordinate
  #   @local_player.location = location
  #   # map_view.setCenterCoordinate(loc)
  # end

  PylonViewIdentifier = 'PylonViewIdentifier'

  ### Makes an annotation image for the map ###
  def mapView(map_view, viewForAnnotation:annotation)

    if annotation == map_view.userLocation
      puts "PLAYER"
      return nil
    end
    # puts "viewForAnnotation: #{annotation.class}"
    # check to see if it exists and has been queued
    if annotation_view = map_view.dequeueReusableAnnotationViewWithIdentifier(PylonViewIdentifier)
      # puts "using existing view"
      # annotation_view.annotation = pylon # what does this line do?
    else
      # create a new one
      # MKPinAnnotationView is depreciated
      # puts "create new view"
      # annotation_view = MKMarkerAnnotationView.alloc.initWithAnnotation(annotation, reuseIdentifier:PylonViewIdentifier)
      annotation_view = MKAnnotationView.alloc.initWithAnnotation(annotation, reuseIdentifier:PylonViewIdentifier)

      # use png
      # annotation_view.image = UIImage.imageNamed("pylon_test_01.png")
      # dynamically generate
      ui_renderer = UIGraphicsImageRenderer.alloc.initWithSize(CGSizeMake(16, 16))

      annotation_view.image = ui_renderer.imageWithActions(
        lambda do |context|
          path = UIBezierPath.bezierPathWithRoundedRect(CGRectMake(1, 1, 14, 14), cornerRadius: 4)
          # UIColor.blueColor.setFill
          annotation.color.setStroke
          path.stroke
        end
      )

      annotation_view.canShowCallout = false
    end
    annotation_view
  end

  ### Called after annotations have been added ###
  def mapView(map_view, didAddAnnotationViews:views)
    # puts "didAddAnnotationViews!!"
  end

  def mapView(map_view, rendererForOverlay:overlay)
    # puts "GAME_CONTROLLER: MAPVIEW.RENDERFOROVERLAY"
    rend = MKPolygonRenderer.alloc.initWithOverlay(overlay)
    rend.lineWidth = 0.75
    rend.strokeColor = UIColor.colorWithHue(0.5, saturation: 0.9, brightness: 0.9, alpha: 1.0)
    # overlay.fillColor = UIColor.systemGreenColor
    rend.fillColor = UIColor.colorWithHue(0.2, saturation: 0.9, brightness: 0.9, alpha: 0.3)
    unless overlay.overlayColor.nil?
      rend.fillColor = UIColor.colorWithCGColor(overlay.overlayColor.CGColor)
    end
    rend.lineJoin = KCGLineJoinMiter

    return rend
  end

  # REFACTOR with method below?
  def renderOverlays
    puts "GAME_CONTROLLER RENDEROVERLAYS".blue if DEBUGGING

    if map_view.overlays then
      overlaysToRemove = map_view.overlays.mutableCopy
      map_view.removeOverlays(overlaysToRemove)
    end

    # This is a hack to get past having one pylon
    return if @voronoi_map.pylons.length < 2

    vcells = @voronoi_map.voronoiCells

    vcells.each do |cell|
      map_view.addOverlay(cell.overlay)
    end
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

  def add_overlays_and_annotations
    puts "add_overlays_and_annotations"
    add_overlays
    add_annotations
  end
  def add_overlays
    puts "GAME_CONTROLLER: ADD_OVERLAYS".blue if DEBUGGING
    @voronoi_map.voronoi_cells.each do |cell|
      map_view.addOverlay(cell.overlay)
    end
  end
  def add_annotations
    puts "GAME_CONTROLLER: ADD_ANNOTATIIONS".blue if DEBUGGING
    map_view.addAnnotations(@voronoi_map.annotations)
  end

  def create_play_region(args = {})
    puts "GAME_CONTROLLER: CREATE_PLAY_REGION".blue if DEBUGGING
    location = args[:location] || CLLocationCoordinate2DMake(37.33189332651307, -122.03128724123847)
    span = args[:span] || MKCoordinateSpanMake(0.01, 0.01)
    region = MKCoordinateRegionMake(location, span)
  end

  def player_for_audio(filename)
    sound_path = NSBundle.mainBundle.pathForResource(filename, ofType:"mp3")
    sound_url = NSURL.fileURLWithPath(sound_path)
    error_ptr = Pointer.new(:object)
    player_audio = AVAudioPlayer.alloc.initWithContentsOfURL(sound_url, error:error_ptr)
    puts "AVAudioPlayer error: #{error_ptr[0]}" if error_ptr[0]
    return player_audio
  end

  def create_new_pylon
    puts "GAME_CONTROLLER: CREATE_NEW_PYLON".blue if DEBUGGING

    # this gets it into the DB, but not on screen
    # @fb_game.create_new_pylon(@player_location)
    Machine.instance.create_new_pylon(@player_location)
  end

  def handle_new_pylon(data)
    puts "GAME_CONTROLLER: HANDLE_NEW_PYLON".blue if DEBUGGING

    _p = Pylon.initWithHash(data)
    _p.set_uuid data[:uuID]

    @voronoi_map.add_pylon(_p)

    renderOverlays
  end
end

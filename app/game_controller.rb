class GameController < MachineViewController
  include VoronoiUtilities

  outlet :map_view, MKMapView
  outlet :button_pylon, UIButton

  attr_accessor :voronoi_map,
                :game,
                :player_location

  DEBUGGING = true
  PYLON_VIEW_IDENTIFIER = 'PylonViewIdentifier'.freeze

  def setup_mapview
    map_view.showsUserLocation = true
    map_view.showsPitchControl = false
  end

  def setup_audio
    @boundary_audio = player_for_audio('boundary')

    @boundary_audio.numberOfLoops = -1  # looping
    @boundary_audio.prepareToPlay       # make sure it's ready
  end

  # rubocop:disable Metrics/AbcSize
  def init_observers
    @map_refresh = App.notification_center.observe 'MapRefresh' do |_notification|
      puts 'map_refresh'.focus
      observe_new_pouwhenua
    end
    @pouwhenua_new_observer = App.notification_center.observe 'PouwhenuaNew' do |_notification|
      puts 'pouwhenua_new_observer'.focus
      observe_new_pouwhenua
    end
    @pouwhenuafbo_new_observer = App.notification_center.observe 'PouwhenuaFbo_New' do |_notification|
      puts 'pouwhenuafbo_new_observer'.focus
      observe_new_pouwhenua
    end
    @pouwhenua_child_observer = App.notification_center.observe 'PouwhenuaFbo_ChildAdded' do |_notification|
      puts 'pouwhenua_child_observer'.focus
      observe_new_pouwhenua
    end

    @player_new_observer = App.notification_center.observe 'PlayerNew' do |_notification|
      puts 'NEW PLAYER'
    end
    # BOUNDARY EXIT
    @exit_observer = App.notification_center.observe 'BoundaryExit' do |_notification|
      @boundary_audio.play

      # disable the pylon button
      button_pylon.enabled = false

      # mark the player's last location
    end
    # BOUNDARY ENTER
    @enter_observer = App.notification_center.observe 'BoundaryEnter' do |_notification|
      @boundary_audio.stop
      # enable the pylon button
      button_pylon.enabled = true

      # remove the players last location
    end
    # PLAYER DISAPPEAR
    @disappear_observer = App.notification_center.observe 'PlayerDisappear' do |_notification|
      # puts 'PLAYER DISAPPEAR'.yellow

      # set the player state

      # disable the pylon button
      # button_pylon.enabled = false

      # mark the player's last location
    end
    # PLAYER APPEAR
    @appear_observer = App.notification_center.observe 'PlayerAppear' do |_notification|
      # puts 'PLAYER APPEAR'.yellow

      # set the player state

      # enable the pylon button
      button_pylon.enabled = true

      # remove the players last location
    end

    @placement_observer = App.notification_center.observe 'CrossedPlacementLimit' do |_notification|
      @button_fsm.event(:button_cancel)
    end
  end
  # rubocop:enable Metrics/AbcSize

  def viewWillAppear(_animated)
    puts 'GAME_CONTROLLER: VIEWWILLAPPEAR'.light_blue

    # https://stackoverflow.com/questions/6020612/mkmapkit-not-showing-userlocation
    setup_mapview

    add_overlays_and_annotations

    render_overlays
  end

  # rubocop:disable Metrics/AbcSize
  def viewDidLoad
    super
    puts 'GAMECONTROLLER: VIEWDIDLOAD'.light_blue

    Machine.instance.is_playing = true

    map_view.setRegion(Machine.instance.takaro_fbo.taiapa_region, animated: false)
    map_view.setCameraBoundary(
      MKMapCameraBoundary.alloc.initWithCoordinateRegion(Machine.instance.takaro_fbo.taiapa_region),
      animated: true
    )

    init_observers
    setup_audio

    @voronoi_map = VoronoiMap.new

    @button_fsm = StateMachine::Base.new start_state: :up, verbose: true
    @button_fsm.when :up do |state|
      state.on_entry { button_up }
      state.transition_to :down,
                          on: :button_down
    end
    @button_fsm.when :down do |state|
      state.on_entry { button_down }
      state.transition_to :primed,
                          after: Machine.instance.takaro_fbo.local_kaitakaro.deploy_time
      state.transition_to :up,
                          on: :button_up
      state.transition_to :up,
                          on: :button_cancel
    end
    @button_fsm.when :primed do |state|
      state.on_entry { button_color(UIColor.systemGreenColor) }
      state.transition_to :placing,
                          on: :button_up
      state.transition_to :up,
                          on: :button_cancel
    end
    @button_fsm.when :placing do |state|
      state.on_entry { handle_new_pouwhenua }
      state.transition_to :up,
                          # this is a hack to get around thread timing
                          after: 0.2
    end

    # puts 'Starting button state machine'
    @button_fsm.start!

    add_overlays_and_annotations
  end

  def button_down
    puts 'GameController button_down'.red

    # change the button color
    button_color(UIColor.systemRedColor)

    Machine.instance.takaro_fbo.local_kaitakaro.placing(true)
  end

  def button_up
    puts 'GameController button_up'.red

    # change the button color
    button_color(UIColor.systemBlueColor)

    Machine.instance.takaro_fbo.local_kaitakaro.placing(true)
  end

  ### Makes an annotation image for the map ###
  def mapView(map_view, viewForAnnotation: annotation)
    # puts 'GAME_CONTROLLER: MAPVIEW.VIEWFORANNOTATION'.blue if DEBUGGING
    return nil if annotation == map_view.userLocation

    # puts "viewForAnnotation: #{annotation.class}"
    # check to see if it exists and has been queued
    if annotation_view = map_view.dequeueReusableAnnotationViewWithIdentifier(PYLON_VIEW_IDENTIFIER)
     else
      annotation_view = MKAnnotationView.alloc.initWithAnnotation(annotation, reuseIdentifier: PYLON_VIEW_IDENTIFIER)

      ui_renderer = UIGraphicsImageRenderer.alloc.initWithSize(CGSizeMake(16, 16))

      annotation_view.image = ui_renderer.imageWithActions(
        lambda do |_context|
          path = UIBezierPath.bezierPathWithRoundedRect(CGRectMake(1, 1, 14, 14), cornerRadius: 4)
          # UIColor.blueColor.setFill
          # puts "Annotation color for #{annotation.coordinate.to_hash}"
          # mp annotation.color.CIColor.stringRepresentation
          annotation.color.setStroke
          path.lineWidth = 4.0
          path.stroke
        end
      )

      annotation_view.canShowCallout = false
    end
    annotation_view
  end
  # rubocop:enable Metrics/AbcSize

  ### Called after annotations have been added ###
  # def mapView(map_view, didAddAnnotationViews: views)
  #   puts 'didAddAnnotationViews!!'.focus
  # end

  def mapView(_map_view, rendererForOverlay: overlay)
    # puts 'GAME_CONTROLLER: MAPVIEW.RENDERFOROVERLAY'.blue if DEBUGGING
    rend = MKPolygonRenderer.alloc.initWithOverlay(overlay)
    rend.lineWidth = 0.75
    rend.strokeColor = UIColor.colorWithHue(1.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
    # overlay.fillColor = UIColor.systemGreenColor
    rend.fillColor = UIColor.colorWithHue(1.0, saturation: 1.0, brightness: 1.0, alpha: 0.3)
    unless overlay.overlayColor.nil?
      # rend.fillColor = UIColor.colorWithCGColor(overlay.overlayColor.CGColor)
      # puts "overlayColor: #{overlay.overlayColor}".focus
      rend.fillColor = UIColor.colorWithCIColor(overlay.overlayColor).colorWithAlphaComponent(0.5)
    end
    rend.lineJoin = KCGLineJoinMiter
    rend
  end

  # REFACTOR with method below?
  def render_overlays
    puts 'GAME_CONTROLLER RENDEROVERLAYS'.blue if DEBUGGING

    if map_view.overlays
      overlays_to_remove = map_view.overlays.mutableCopy
      map_view.removeOverlays(overlays_to_remove)
    end
    if map_view.annotations
      annotations_to_remove = map_view.annotations.mutableCopy
      map_view.removeAnnotations(annotations_to_remove)
    end

    # This is a hack to get past having one pylon
    # return if @voronoi_map.pylons.length < 2
    # return if Machine.instance.takaro.pouwhenua_array.length < 2
    return if Machine.instance.takaro_fbo.pouwhenua_array.length < 2

    # puts "Adding annotations: #{@voronoi_map.annotations}".focus
    map_view.addAnnotations(@voronoi_map.annotations)

    puts 'GAME_CONTROLLER getting the cells'
#     vcells = @voronoi_map.voronoiCells
# 
#     vcells.each do |cell|
    @voronoi_map.voronoiCells.each do |cell|
      # puts "cell: #{cell}".focus
      map_view.addOverlay(cell.overlay)
    end
  end

  def touch_down
    puts 'touch down'
    @button_fsm.event(:button_down)
  end

  def touch_up
    puts 'touch up'
    @button_fsm.event(:button_up)
  end

  def touch_out
    puts 'touch out'
    @button_fsm.event(:button_cancel)
  end

  def button_color(color)
    button_pylon.tintColor = color
  end

  def add_overlays_and_annotations
    # puts 'add_overlays_and_annotations'
    add_overlays
    add_annotations
  end

  def add_overlays
    puts 'GAME_CONTROLLER: ADD_OVERLAYS'.blue if DEBUGGING
    @voronoi_map.voronoi_cells.each do |cell|
      map_view.addOverlay(cell.overlay)
    end
  end

  def add_annotations
    puts 'GAME_CONTROLLER: ADD_ANNOTATIIONS'.blue if DEBUGGING
    map_view.addAnnotations(@voronoi_map.annotations)
  end

  def player_for_audio(filename)
    sound_path = NSBundle.mainBundle.pathForResource(filename, ofType: 'mp3')
    sound_url = NSURL.fileURLWithPath(sound_path)
    error_ptr = Pointer.new(:object)
    # player_audio = AVAudioPlayer.alloc.initWithContentsOfURL(sound_url, error: error_ptr)
    # puts "AVAudioPlayer error: #{error_ptr[0]}" if error_ptr[0]
    AVAudioPlayer.alloc.initWithContentsOfURL(sound_url, error: error_ptr)
  end

  def handle_new_pouwhenua
    puts 'GAME_CONTROLLER: HANDLE_NEW_POUWHENUA'.blue if DEBUGGING

    puts "SENDING EVENT".focus
    @button_fsm.event(:button_placed)

    puts "HANDLING POUWHENUA".focus
    Machine.instance.takaro_fbo.create_new_pouwhenua_from_hash
  end

  def observe_new_pouwhenua
    puts 'game_controller observe_new_pouwhenua'.blue if DEBUGGING
    render_overlays
  end
end

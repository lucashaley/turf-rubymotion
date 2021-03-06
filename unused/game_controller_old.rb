class GameController < MachineViewController
  include VoronoiUtilities

  outlet :map_view, MKMapView
  outlet :button_pylon, UIButton

  attr_accessor :voronoi_map,
                :game,
                :player_location,
                :boundary_audio

  DEBUGGING = false

  def setup_mapview
    map_view.showsUserLocation = true
    map_view.showsPitchControl = false
  end

  def setup_audio
    # AUDIO SETUP
    @boundary_audio = player_for_audio('boundary')
  end

  def viewWillAppear(animated)
    puts 'GAME_CONTROLLER: VIEWWILLAPPEAR'.light_blue

    Machine.instance.is_playing = true

    # https://stackoverflow.com/questions/6020612/mkmapkit-not-showing-userlocation
    setup_mapview
    setup_audio
    
    add_overlays_and_annotations
    
    @pouwhenua_new_observer = Notification.center.observe 'PouwhenuaNew' do |notification|
      observe_new_pouwhenua
    end
    @pylon_new_observer = Notification.center.observe 'PylonNew' do |notification|
      observe_new_pylon(notification.object)
    end
    @pylon_observer = Notification.center.observe 'PylonChange' do |notification|
      observe_change_pylon
    end
    @pylon_death_observer = Notification.center.observe 'PylonDeath' do |notification|
      observe_death_pylon(notification.object)
    end
    
    @player_new_observer = Notification.center.observe 'PlayerNew' do |notification|
      puts 'NEW PLAYER'
    end
    # BOUNDARY EXIT
    @exit_observer = Notification.center.observe 'BoundaryExit' do |notification|
      puts 'BOUNDARY EXIT'.yellow

      # trying sounds
      puts 'Playing Sound'
      # TODO make this work again
      # boundary_audio.play

      # set the player state

      # disable the pylon button
      button_pylon.enabled = false

      # mark the player's last location
    end
    # BOUNDARY ENTER
    @enter_observer = Notification.center.observe 'BoundaryEnter' do |notification|
      puts 'BOUNDARY ENTER'.yellow

      # set the player state

      # enable the pylon button
      button_pylon.enabled = true

      # remove the players last location
    end
    # PLAYER DISAPPEAR
    @disappear_observer = Notification.center.observe 'PlayerDisappear' do |notification|
      puts 'PLAYER DISAPPEAR'.yellow

      # set the player state

      # disable the pylon button
      # button_pylon.enabled = false

      # mark the player's last location
    end
    # PLAYER APPEAR
    @appear_observer = Notification.center.observe 'PlayerAppear' do |notification|
      puts 'PLAYER APPEAR'.yellow

      # set the player state

      # enable the pylon button
      button_pylon.enabled = true

      # remove the players last location
    end
  end

  def viewDidLoad
    super
    puts 'GAMECONTROLLER: VIEWDIDLOAD'.light_blue

    # # with the new new/join system, we have the gamecode
    # puts "Machine gamecode: #{Machine.instance.gamecode}".red
    # # and need to set up the takaro
    # # move this to the character selection?
    # Machine.instance.db.referenceWithPath("games")
    # .queryOrderedByChild("gamecode")
    # .queryEqualToValue(Machine.instance.gamecode)
    # .queryLimitedToLast(1)
    # .getDataWithCompletionBlock(
    #   lambda do | error, snapshot |
    #     # create the takaro
    #     puts "snapshot: #{snapshot.value}".focus
    #     Machine.instance.takaro = Takaro.new(snapshot.children.nextObject.key)
    #     Machine.instance.takaro.local_kaitakaro.character = local_character
    #   end
    # )

    # Machine.instance.takaro.start_observing_pouwhenua

    # deploy_time = Machine.instance.takaro.local_kaitakaro_hash['player_class']['deploy_time']
    # puts "deploy_time: #{deploy_time}".pink

    map_view.setRegion(Machine.instance.takaro.taiapa_region, animated: false)
    map_view.setCameraBoundary(MKMapCameraBoundary.alloc.initWithCoordinateRegion(Machine.instance.takaro.taiapa_region), animated: true)

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
        after: deploy_time
      state.transition_to :up,
        on: :button_up
    end
    @button_fsm.when :primed do |state|
      state.on_entry { set_button_color(UIColor.systemGreenColor) }
      state.transition_to :up,
        on: :button_up,
        # action: proc { create_new_pylon } # CREATE NEW PYLON!
        # TODO switch to Takaro
        # action: proc { Machine.instance.game.create_new_pouwhenua }
        action: proc { Machine.instance.takaro.create_new_pouwhenua }
    end

    puts 'Starting button state machine'
    @button_fsm.start!

    add_overlays_and_annotations
  end

  PYLON_VIEW_IDENTIFIER = 'PylonViewIdentifier'

  ### Makes an annotation image for the map ###
  def mapView(map_view, viewForAnnotation: annotation)
    puts 'GAME_CONTROLLER: MAPVIEW.VIEWFORANNOTATION'.blue if DEBUGGING
    if annotation == map_view.userLocation
      puts 'PLAYER'
      return nil
    end
    # puts "viewForAnnotation: #{annotation.class}"
    # check to see if it exists and has been queued
    if annotation_view = map_view.dequeueReusableAnnotationViewWithIdentifier(PYLON_VIEW_IDENTIFIER)
     else
      annotation_view = MKAnnotationView.alloc.initWithAnnotation(annotation, reuseIdentifier: PYLON_VIEW_IDENTIFIER)

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
  def mapView(map_view, didAddAnnotationViews: views)
    puts 'didAddAnnotationViews!!'.focus
  end

  def mapView(map_view, rendererForOverlay: overlay)
    puts 'GAME_CONTROLLER: MAPVIEW.RENDERFOROVERLAY'.blue if DEBUGGING
    rend = MKPolygonRenderer.alloc.initWithOverlay(overlay)
    rend.lineWidth = 0.75
    rend.strokeColor = UIColor.colorWithHue(0.2, saturation: 0.9, brightness: 0.9, alpha: 1.0)
    # overlay.fillColor = UIColor.systemGreenColor
    rend.fillColor = UIColor.colorWithHue(0.2, saturation: 0.9, brightness: 0.9, alpha: 0.3)
    unless overlay.overlayColor.nil?
      # rend.fillColor = UIColor.colorWithCGColor(overlay.overlayColor.CGColor)
      puts "overlayColor: #{overlay.overlayColor}".focus
      rend.fillColor = UIColor.colorWithCIColor(overlay.overlayColor).colorWithAlphaComponent(0.2)
    end
    rend.lineJoin = KCGLineJoinMiter
    rend
  end

  # REFACTOR with method below?
  def renderOverlays
    puts 'GAME_CONTROLLER RENDEROVERLAYS'.blue if DEBUGGING

    if map_view.overlays
      overlaysToRemove = map_view.overlays.mutableCopy
      map_view.removeOverlays(overlaysToRemove)
    end
    if map_view.annotations
      annotations_to_remove = map_view.annotations.mutableCopy
      map_view.removeAnnotations(annotations_to_remove)
    end

    # This is a hack to get past having one pylon
    # return if @voronoi_map.pylons.length < 2
    return if Machine.instance.takaro.pouwhenua_array.length < 2

    puts "Adding annotations: #{@voronoi_map.annotations}".focus
    map_view.addAnnotations(@voronoi_map.annotations)

    puts 'GAME_CONTROLLER getting the cells'
    vcells = @voronoi_map.voronoiCells

    vcells.each do |cell|
      puts "cell: #{cell}".focus
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
    @button_fsm.event(:button_up)
  end

  def set_button_color(color)
    button_pylon.tintColor = color
  end

  def add_overlays_and_annotations
    puts 'add_overlays_and_annotations'
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
  #
  # def create_play_region(args = {})
  #   puts "GAME_CONTROLLER: CREATE_PLAY_REGION".blue if DEBUGGING
  #   location = args[:location] || CLLocationCoordinate2DMake(37.33189332651307, -122.03128724123847)
  #   span = args[:span] || MKCoordinateSpanMake(0.01, 0.01)
  #   region = MKCoordinateRegionMake(location, span)
  # end

  def player_for_audio(filename)
    sound_path = NSBundle.mainBundle.pathForResource(filename, ofType: "mp3")
    sound_url = NSURL.fileURLWithPath(sound_path)
    error_ptr = Pointer.new(:object)
    player_audio = AVAudioPlayer.alloc.initWithContentsOfURL(sound_url, error: error_ptr)
    puts "AVAudioPlayer error: #{error_ptr[0]}" if error_ptr[0]
  end

  # def create_new_pylon
  #   puts "GAME_CONTROLLER: CREATE_NEW_PYLON".blue if DEBUGGING
  #
  #   # this gets it into the DB, but not on screen
  #   # @fb_game.create_new_pylon(@player_location)
  #   # Machine.instance.create_new_pylon(@player_location)
  #   # Machine.instance.create_new_pylon(Machine.instance.player.location)
  #   Machine.instance.create_new_pylon
  # end

#   def create_new_pouwhenua
# 
#   end
# 
#   def handle_new_pylon(data)
#     puts "GAME_CONTROLLER: HANDLE_NEW_PYLON".blue if DEBUGGING
# 
#     p = Pylon.initWithHash(data)
#     p.set_uuid data[:uuID]
# 
#     @voronoi_map.add_pylon(p)
# 
#     renderOverlays
#   end

  def handle_new_pouwhenua(data)
    puts 'GAME_CONTROLLER: HANDLE_NEW_POUWHENUA'.blue if DEBUGGING
    # data.each do |k, v|
    #   puts "#{k}: #{v}"
    # end
    # puts data["title"]

    p = Pouwhenua.new(data['location'], { color: data['color'], title: data['title'], birthdate: data['birthdate'] })
    # puts data[:uuID]
    # puts data["uuID"]
    p.set_uuid data[:uuID]

    # @voronoi_map.add_pylon(p)
    @voronoi_map.add_pouwhenua(p)

    renderOverlays
  end

  def observe_new_pouwhenua
    puts "-game_controller observe_new_pouwhenua".blue if DEBUGGING
    renderOverlays
  end

  def observe_new_pylon(notification_object)
    puts "-game_controller observe_new_pylon".blue if DEBUGGING
    handle_new_pylon({uuID: notification_object.key}.merge(notification_object.value))

    add_overlays_and_annotations
    renderOverlays
  end

  def observe_change_pylon
    puts "-game_controller observe_change_pylon".blue if DEBUGGING
    renderOverlays
    add_overlays_and_annotations
  end

  def observe_death_pylon(notification_object)
    puts '-game_controller observe_death_pylon'.blue if DEBUGGING
    removed_pylon = @voronoi_map.pylons.delete(notification.object[:object].uuID)
    map_view.removeAnnotation(notification.object[:object].annotation)
    renderOverlays
    add_overlays_and_annotations
  end
end

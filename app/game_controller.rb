class GameController < MachineViewController
  include VoronoiUtilities

  outlet :map_view, MKMapView
  outlet :button_pylon, UIButton
  outlet :timer_label, UILabel
  outlet :pouwhenua_label, UILabel
  outlet :left_score_label, UILabel
  outlet :right_score_label, UILabel

  attr_accessor :voronoi_map,
                :game,
                :player_location,
                :timer,
                :timer_count,
                :scores,
                :scores_hash

  DEBUGGING = true
  PYLON_VIEW_IDENTIFIER = 'PylonViewIdentifier'.freeze
  KAITAKARO_VIEW_IDENTIFIER = 'KaitakaroViewIdentifier'.freeze

  def setup_mapview
    map_view.showsUserLocation = false
    map_view.showsPitchControl = false
  end

  def setup_audio
    @boundary_audio = player_for_audio('boundary')

    @boundary_audio.numberOfLoops = -1  # looping
    @boundary_audio.prepareToPlay       # make sure it's ready

    @button_cancel_audio = player_for_audio('button_cancel')
    @button_cancel_audio.prepareToPlay
  end

  def update_pouwhenua_label
    pouwhenua_label.text = '•' * Machine.instance.takaro_fbo.local_kaitakaro.pouwhenua_current
  end

  # https://www.raywenderlich.com/2156-rubymotion-tutorial-for-beginners-part-2
  def setup_timers
    puts 'SETUP_TIMERS'.yellow
    @timer_count = Machine.instance.takaro_fbo.duration * 60
    # mp @timer_count
    timer_label.text = format_seconds(@timer_count)
    @timer = NSTimer.timerWithTimeInterval(
      1,
      target: self,
      selector: 'timer_decrement',
      userInfo: nil,
      repeats: true
    )
    NSRunLoop.currentRunLoop.addTimer(@timer, forMode: NSDefaultRunLoopMode)

    @score_timer = NSTimer.timerWithTimeInterval(
      0.1,
      target: self,
      selector: 'calculate_score',
      userInfo: nil,
      repeats: true
    )
    NSRunLoop.currentRunLoop.addTimer(@score_timer, forMode: NSDefaultRunLoopMode)

    @redraw_timer = NSTimer.timerWithTimeInterval(
      0.1,
      target: self,
      selector: 'try_render_overlays',
      userInfo: nil,
      repeats: true
    )
    NSRunLoop.currentRunLoop.addTimer(@redraw_timer, forMode: NSDefaultRunLoopMode)
  end

  def timer_decrement
    # puts 'TIMER_DECREMENT'.yellow
    @timer_count -= 1
    timer_label.text = format_seconds(@timer_count)
  end

  def format_seconds(in_seconds)
    minutes = (in_seconds / 60).floor
    seconds = (in_seconds % 60).round

    "#{minutes}:#{seconds.to_s.rjust(2, '0')}"
  end

  # rubocop:disable Metrics/AbcSize
  def calculate_score
    return if @voronoi_map.nil?

    areas_hash = {}

    @voronoi_map.voronoi_cells.each do |vc|
      # mp vc.pylon['kapa_key']
      verts = vc.vertices

      area = 0.0
      verts.each_with_index do |point, index|
        if index + 1 < verts.length
          point2 = verts[index + 1]
        end
        if point2
          # shoelace algorithm
          # area = area + ((point.x * point2.y) - (point2.x * point.y))
          area += ((point.x * point2.y) - (point2.x * point.y))
        else
          # use the first point with the last point when all the other points have been done
          # area = area + ((point.x * verts[0].y) - (verts[0].x * point.y))
          area += ((point.x * verts[0].y) - (verts[0].x * point.y))
        end
      end
      # divide by 2 and get the absolute. I  have converted the result to metres but that is optional. Leave it in square inches if you prefer.
      area = (area / (2.0 * 100_000)).abs.round(1)

      if areas_hash.key?(vc.pylon['kapa_key'])
        areas_hash[vc.pylon['kapa_key']] += area
      else
        areas_hash[vc.pylon['kapa_key']] = area
      end
    end

    total_areas_hash = areas_hash.values.inject(0, :+)

    delta_hash = {}
    areas_hash.each do |key, v|
      s = ((v / total_areas_hash) * 100).round - 50
      s = s < 0 ? 0 : s
      delta_hash[key] = (s / 10).round
    end

    # This doesn't seem to work for this version?
    # delta_hash = areas_hash.transform_values { |v| ((v / total_areas_hash) * 100).round - 50 }

    delta_hash.each do |key, value|
      if @scores_hash.key?(key)
        @scores_hash[key] += value
      else
        @scores_hash[key] = value
      end
    end

    left_score_label.text = @scores_hash.values[0].to_s
    right_score_label.text = @scores_hash.values[1].to_s
  end
  # rubocop:disable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  def init_observers
    @map_refresh = Notification.center.observe 'MapRefresh' do |_notification|
      puts 'map_refresh'.focus
      observe_new_pouwhenua
    end
    @pouwhenua_new_observer = Notification.center.observe 'PouwhenuaNew' do |_notification|
      puts 'pouwhenua_new_observer'.focus
      observe_new_pouwhenua
    end
    @pouwhenuafbo_new_observer = Notification.center.observe 'PouwhenuaFbo_New' do |_notification|
      puts 'pouwhenuafbo_new_observer'.focus
      observe_new_pouwhenua
    end
    @pouwhenua_child_observer = Notification.center.observe 'PouwhenuaFbo_ChildAdded' do |_notification|
      puts 'pouwhenua_child_observer'.focus
      observe_new_pouwhenua
    end

    @player_new_observer = Notification.center.observe 'PlayerNew' do |_notification|
      puts 'NEW PLAYER'
    end
    # BOUNDARY EXIT
    @exit_observer = Notification.center.observe 'BoundaryExit' do |_notification|
      @boundary_audio.play

      # disable the pylon button
      button_pylon.enabled = false

      # mark the player's last location
    end
    # BOUNDARY ENTER
    @enter_observer = Notification.center.observe 'BoundaryEnter' do |_notification|
      @boundary_audio.stop
      # enable the pylon button
      button_pylon.enabled = true

      # remove the players last location
    end
    # PLAYER DISAPPEAR
    @disappear_observer = Notification.center.observe 'PlayerDisappear' do |_notification|
      # puts 'PLAYER DISAPPEAR'.yellow

      # set the player state

      # disable the pylon button
      # button_pylon.enabled = false

      # mark the player's last location
    end
    # PLAYER APPEAR
    @appear_observer = Notification.center.observe 'PlayerAppear' do |_notification|
      # puts 'PLAYER APPEAR'.yellow

      # set the player state

      # enable the pylon button
      button_pylon.enabled = true

      # remove the players last location
    end

    @placement_observer = Notification.center.observe 'CrossedPlacementLimit' do |_notification|
      @button_cancel_audio.play
      @button_fsm.event(:button_cancel)
    end

    @pouwhenua_label_observer = Notification.center.observe 'UpdatePouwhenuaLabel' do |_notification|
      puts 'GameController: pouwhenua_label_observer'.focus
      update_pouwhenua_label
    end
  end
  # rubocop:enable Metrics/AbcSize

  def viewWillAppear(_animated)
    puts 'GAME_CONTROLLER: VIEWWILLAPPEAR'.light_blue

    button_pylon.setImage(icon_image(:awesome, :plus_circle, size: 80, color: UIColor.redColor), forState: UIControlStateNormal)

    # https://stackoverflow.com/questions/6020612/mkmapkit-not-showing-userlocation
    setup_mapview

    # add_overlays_and_annotations

    render_overlays
  end

  # rubocop:disable Metrics/AbcSize
  def viewDidLoad
    super
    puts 'GAMECONTROLLER: VIEWDIDLOAD'.light_blue

    Machine.instance.is_playing = true
    @scores = [0, 0]
    @scores_hash = {}

    map_view.setRegion(Machine.instance.takaro_fbo.taiapa_region, animated: false)
    map_view.setCameraBoundary(
      MKMapCameraBoundary.alloc.initWithCoordinateRegion(Machine.instance.takaro_fbo.taiapa_region),
      animated: true
    )

    init_observers
    setup_audio
    setup_timers
    update_pouwhenua_label

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

    # add_overlays_and_annotations
    render_overlays
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
    return nil if annotation == map_view.userLocation

    return pouwhenua_annotation(annotation) if annotation.class.to_s.end_with?('PouAnnotation')
    return kaitarako_annotation(annotation) if annotation.class.to_s.end_with?('KaitakaroAnnotation')
  end
  # rubocop:enable Metrics/AbcSize

  def pouwhenua_annotation(annotation)
    annotation_view = map_view.dequeueReusableAnnotationViewWithIdentifier(PYLON_VIEW_IDENTIFIER)
    if annotation_view.nil?
      annotation_view = MKAnnotationView.alloc.initWithAnnotation(annotation, reuseIdentifier: PYLON_VIEW_IDENTIFIER)
    end

    # ui_renderer = UIGraphicsImageRenderer.alloc.initWithSize(CGSizeMake(16, 16))
    ui_renderer = UIGraphicsImageRenderer.alloc.initWithSize(CGSizeMake(24, 24))

    annotation_view.image = ui_renderer.imageWithActions(
      lambda do |_context|
        # path = UIBezierPath.bezierPathWithRoundedRect(CGRectMake(1, 1, 14, 14), cornerRadius: 4)
        path = UIBezierPath.bezierPathWithRoundedRect(CGRectMake(1, 1, 22, 22), cornerRadius: 4)

        UIColor.whiteColor.setFill
        path.fill
        annotation.color.setStroke
        path.lineWidth = 2.0
        path.stroke
      end
    )

    annotation_view.canShowCallout = false
    annotation_view.layer.zPosition = 1

    annotation_view
  end

  def kaitarako_annotation(annotation)
    annotation_view = map_view.dequeueReusableAnnotationViewWithIdentifier(KAITAKARO_VIEW_IDENTIFIER)
    if annotation_view.nil?
      annotation_view = MKAnnotationView.alloc.initWithAnnotation(annotation, reuseIdentifier: KAITAKARO_VIEW_IDENTIFIER)
    end

    ui_renderer = UIGraphicsImageRenderer.alloc.initWithSize(CGSizeMake(16, 16))

    annotation_view.image = ui_renderer.imageWithActions(
      lambda do |_context|
        path = UIBezierPath.bezierPathWithOvalInRect(CGRectMake(1, 1, 14, 14))

        UIColor.blackColor.setFill
        path.fill
        annotation.color.setStroke
        path.lineWidth = 2.0
        path.stroke
      end
    )

    annotation_view.canShowCallout = true
    annotation_view.layer.zPosition = 2

    annotation_view
  end

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

  def try_render_overlays
    puts 'try_render_overlays'
    return if @rendering

    puts 'rendering'
    render_overlays
  end

  def render_overlays
    # puts 'game_controller render_overlays'.blue

    @rendering = true

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

    # add the pouwhenua
    # map_view.addAnnotations(@voronoi_map.annotations)
    map_view.addAnnotations(Machine.instance.takaro_fbo.pouwhenua_annotations)

    # add the players
    map_view.addAnnotations(Machine.instance.takaro_fbo.kaitakaro_annotations)

    @voronoi_map.voronoiCells.each do |cell|
      map_view.addOverlay(cell.overlay)
    end

    @rendering = false
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

#   def add_overlays_and_annotations
#     # puts 'add_overlays_and_annotations'
#     add_overlays
#     add_annotations
#   end
# 
#   def add_overlays
#     puts 'GAME_CONTROLLER: ADD_OVERLAYS'.blue if DEBUGGING
#     @voronoi_map.voronoi_cells.each do |cell|
#       map_view.addOverlay(cell.overlay)
#     end
#   end
# 
#   def add_annotations
#     puts 'GAME_CONTROLLER: ADD_ANNOTATIIONS'.blue
#     # map_view.addAnnotations(@voronoi_map.annotations)
#     map_view.addAnnotations(Machine.instance.takaro_fbo.pouwhenua_annotations)
#     map_view.addAnnotations(Machine.instance.takaro_fbo.kaitakaro_annotations)
#   end

  def player_for_audio(filename)
    sound_path = NSBundle.mainBundle.pathForResource(filename, ofType: 'mp3')
    sound_url = NSURL.fileURLWithPath(sound_path)
    error_ptr = Pointer.new(:object)
    # player_audio = AVAudioPlayer.alloc.initWithContentsOfURL(sound_url, error: error_ptr)
    # puts "AVAudioPlayer error: #{error_ptr[0]}" if error_ptr[0]
    AVAudioPlayer.alloc.initWithContentsOfURL(sound_url, error: error_ptr)
  end

  # https://gist.github.com/amirrajan/706dafe5ce196f966ad04bf9bb06e764
  def play_forward_sound_thread
    NSThread.detachNewThreadSelector :play_forward_sound, toTarget: self, withObject: nil
  end
  
  def play_forward_sound context = nil
    #play sound code here
  end

  def handle_new_pouwhenua
    puts 'GAME_CONTROLLER: HANDLE_NEW_POUWHENUA'.blue if DEBUGGING

    # @button_fsm.event(:button_placed)
    Machine.instance.takaro_fbo.create_new_pouwhenua_from_hash
  end

  def observe_new_pouwhenua
    puts 'game_controller observe_new_pouwhenua'.blue if DEBUGGING
    render_overlays
  end
end

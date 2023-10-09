class GameController < MachineViewController
  include VoronoiUtilities

  outlet :map_view, MKMapView
  outlet :button_pylon, UIButton
  outlet :timer_label, UILabel
  # TODO: change this here and in xcode
  outlet :pouwhenua_label, UILabel
  outlet :marker_label, UILabel
  outlet :left_score_label, UILabel
  outlet :right_score_label, UILabel
  outlet :skview, SKView

  attr_accessor :voronoi_map,
                :game,
                :player_location,
                :timer,
                :timer_count,
                :scores,
                :scores_hash

  DEBUGGING = true
  # TODO: change this
  PYLON_VIEW_IDENTIFIER = 'PylonViewIdentifier'.freeze
  KAITAKARO_VIEW_IDENTIFIER = 'KaitakaroViewIdentifier'.freeze

  def setup_mapview
    map_view.showsUserLocation = true
    map_view.showsPitchControl = false
  end

  def setup_audio
    @boundary_audio = player_for_audio('boundary')

    @boundary_audio.numberOfLoops = -1  # looping
    @boundary_audio.prepareToPlay       # make sure it's ready

    @button_cancel_audio = player_for_audio('button_cancel')
    @button_cancel_audio.prepareToPlay
  end

  # def update_pouwhenua_label
  #   # pouwhenua_label.text = '•' * Machine.instance.takaro_fbo.local_kaitakaro.pouwhenua_current
  # end

  def update_marker_label
    mp __method__
    # pouwhenua_label.text = '•' * Machine.instance.takaro_fbo.local_player.marker_current
    pouwhenua_label.text = '•' * current_game.local_player.marker_current

    # change the enable of the button
    # if Machine.instance.takaro_fbo.local_player.marker_current <= 0
    if current_game.local_player.marker_current <= 0
      button_pylon.enabled = false
    else
      # button_pylon.enabled = false & Machine.instance.takaro_fbo.local_player.in_boundary
      button_pylon.enabled = false & current_game.local_player.in_boundary
    end
  end

  # https://www.raywenderlich.com/2156-rubymotion-tutorial-for-beginners-part-2
  def setup_timers
    mp __method__

    # @timer_count = Machine.instance.takaro_fbo.duration * 60
    @timer_count = current_game.duration * 60
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
      # 0.1,
      6,
      target: self,
      selector: 'calculate_score',
      userInfo: nil,
      repeats: true
    )
    NSRunLoop.currentRunLoop.addTimer(@score_timer, forMode: NSDefaultRunLoopMode)

    @redraw_timer = NSTimer.timerWithTimeInterval(
      # 0.1,
      3,
      target: self,
      selector: 'try_render_overlays',
      # selector: 'render_overlays',
      userInfo: nil,
      repeats: true
    )
    NSRunLoop.currentRunLoop.addTimer(@redraw_timer, forMode: NSDefaultRunLoopMode)
  end

  def timer_decrement
    # puts 'TIMER_DECREMENT'.yellow
    @timer_count -= 1

    handle_game_over if @timer_count <= 0

    timer_label.text = format_seconds(@timer_count)
  end

  def handle_game_over
    mp 'handle_game_over'
    performSegueWithIdentifier('GameOver', sender: self)
  end

  # rubocop:disable Metrics/AbcSize
  def calculate_score
    mp __method__

    return if @voronoi_map.nil?
    return if @voronoi_map.voronoi_cells.nil?

    areas_hash = {}

    begin
      @voronoi_map.voronoi_cells.each do |vc|
        team_key = vc.pylon['team_key']
        mp team_key
        
        # mp 'voronoi cell'
        mp 'Current cell:'
        mp vc

        mp 'verts'
        verts = vc.vertices
        mp verts

        area = 0.0
        verts.each_with_index do |point, index|
          mp 'point:'
          mp point

          if index + 1 < verts.length
            point2 = verts[index + 1]
          end
          if point2
            # shoelace algorithm
            area += ((point.x * point2.y) - (point2.x * point.y))
          else
            # use the first point with the last point when all the other points have been done
            area += ((point.x * verts[0].y) - (verts[0].x * point.y))
          end
        end
        mp area
        # divide by 2 and get the absolute.
        # TODO: Why divide by 2?
        # area = (area / (2.0 * 100_000)).abs.round(1)
        area = (area / 2).abs.round(1)
        mp 'area'
        mp area

        if areas_hash.key?(team_key)
          areas_hash[team_key] += area
        else
          areas_hash[team_key] = area
        end
      end
    rescue Exception => exception
      Bugsnag.leaveBreadcrumbWithMessage('calculate_score')
      Bugsnag.notify(exception)
    end

    mp 'areas_hash'
    mp areas_hash

    total_areas_hash = areas_hash.values.inject(0, :+) # whut
    mp 'total_areas_hash'
    mp total_areas_hash

    delta_hash = {}

    begin
      # TODO: something is going on here, still NaN
      areas_hash.each do |key, v|
        # mp key
        s = ((v / total_areas_hash) * 100).round - 50
        mp s
        s = s < 0 ? 0 : s
        mp s
        delta_hash[key] = s == 0 ? 0 : (s / 10).round # is this necessary?
      end
    rescue Exception => exception
      mp exception.reason
      Bugsnag.notify(exception)
    end

    # mp 'delta_hash'
    # mp delta_hash

    # This doesn't seem to work for this version?
    # delta_hash = areas_hash.transform_values { |v| ((v / total_areas_hash) * 100).round - 50 }

    delta_hash.each do |key, value|
      if @scores_hash.key?(key)
        @scores_hash[key] += value
      else
        @scores_hash[key] = value
      end
    end

    # mp 'scores_hash'
    # mp @scores_hash

    left_score_label.text = @scores_hash.values[0].to_s
    right_score_label.text = @scores_hash.values[1].to_s
  end
  # rubocop:disable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  def init_observers
    # @map_refresh = Notification.center.observe 'MapRefresh' do |_notification|
    #   puts 'map_refresh'.focus
    #   observe_new_pouwhenua
    # end
    # @pouwhenua_new_observer = Notification.center.observe 'PouwhenuaNew' do |_notification|
    #   puts 'pouwhenua_new_observer'.focus
    #   observe_new_pouwhenua
    # end
    # @pouwhenuafbo_new_observer = Notification.center.observe 'PouwhenuaFbo_New' do |_notification|
    #   puts 'pouwhenuafbo_new_observer'.focus
    #   observe_new_pouwhenua
    # end
    # @pouwhenua_child_observer = Notification.center.observe 'PouwhenuaFbo_ChildAdded' do |_notification|
    #   puts 'pouwhenua_child_observer'.focus
    #   observe_new_pouwhenua
    # end

    @player_new_observer = Notification.center.observe 'PlayerNew' do |_notification|
      mp 'NEW PLAYER'
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
      Utilities::breadcrumb('BoundaryEnter')
      @boundary_audio.stop
      # enable the pylon button
      button_pylon.enabled = true

      # remove the players last location
    end
    # PLAYER DISAPPEAR
    @disappear_observer = Notification.center.observe 'PlayerDisappear' do |_notification|
        Utilities::breadcrumb('PlayerDisappear')

      # puts 'PLAYER DISAPPEAR'.yellow

      # set the player state

      # disable the pylon button
      # button_pylon.enabled = false

      # mark the player's last location
    end
    # PLAYER APPEAR
    @appear_observer = Notification.center.observe 'PlayerAppear' do |_notification|
      Utilities::breadcrumb('PlayerAppear')
      # puts 'PLAYER APPEAR'.yellow

      # set the player state

      # enable the pylon button
      button_pylon.enabled = true

      # remove the players last location
    end

    @placement_observer = Notification.center.observe 'CrossedPlacementLimit' do |_notification|
      mp 'Player has moved too far while placing'
      @button_cancel_audio.play
      @button_fsm.event(:button_cancel)
    end

    # @pouwhenua_label_observer = Notification.center.observe 'UpdatePouwhenuaLabel' do |_notification|
    #   puts 'GameController: pouwhenua_label_observer'.focus
    #   update_pouwhenua_label
    # end

    @marker_label_observer = Notification.center.observe 'UpdateMarkerLabel' do |_notification|
      mp 'GameController: UpdateMarkerLabel'.focus
      update_marker_label
    end

    @markers_change = Notification.center.observe 'markers_changed' do |_notification|
      mp 'markers_changed received'
      @voronoi_map.recalculate_cells
      render_overlays
    end

    @player_move = Notification.center.observe 'player_changed' do |_notification|
      mp 'player_changed received'
      render_overlays
    end

    @accuracy_change = Notification.center.observe 'accuracy_change' do |notification|
      begin
        mp 'accuracy_change received'
        mp "change to: #{notification.object['accurate']}"
        button_pylon.enabled = notification.object['accurate']
      rescue
        mp 'Something happened in the accuracy change'
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  def viewWillAppear(_animated)
    mp 'GAME_CONTROLLER: VIEWWILLAPPEAR'.light_blue

    # we now use a background image?
    # button_pylon.setImage(icon_image(:awesome, :plus_circle, size: 100, color: UIColor.redColor), forState: UIControlStateNormal)

    # https://stackoverflow.com/questions/6020612/mkmapkit-not-showing-userlocation
    setup_mapview

    # add_overlays_and_annotations

    render_overlays
  end

  # rubocop:disable Metrics/AbcSize
  def viewDidLoad
    super
    mp 'GAMECONTROLLER: VIEWDIDLOAD'.light_blue

    mp 'SKScene'
    mp @skview

    # Machine.instance.is_playing = true
    current_game.local_player_state('playing')

    # should these be here?
    @scores = [0, 0]
    @scores_hash = {}

    begin
      # map_view.setRegion(Machine.instance.takaro_fbo.taiapa_region, animated: false)
      # map_view.setCameraBoundary(
      #   MKMapCameraBoundary.alloc.initWithCoordinateRegion(Machine.instance.takaro_fbo.taiapa_region),
      #   animated: true
      # )

      map_view.setRegion(current_game.playfield_region, animated: false)
      map_view.setCameraBoundary(
        MKMapCameraBoundary.alloc.initWithCoordinateRegion(current_game.playfield_region),
        animated: true
      )
    rescue Exception => exception
      Bugsnag.notify(exception)
    end

    init_observers
    setup_audio
    setup_timers
    # update_pouwhenua_label
    update_marker_label

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
                          # after: Machine.instance.takaro_fbo.local_kaitakaro.deploy_time
                          after: current_game.local_player.deploy_time
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
      # state.on_entry { handle_new_pouwhenua }
      state.on_entry { handle_new_marker }
      state.transition_to :up,
                          # this is a hack to get around thread timing
                          after: 0.2
    end

    # puts 'Starting button state machine'
    @button_fsm.start!

    Notification.center.post("game_state_playing_notification", nil)

    # add_overlays_and_annotations
    render_overlays
  end

  def button_down
    mp 'GameController button_down'.red

    # change the button color
    button_color(UIColor.systemRedColor)

    current_game.local_player.placing(true)
  end

  def button_up
    mp 'GameController button_up'.red

    # change the button color
    button_color(UIColor.labelColor)

    # Machine.instance.takaro_fbo.local_kaitakaro.placing(true)
    current_game.local_player.placing(true)
  end

  ### Makes an annotation image for the map ###
  def mapView(map_view, viewForAnnotation: annotation)
    return nil if annotation == map_view.userLocation

    return marker_annotation(annotation) if annotation.class.to_s.end_with?('MarkerAnnotation')
    return player_annotation(annotation) if annotation.class.to_s.end_with?('PlayerAnnotation')
  end
  # rubocop:enable Metrics/AbcSize

  def marker_annotation(annotation)
    annotation_view = map_view.dequeueReusableAnnotationViewWithIdentifier(PYLON_VIEW_IDENTIFIER)
    if annotation_view.nil?
      annotation_view = MKAnnotationView.alloc.initWithAnnotation(annotation, reuseIdentifier: PYLON_VIEW_IDENTIFIER)
    end

    # ui_renderer = UIGraphicsImageRenderer.alloc.initWithSize(CGSizeMake(16, 16))
    ui_renderer = UIGraphicsImageRenderer.alloc.initWithSize(CGSizeMake(26, 26))

    annotation_view.image = ui_renderer.imageWithActions(
      lambda do |_context|
        # path = UIBezierPath.bezierPathWithRoundedRect(CGRectMake(1, 1, 14, 14), cornerRadius: 4)
        path = UIBezierPath.bezierPathWithRoundedRect(CGRectMake(1, 1, 24, 24), cornerRadius: 4)

        # UIColor.whiteColor.setFill
        # path.fill
        annotation.color.setStroke
        path.lineWidth = 4.0
        path.stroke
      end
    )

    annotation_view.canShowCallout = false
    annotation_view.layer.zPosition = 1

    annotation_view
  end

  def player_annotation(annotation)
    annotation_view = map_view.dequeueReusableAnnotationViewWithIdentifier(KAITAKARO_VIEW_IDENTIFIER)
    if annotation_view.nil?
      annotation_view = MKAnnotationView.alloc.initWithAnnotation(
        annotation, reuseIdentifier: KAITAKARO_VIEW_IDENTIFIER
      )
    end

    ui_renderer = UIGraphicsImageRenderer.alloc.initWithSize(CGSizeMake(16, 16))

    annotation_view.image = ui_renderer.imageWithActions(
      lambda do |_context|
        path = UIBezierPath.bezierPathWithOvalInRect(CGRectMake(1, 1, 14, 14))

        annotation.color.setFill
        path.fill
        UIColor.blackColor.setStroke
        path.lineWidth = 2.0
        path.stroke
      end
    )

    annotation_view.canShowCallout = true
    annotation_view.layer.zPosition = 2

    annotation_view.titleVisibility = MKFeatureVisibilityVisible

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
    # puts 'try_render_overlays'
    return if @rendering

    # puts 'rendering'
    render_overlays
  end

  def render_overlays
    # mp __method__

    @rendering = true

    # TODO: this is terrible
    if map_view.overlays
      overlays_to_remove = map_view.overlays.mutableCopy
      map_view.removeOverlays(overlays_to_remove)
    end
    if map_view.annotations
      annotations_to_remove = map_view.annotations.mutableCopy
      map_view.removeAnnotations(annotations_to_remove)
    end

    # This is a hack to get past having one pylon
    # mp Machine.instance.takaro_fbo.markers_hash
    return if current_game.markers_hash.length < 2

    # add the pouwhenua
    map_view.addAnnotations(current_game.marker_annotations)

    # add the players
    map_view.addAnnotations(current_game.player_annotations)

    @voronoi_map.voronoiCells.each do |cell|
      map_view.addOverlay(cell.overlay)
    end

    # adding new overlays
    map_view.addOverlays(current_game.overlays) unless current_game.overlays.nil?

    @rendering = false
  end

  def touch_down
    mp 'touch down'
    @button_fsm.event(:button_down)
  end

  def touch_up
    mp 'touch up'
    @button_fsm.event(:button_up)
  end

  def touch_out
    mp 'touch out'
    @button_fsm.event(:button_cancel)
  end

  def button_color(color)
    @button_pylon.tintColor = color
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

  def handle_new_marker
    mp __method__

    Machine.instance.takaro_fbo.create_new_marker_from_hash
  end

  def observe_new_pouwhenua
    mp __method__
    # mp 'game_controller observe_new_pouwhenua'.blue if DEBUGGING
    render_overlays
  end

  def format_seconds(in_seconds)
    minutes = (in_seconds / 60).floor
    seconds = (in_seconds % 60).round

    "#{minutes}:#{seconds.to_s.rjust(2, '0')}"
  end
end

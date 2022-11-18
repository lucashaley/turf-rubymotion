class TakaroFbo < FirebaseObject
  attr_accessor :team_manager,
                :kaitakaro_array,
                :kaitakaro_hash,
                :teams_hash,
                :local_kapa_array,
                :local_kaitakaro,
                :local_player,
                :bot_centroid,
                :local_pouwhenua,
                :pouwhenua_is_dirty,
                :marker_hash,
                :game_state,
                :game_state_machine,
                :taiapa_region # TODO: this might be hash later?

  DEBUGGING = true

  TEAM_DISTANCE = 3
  MOVE_THRESHOLD = 2
  TEAM_COUNT = 2
  FIELD_SCALE = 3
  BOT_DISTANCE = 0.005
  BOT_TEAM_DISPLACEMENT = 5 * 10**-14

  def initialize(in_ref, in_data_hash)
    mp __method__

    @team_manager = TeamManager.new
    @kaitakaro_array = []
    @kaitakaro_hash = {}
    @teams_hash = {}
    @marker_hash = {}
    @local_kapa_array = []
    @local_pouwhenua = []
    @pouwhenua_is_dirty = true

    puts 'TakaroFbo initialize'.red
    super.tap do |t|
      unless in_data_hash.nil?
        t.init_states
        # t.init_kapa
        t.initialize_firebase_observers
        # t.init_pouwhenua
        # t.initialize_markers

        # set up game state state machine
        t.game_state_machine = StateMachine::Base.new start_state: :initializing, verbose: DEBUGGING

        ####################
        # SPLASH SCREEN
        t.game_state_machine.when :initializing do |state|
          state.on_entry { mp 'game_state start initializing' }
          state.on_exit { mp 'game_state end initializing' }
          state.transition_to :options,
                              on_notification: 'game_state_options_notification'
        end
        ####################
        # OPTIONS
        t.game_state_machine.when :options do |state|
          state.on_entry { mp 'game_state start options' }
          state.on_exit { mp 'game_state end options' }
          state.transition_to :character_selection,
                              on_notification: 'game_state_charcater_selection_notification'
        end
        ####################
        # CHARACTER SELECTION
        t.game_state_machine.when :character_selection do |state|
          state.on_entry { mp 'game_state start character_selection' }
          state.on_exit { mp 'game_state end character_selection' }
          state.transition_to :waiting_room,
                              on_notification: 'game_state_waiting_room_notification'
        end
        ####################
        # WAITING ROOM
        t.game_state_machine.when :waiting_room do |state|
          state.on_entry { mp 'game_state start waiting_room' }
          state.on_exit { mp 'game_state end waiting_room' }

          state.transition_to :countdown,
                              on_notification: 'game_state_countdown_notification'
        end
        ####################
        # STARTING
        t.game_state_machine.when :countdown do |state|
          state.on_entry { mp 'game_state start countdown' }
          state.on_exit { mp 'game_state end countdown' }

          state.transition_to :playing,
                              on_notification: 'game_state_playing_notification'
        end
        ####################
        # PLAYING
        t.game_state_machine.when :playing do |state|
          state.on_entry { mp 'game_state start playing' }
          state.on_exit { mp 'game_state end playing' }

          # state.transition_to :options,
          #                     on_notification: 'game_state_start_notification'
        end
        t.game_state_machine.start!
      end
    end
    Utilities::puts_close
  end

  def initialize_firebase_observers
    mp __method__
    # Teams
    @ref.child('teams').observeEventType(
      FIRDataEventTypeChildChanged, withBlock:
      lambda do |teams_snapshot|
        teams_snapshot.ref.parent.getDataWithCompletionBlock(
          lambda do |error, snapshot|
            @teams_hash = snapshot.childSnapshotForPath('teams').valueInExportFormat
            Notification.center.post("teams_changed", @teams_hash)
          end
        )
      end
    )
    @ref.child('teams').observeEventType(FIRDataEventTypeValue, withBlock:
      lambda do |teams_snapshot|
        mp 'TEAMS VALUE CALLBACK'
        mp teams_snapshot.value
        # @teams_hash = teams_snapshot.value.values
        # Notification.center.post("teams_changed", @teams_hash)
      end
    )
    # Markers
    @ref.child('markers').queryOrderedByChild('enabled').queryEqualToValue('true').observeEventType(FIRDataEventTypeValue, withBlock:
      lambda do |markers_snapshot|
        mp 'MARKERS ENABLED CALLBACK'
        mp markers_snapshot.value
        @marker_hash = markers_snapshot.value
        Notification.center.post("markers_changed", @marker_hash)
      end
    )

    # Game ready
    @ref.child('game_state').observeEventType(
      FIRDataEventTypeValue, withBlock:
      lambda do |game_state_snapshot|
        # if true
        mp 'game_state_snapshot'
        mp game_state_snapshot.value

        self.game_state = game_state_snapshot.value

        if game_state_snapshot.value == 'ready'
          mp 'ready to start!'
          Machine.instance.is_waiting = false
          Machine.instance.current_view.performSegueWithIdentifier('ToGameCountdown', sender: self)
        end
      end
    )
  end

  def init_states
    mp __method__
    self.waiting = false
    self.playing = false
    self.game_state = 'prepping'

    @ref.child('game_state').setValue('prepping')
  end

#   def initialize_markers
#     mp __method__
#
#     @ref.child('markers').observeEventType(
#       FIRDataEventTypeChildAdded, withBlock:
#       lambda do |pylon_snapshot|
#         puts "FBO:#{@class_name} MARKER ADDED".red if DEBUGGING
#         pull_with_block { Notification.center.post 'markers_new' }
#         @markers_are_dirty = true
#       end
#     )
#   end

#   def init_pouwhenua
#     mp __method__
#     puts "FBO:#{@class_name} INIT_POUWHENUA".green if DEBUGGING
#
#     @ref.child('pouwhenua').observeEventType(
#       FIRDataEventTypeChildAdded, withBlock:
#       lambda do |_data_snapshot|
#         puts "FBO:#{@class_name} POUWHENUA ADDED".red if DEBUGGING
#         pull_with_block { Notification.center.post 'PouwhenuaFbo_New' }
#         @pouwhenua_is_dirty = true
#       end
#     )
#   end

#   def init_local_kaitakaro(in_character)
#     puts "FBO:#{@class_name} init_local_kaitakaro".green if DEBUGGING
#     kaitakaro_ref = @ref.child('kaitakaro').childByAutoId
#     $logger.info Machine.instance.firebase_user
#     $logger.info Machine.instance.firebase_user.providerData[0].displayName
#     k = KaitakaroFbo.new(
#       kaitakaro_ref,
#       {
#         'character' => in_character,
#         'display_name' => Machine.instance.firebase_user.providerData[0].displayName
#       }
#     )
#     @local_kaitakaro = k
#
#     add_kaitakaro(k)
#   end

  def initialize_local_player(in_character)
    puts "FBO:#{@class_name} initialize_local_player".green if DEBUGGING
    player_ref = @ref.child('players').childByAutoId
    player = Player.new(
      player_ref,
      {
        'character' => in_character,
        'display_name' => Machine.instance.firebase_user.providerData[0].displayName,
        'marker_current' => in_character['pouwhenua_start']
      }
    )
    @local_player = player

    # not sure we need this
    add_player(player)
  end

#   # This is never called?
#   # TODO: figure this out
#   def create_kapa(coordinate)
#     puts 'Creating new kapa'
#     kapa_ref = @ref.child('kapa').childByAutoId
#     # puts "kapa_ref: #{kapa_ref.URL}".yellow
#     # TODO: This uses random colors, which is an issue
#     k = KapaFbo.new(kapa_ref, { 'color' => Utilities::random_color, 'coordinate' => coordinate })
#     team = Team.new(kapa_ref, { 'color' => Utilities::random_color, 'coordinate' => coordinate })
#     mp 'New team: ' & team
#
#     @local_kapa_array << k
#     k
#   end
#
#   def remove_kapa(_in_ref)
#     puts "FBO:#{@class_name} remove_kapa".green if DEBUGGING
#     # puts "in_ref: #{in_ref}".focus
#   end

  def create_bot_player
    puts "FBO:#{@class_name} create_bot_player".green if DEBUGGING

    # grab local player coordinate if not defined
    @bot_centroid ||= {
      'latitude' => @local_player.coordinate['latitude'] + rand(-BOT_DISTANCE..BOT_DISTANCE),
      'longitude' => @local_player.coordinate['longitude'] + rand(-BOT_DISTANCE..BOT_DISTANCE)
    }

    bot_data = {
      'display_name' => 'Jimmy Bot',
      'character' => {
        'deploy_time' => 4,
        'lifespan_ms' => 280_000,
        'pylon_start' => 3,
        'title' => 'Bot Character'
      }
    }

    bot_ref = @ref.child('players').childByAutoId
    bot = Player.new(bot_ref, bot_data, true)

    # coord = @local_kaitakaro.coordinate
    # coord = @local_player.coordinate
    # mp "coord: #{coord}"

    bot.coordinate = {
      'latitude' => @bot_centroid['latitude'] + rand(-BOT_TEAM_DISPLACEMENT..BOT_TEAM_DISPLACEMENT),
      'longitude' => @bot_centroid['longitude'] + rand(-BOT_TEAM_DISPLACEMENT..BOT_TEAM_DISPLACEMENT)
    }

    # add_kaitakaro(bot)
    @team_manager.add_player_to_team(bot)
  end

#   def add_kaitakaro(in_kaitakaro)
#     puts "FBO:#{@class_name} add_kaitakaro".green if DEBUGGING
#
#     @kaitakaro_array << in_kaitakaro
#     @kaitakaro_hash[in_kaitakaro.data_hash['display_name']] = in_kaitakaro
#
#     # Testing
#     # @team_manager.add_player_to_team(in_kaitakaro)
#
#     # send update to UI
#     # This should ultimately be in the Kapa
#     Notification.center.post('PlayerNew', @kaitakaro_hash)
#   end

  def add_player(in_player)
    puts "FBO:#{@class_name} add_player".green if DEBUGGING

    # not sure we need this
    @kaitakaro_array << in_player
    @kaitakaro_hash[in_player.data_hash['display_name']] = in_player

    Notification.center.post('PlayerNew', @kaitakaro_hash)
  end

  # This need to delete from both array and Hash
  # and then delete the kapa if empty
  def remove_kaitakaro_from_kapa(in_kaitakaro_id, in_kapa_id)
    puts 'remove_kaitakaro_from_kapa'.light_blue

    # Find the kapa
    kapa = @local_kapa_array.select { |k| k.ref.key == in_kapa_id }.first
    kapa_empty = kapa.remove_kaitakaro(in_kaitakaro_id)

    kapa = nil if kapa_empty

    @local_kapa_array.delete_if { |k| k.ref.key == in_kapa_id }.first
  end

  def kapa_with_key(in_key)
    puts "takaro_fbo kapa_with_key: #{in_key}"
    @local_kapa_array.select { |k| k.ref.key == in_key }.first
  end

  # TODO: When a player moves too much, they can make a new kapa. Check for this?
  # TODO: if it's the only member, it can't move too far away?
  # This is never called?
  def get_kapa_for_coordinate(coordinate)
    puts "FBO:#{@class_name}:#{__LINE__} get_kapa_for_coordinate".green if DEBUGGING

    # check existing kapa
    @local_kapa_array.each do |k|
      return k if k.check_distance(coordinate)
    end

    # add a new kapa if there aren't enough
    if @local_kapa_array.count < TEAM_COUNT
      puts "FBO:#{@class_name}:#{__LINE__} creating new kapa".green if DEBUGGING
      k = create_kapa(coordinate)
      return k
    end

    # otherwise, we're too far
    nil
  end

#   # rubocop:disable Metrics/AbcSize
#   # THIS IS NEXT!
#   def set_initial_pouwhenua
#     puts "FBO:#{@class_name}:#{__LINE__} set_initial_pouwhenua".green if DEBUGGING
#     coord_array = []
#
#     # instead of a local array, we should pull from the DB?
#     # Can't we just use @teams_hash?
#     @local_kapa_array.each do |k|
#       data = k.data_for_pouwhenua
#       # mp data
#
#       # TODO: Should these initial pouwhenua ever die?
#       # data.merge!('lifespan_ms' => 120_000)
#       data.merge!('lifespan_ms' => duration * 60 * 1000)
#
#       create_new_pouwhenua_from_hash(data, true)
#
#       # add to local coords
#       coord_array << k.coordinate
#     end
#
#     # use coords to calculate play area
#     lats = coord_array.map { |c| c['latitude'] }.minmax
#     longs = coord_array.map { |c| c['longitude'] }.minmax
#
#     # This is a hack way to find the midpoint
#     # A more accurate solution is here:
#     # https://stackoverflow.com/questions/10559219/determining-midpoint-between-2-coordinates
#     midpoint_array = [(lats[0] + lats[1]) * 0.5, (longs[0] + longs[1]) * 0.5]
#     midpoint_location = CLLocation.alloc.initWithLatitude(midpoint_array[0], longitude: midpoint_array[1])
#     top_location = CLLocation.alloc.initWithLatitude(lats[1], longitude: midpoint_array[1])
#     right_location = CLLocation.alloc.initWithLatitude(midpoint_array[0], longitude: longs[1])
#     latitude_delta = midpoint_location.distanceFromLocation(top_location)
#     longitude_delta = midpoint_location.distanceFromLocation(right_location)
#
#     @taiapa_center = MKMapPointForCoordinate(CLLocationCoordinate2DMake(midpoint_array[0], midpoint_array[1]))
#
#     # Sometimes the resulting rectangle is super narrow
#     # resize based on the longer side and golden ratio
#     if latitude_delta < longitude_delta
#       latitude_delta = longitude_delta * 0.618034
#     else
#       longitude_delta = latitude_delta * 0.618034
#     end
#
#     @taiapa_region = MKCoordinateRegionMakeWithDistance(
#       midpoint_location.coordinate, latitude_delta * 3, longitude_delta * 3
#     )
#     self.taiapa = {
#       'midpoint' => midpoint_location.coordinate.to_hash,
#       'latitude_delta' => latitude_delta * 3,
#       'longitude_delta' => longitude_delta * 3
#     }
#
#     # TODO: Should this be in the Machine?
#     Machine.instance.is_waiting = false
#     Machine.instance.current_view.performSegueWithIdentifier('ToGameCountdown', sender: self)
#   end
#   # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  # THIS IS NEXT!
  def set_initial_markers
    mp __method__

    # get the teams coordinates
    coord_array = []
    mp ['teams_hash', @teams_hash]
    # coord_array = @teams_hash { |k,v| v['coordinate'] }
    @teams_hash.each do |k, t|
      # data = k.data_for_pouwhenua
      new_marker_data = {
        'kapa_key' => t['key'],
        'color' => t['color'],
        'coordinate' => t['coordinate'],
        'enabled' => 'true'
      }
      mp new_marker_data
      new_marker_data.merge!('lifespan_ms' => duration * 60 * 1000)
      create_new_marker_from_hash(new_marker_data, true)
      coord_array << t['coordinate']
    end
    mp ['coord_array', coord_array]

    # We should check if there are two team coordinates here
    # If not prior to

    # use coords to calculate play area
    lats = coord_array.map { |c| c['latitude'] }.minmax
    longs = coord_array.map { |c| c['longitude'] }.minmax

    mp ['corners', [lats, longs]]

    # This is a hack way to find the midpoint
    # A more accurate solution is here:
    # https://stackoverflow.com/questions/10559219/determining-midpoint-between-2-coordinates
    midpoint_array = [(lats[0] + lats[1]) * 0.5, (longs[0] + longs[1]) * 0.5]
    midpoint_location = CLLocation.alloc.initWithLatitude(midpoint_array[0], longitude: midpoint_array[1])
    top_location = CLLocation.alloc.initWithLatitude(lats[1], longitude: midpoint_array[1])
    right_location = CLLocation.alloc.initWithLatitude(midpoint_array[0], longitude: longs[1])
    latitude_delta = midpoint_location.distanceFromLocation(top_location)
    longitude_delta = midpoint_location.distanceFromLocation(right_location)

    @taiapa_center = MKMapPointForCoordinate(CLLocationCoordinate2DMake(midpoint_array[0], midpoint_array[1]))

    # Sometimes the resulting rectangle is super narrow
    # resize based on the longer side and golden ratio
    if latitude_delta < longitude_delta
      latitude_delta = longitude_delta * 0.618034
    else
      longitude_delta = latitude_delta * 0.618034
    end

    # change this
    # and also in voronoi_map.rb line 21
    @taiapa_region = MKCoordinateRegionMakeWithDistance(
      midpoint_location.coordinate, latitude_delta * 3, longitude_delta * 3
    )
    # self.taiapa = {
    #   'midpoint' => midpoint_location.coordinate.to_hash,
    #   'latitude_delta' => latitude_delta * 3,
    #   'longitude_delta' => longitude_delta * 3
    # }
    self.playfield = {
      'midpoint' => midpoint_location.coordinate.to_hash,
      'latitude_delta' => latitude_delta * FIELD_SCALE,
      'longitude_delta' => longitude_delta * FIELD_SCALE
    }

    # TODO: Should this be in the Machine?
    # TODO: make the transition a reaction to setting the playfield
    # Machine.instance.is_waiting = false
    # Machine.instance.current_view.performSegueWithIdentifier('ToGameCountdown', sender: self)
    @ref.child('game_state').setValue('ready')
  end
  # rubocop:enable Metrics/AbcSize

#   def create_new_pouwhenua_from_hash(arg_hash = {}, is_initial = false)
#     puts "FBO:#{@class_name}:#{__LINE__} create_new_pouwhenua_from_hash".green if DEBUGGING
#
#     # Check if the player still has available pouwhenua
#     # puts @local_kaitakaro.pouwhenua_current.to_s.focus
#     return if @local_kaitakaro.pouwhenua_current <= 0
#
#     # the format we want to end up with:
#     # color,
#     # coordinate,
#     # title,
#     # kapa_key,
#     # lifespan
#
#     # get the player info
#     new_pouwhenua_hash = @local_kaitakaro.data_for_pouwhenua.merge arg_hash
#
#     # remove the kaitakaro for initial pouwhenua
#     # TODO: not sure we need this, it's also super clunky
#     new_pouwhenua_hash.delete('kaitakaro_key') if is_initial
#
#     p = PouwhenuaFbo.new(
#       @ref.child('pouwhenua').childByAutoId, new_pouwhenua_hash
#     )
#     @local_pouwhenua << p
#
#     @local_kaitakaro.pouwhenua_decrement unless is_initial
#
#     pull
#   end

  def create_new_marker_from_hash(arg_hash = {}, is_initial = false)
    mp __method__
    mp arg_hash
    mp @local_player
    mp @local_player.marker_current

    # no availble markers
    if @local_player.marker_current <= 0 && !is_initial
      mp 'no available markers!'
      return
    end

    # get player info
    new_marker_hash = @local_player.data_for_marker.merge arg_hash

    # this is clunky
    new_marker_hash.delete('player_key') if is_initial
    new_marker_hash['enabled'] = 'true'

    # new_marker = Marker.new(
    #   @ref.child('markers').childByAutoId, new_marker_hash
    # )

    mp 'creating new marker'
    new_marker = @ref.child('markers').childByAutoId
    new_marker.setValue(
      new_marker_hash
    )

    @local_player.marker_decrement unless is_initial
  end

  # TableView methods
  def player_count_for_index(in_index)
    mp __method__

    return 0 if in_index >= @teams_hash.count
    return 0 if @teams_hash.empty?
    return 0 if @teams_hash.values[in_index].nil?

    @teams_hash.values[in_index]['players'].count
  end

  def list_player_names_for_index(in_index)
    mp __method__
    puts "FBO:#{@class_name} list_player_names_for_index".green if DEBUGGING

    @teams_hash.values[in_index]['players'].values.map{ |p| {
      'display_name' => p['display_name'],
      'character' => p['character']
    } }
  end

  def calculate_score
    puts 'calculate_score'
  end

  # Helpers
  def gamecode
    @data_hash['gamecode']
  end

  def gamecode=(in_gamecode)
    update({ 'gamecode' => in_gamecode })
  end

  def duration
    @data_hash['duration']
  end

  def duration=(in_duration)
    update({ 'duration' => in_duration })
  end

  def kapa_hash
    @data_hash['kapa']
  end

  def kapa_array
    kapa_hash&.values
  end

  def kaitakaro
    @data_hash['kaitakaro']
  end

  def kaitakaro_for_kapa(kapa_key = @local_kaitakaro.kapa['kapa_key'])
    kaitakaro.select { |_key, value| value['kapa']['kapa_key'] == kapa_key }
  end

  def pouwhenua_array
    # puts "pouwhenua_array: #{@data_hash['pouwhenua']&.values}"
    @data_hash['pouwhenua']&.values

    # TODO: This doesn't seem to work
    # h = @data_hash['pouwhenua']&.select { |p| p['enabled'] == 'true' }
    # h&.values
  end

  def pouwhenua_array_for_kapa(kapa_key = @local_kaitakaro.kapa['kapa_key'])
    pouwhenua_array.select { |p| p['kapa_key'] == kapa_key && p['enabled'] == 'true' }
  end

  def pouwhenua_array_enabled_only
    pouwhenua_array.select { |p| p['enabled'] == 'true' }
  end

  def markers_array_enabled_only
    mp __method__
    @ref.child('markers').queryOrderedByChild('enabled').queryEqualToValue('true').observeSingleEventOfType(FIRDataEventTypeValue, withBlock:
      lambda do |error, snapshot|
        mp snapshot.value
        return snapshot.value
      end
    )
  end

  def taiapa=(in_region)
    update({ 'taiapa' => in_region })
  end

  def taiapa
    @data_hash['taiapa']
  end

  def playfield=(in_region)
    update({ 'playfield' => in_region })
  end

  def playfield
    @data_hash['playfield']
  end

  def waiting?
    @data_hash['waiting']
  end

  def waiting=(in_waiting)
    update({ 'waiting' => in_waiting })
  end

  def playing?
    @data_hash['playing']
  end

  def playing=(in_playing)
    update({ 'playing' => in_playing })
  end

#   def game_state
#     @data_hash['game_state']
#   end
#
#   def game_state=(in_state)
#     update({ 'game_state' => in_state })
#   end

  def score(kapa_key, score)
    puts "Score for #{kapa_key}: #{score}".focus
    # mp kapa_hash
    # mp local_kapa_array
  end

#   def kaitakaro_annotations
#     # puts 'kaitakaro_annotations'
#     annotations = []
#
#     # this just gets the local kaitakaro's kapa
#     kaitakaro_for_kapa.each do |k|
#       # TODO: this is a hack
#       # perhaps we need to massage in the kaitakaro method
#       k_hash = k[1]
#
#       ka = KaitakaroAnnotation.alloc.initWithCoordinate(
#         Utilities::format_to_location_coord(k_hash['coordinate'])
#       )
#       ka.color = UIColor.alloc.initWithCIColor(CIColor.alloc.initWithString(k_hash['kapa']['color']))
#       ka.title = k_hash['display_name']
#       ka.subtitle = k_hash['character']['title']
#       annotations << ka
#     end
#
#     # puts "Annotations: #{annotations}".focus
#     annotations
#   end

  def player_annotations
    mp __method__
    mp @teams_hash.values
    annotations = []
    @teams_hash.values.each do |t|
      t['players'].values.each do |p|
        ka = KaitakaroAnnotation.alloc.initWithCoordinate(
          Utilities::format_to_location_coord(p['coordinate'])
        )
        ka.color = UIColor.alloc.initWithCIColor(CIColor.alloc.initWithString(t['color']))
        ka.title = p['display_name']
        ka.subtitle = p['character']
        annotations << ka
      end
    end
    annotations
  end

#   def pouwhenua_annotations
#     annotations = []
#
#     # this just gets the local kaitakaro's kapa
#     pouwhenua_array_for_kapa.each do |p|
#       pa = PouAnnotation.alloc.initWithCoordinate(
#         Utilities::format_to_location_coord(p['coordinate'])
#       )
#       pa.color = UIColor.alloc.initWithCIColor(CIColor.alloc.initWithString(p['color']))
#       annotations << pa
#     end
#
#     # puts "Annotations: #{annotations}".focus
#     annotations
#   end

  def marker_annotations
    __method__
    mp @marker_hash.values
    annotations = []
      @marker_hash.values.each do |m|
        pa = PouAnnotation.alloc.initWithCoordinate(
          Utilities::format_to_location_coord(m['coordinate'])
        )
        pa.color = UIColor.alloc.initWithCIColor(CIColor.alloc.initWithString(m['color']))
        annotations << pa
      end
    annotations
  end
end

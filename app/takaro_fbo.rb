class TakaroFbo < FirebaseObject
  attr_accessor :team_manager,
                :kaitakaro_array,
                :kaitakaro_hash,
                :teams_hash,
                :local_kapa_array,
                :local_kaitakaro,
                :local_player,
                :bot_centroid,
                :pouwhenua_is_dirty,
                :markers_hash,
                :game_state_machine,
                :players_hash,
                :taiapa_region # TODO: this might be hash later?

  DEBUGGING = true

  TEAM_DISTANCE = 3
  MOVE_THRESHOLD = 2
  TEAM_COUNT = 2
  FIELD_SCALE = 3
  BOT_DISTANCE = 0.001
  BOT_TEAM_DISPLACEMENT = 5 * 10**-14

  def initialize(in_ref, in_data_hash)
    mp __method__

    @team_manager = TeamManager.new
    @kaitakaro_array = []
    @kaitakaro_hash = {}
    @teams_hash = {}
    @markers_hash = {}
    @players_hash = {}
    @local_kapa_array = []
    @pouwhenua_is_dirty = true

    puts 'TakaroFbo initialize'.red
    super.tap do |t|
      unless in_data_hash.nil?
        t.initialize_firebase_observers

        # set up game state state machine
        t.initialize_state_machine
        t.game_state_machine.start!
      end
    end
    Utilities::puts_close
  end

  # rubocop:disable Metrics/AbcSize
  def initialize_firebase_observers
    mp __method__
    # All Players
#     @ref.child('players').observeEventType(FIRDataEventTypeValue, withBlock:
#       lambda do |players_snapshot|
#         mp 'Takaro observe players'
#         mp players_snapshot.valueInExportFormat
#
#         # update the local hash
#         @players_hash = players_snapshot.valueInExportFormat
#       end)
    # Specific Players
    @ref.child('players').observeEventType(FIRDataEventTypeChildChanged, withBlock:
      lambda do |player_snapshot|
        mp 'Takaro observe player changed'
        mp player_snapshot.valueInExportFormat

        # update the specific player
        @players_hash[player_snapshot.key] = player_snapshot.valueInExportFormat
        mp @players_hash

        Notification.center.post('player_moved')
      end)
    # Specific Team
    @ref.child('teams').observeEventType(FIRDataEventTypeChildChanged, withBlock:
      lambda do |teams_snapshot|
        teams_snapshot.ref.parent.getDataWithCompletionBlock(
          lambda do |error, snapshot|
            @teams_hash = snapshot.childSnapshotForPath('teams').valueInExportFormat
            Notification.center.post('teams_changed', @teams_hash)
          end
        )
      end)
    # All Teams
    # @ref.child('teams').observeEventType(FIRDataEventTypeValue, withBlock:
    #   lambda do |teams_snapshot|
    #     mp 'TEAMS VALUE CALLBACK'
    #     mp teams_snapshot.value
    #     # @teams_hash = teams_snapshot.value.values
    #     # Notification.center.post("teams_changed", @teams_hash)
    #   end
    # )
    # Markers
    @ref.child('markers').queryOrderedByChild('enabled').queryEqualToValue('true').observeEventType(FIRDataEventTypeValue, withBlock:
      lambda do |markers_snapshot|
        # mp 'MARKERS ENABLED CALLBACK'
        # mp markers_snapshot.value
        @markers_hash = markers_snapshot.value
        Notification.center.post("markers_changed", @markers_hash)
      end
    )

    @ref.child('game_state').observeEventType(
      FIRDataEventTypeValue, withBlock: lambda do |game_state_snapshot|
        # mp 'GAME_STATE SAVED'
        # mp game_state_snapshot.value

        if game_state_snapshot.value == 'ready'
          Machine.instance.current_view.performSegueWithIdentifier('ToGameCountdown', sender: self)
        end
      end
    )

    # This updates the player location in the location child
    @location_update_observer = Notification.center.observe 'UpdateLocation' do |data|
      mp 'Takaro observe update location'

      new_location = data.object['new_location']
      _old_location = data.object['old_location']

      unless @local_player.nil?
        # mp 'updating location child'
        @ref.child("location/#{@local_player.key}").setValue(new_location.to_hash)
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  def initialize_state_machine
    mp __method__

    @game_state_machine = StateMachine::Base.new start_state: :initializing, verbose: DEBUGGING

    ####################
    # SPLASH SCREEN
    @game_state_machine.when :initializing do |state|
      state.on_entry { mp 'game_state start initializing' }
      state.on_exit { mp 'game_state end initializing' }
      state.transition_to :options,
                          on_notification: 'game_state_options_notification',
                          action: proc { self.game_state = 'options' }
    end
    ####################
    # OPTIONS
    @game_state_machine.when :options do |state|
      state.on_entry { mp 'game_state start options' }
      state.on_exit { mp 'game_state end options' }
      state.transition_to :character_selection,
                          on_notification: 'game_state_charcater_selection_notification',
                          action: proc { self.game_state = 'character_selection' }
    end
    ####################
    # CHARACTER SELECTION
    @game_state_machine.when :character_selection do |state|
      state.on_entry { mp 'game_state start character_selection' }
      state.on_exit { mp 'game_state end character_selection' }
      state.transition_to :waiting_room,
                          on_notification: 'game_state_waiting_room_notification',
                          action: proc { self.game_state = 'waiting_room' }
    end
    ####################
    # WAITING ROOM
    @game_state_machine.when :waiting_room do |state|
      state.on_entry { mp 'game_state start waiting_room' }
      state.on_exit { mp 'game_state end waiting_room' }

      state.transition_to :countdown,
                          on_notification: 'game_state_countdown_notification',
                          action: proc {
                            self.game_state = 'countdown'
                            Machine.instance.current_view.performSegueWithIdentifier('ToGameCountdown', sender: self)
                          }
    end
    ####################
    # STARTING
    @game_state_machine.when :countdown do |state|
      state.on_entry { mp 'game_state start countdown' }
      state.on_exit { mp 'game_state end countdown' }

      state.transition_to :playing,
                          on_notification: 'game_state_playing_notification',
                          action: proc {
                            self.game_state = 'playing'
                          }
    end
    ####################
    # PLAYING
    @game_state_machine.when :playing do |state|
      state.on_entry { mp 'game_state start playing' }
      state.on_exit { mp 'game_state end playing' }

      # state.transition_to :options,
      #                     on_notification: 'game_state_start_notification'
    end
  end
  # rubocop:enable Metrics/AbcSize

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
    mp 'local_player:'
    mp @local_player
  end

  def create_bot_player
    mp __method__

    # mp 'bot_centroid before:'
    # mp @bot_centroid
    # mp 'local coords:'
    # mp @local_player.coordinate

    # grab local player coordinate if not defined
    @bot_centroid ||= {
      'latitude' => @local_player.coordinate['latitude'] + rand(-BOT_DISTANCE..BOT_DISTANCE),
      'longitude' => @local_player.coordinate['longitude'] + rand(-BOT_DISTANCE..BOT_DISTANCE)
    }
    # mp 'bot_centroid after:'
    # mp @bot_centroid

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

    bot.coordinate = {
      'latitude' => @bot_centroid['latitude'] + rand(-BOT_TEAM_DISPLACEMENT..BOT_TEAM_DISPLACEMENT),
      'longitude' => @bot_centroid['longitude'] + rand(-BOT_TEAM_DISPLACEMENT..BOT_TEAM_DISPLACEMENT)
    }
    # mp bot.coordinate

    # add_kaitakaro(bot)
    # @team_manager.add_player_to_team(bot)
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

  # rubocop:disable Metrics/AbcSize
  # THIS IS NEXT!
  # This is doing a lot of heavy lifting
  def set_initial_markers
    mp __method__

    # get the teams coordinates
    coord_array = []
    # mp ['teams_hash', @teams_hash]
    # coord_array = @teams_hash { |k,v| v['coordinate'] }

    mp 'iterating through teams'
    @teams_hash.each do |k, team|
      mp 'team'
      mp team
      new_marker_data = {
        # 'key' => team['key'],
        'team_key' => k,
        'color' => team['color'],
        'coordinate' => team['coordinate'],
        'enabled' => 'true'
      }
      # mp new_marker_data
      new_marker_data.merge!('lifespan_ms' => duration * 60 * 1000)
      create_new_marker_from_hash(new_marker_data, true)
      coord_array << team['coordinate']
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

    self.playfield = {
      'midpoint' => midpoint_location.coordinate.to_hash,
      'latitude_delta' => latitude_delta * FIELD_SCALE,
      'longitude_delta' => longitude_delta * FIELD_SCALE
    }

    Notification.center.post('game_state_countdown_notification', nil)
  end
  # rubocop:enable Metrics/AbcSize

  def create_new_marker_from_hash(arg_hash = {}, is_initial = false)
    mp __method__
    # mp arg_hash
    # mp @local_player
    # mp @local_player.marker_current

    # no availble markers
    if @local_player.marker_current <= 0 && !is_initial
      mp 'no available markers!'
      return
    end

    # get player info
    new_markers_hash = @local_player.data_for_marker.merge arg_hash

    # this is clunky
    new_markers_hash.delete('player_key') if is_initial
    new_markers_hash['enabled'] = 'true'

    # new_marker = Marker.new(
    #   @ref.child('markers').childByAutoId, new_markers_hash
    # )

    mp 'creating new marker'
    new_marker = @ref.child('markers').childByAutoId
    new_marker.setValue(
      new_markers_hash
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

    @teams_hash.values[in_index]['players'].values.map do |p|
      {
        'display_name' => p['display_name'],
        'character' => p['character']
      }
    end
  end

  # def calculate_score
  #   puts 'calculate_score'
  # end

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
        # mp snapshot.value
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

  def game_state
    mp __method__
    @game_state_machine.current_state.name
  end

  def game_state=(in_state)
    mp __method__
    @ref.child('game_state').setValue(in_state)
  end

  def score(kapa_key, score)
    puts "Score for #{kapa_key}: #{score}".focus
  end

  # This uses the teams
  # but we can also use the players, now that they each have a color
  def player_annotations
    mp __method__
    annotations = []

    # the new local hash way
    mp 'iterating through players'
    @players_hash.each_value do |player|
      mp player
      player_annotation = PlayerAnnotation.alloc.initWithCoordinate(
        Utilities::format_to_location_coord(player['coordinate'])
      )

      player_annotation.color = UIColor.alloc.initWithCIColor(
        CIColor.alloc.initWithString(player['color'])
      )
      player_annotation.title = player['display_name']
      player_annotation.subtitle = player['character']

      annotations << player_annotation
    end

    annotations
  end

  def marker_annotations
    __method__

    annotations = []
    @markers_hash.each_value do |marker|
      marker_annotation = MarkerAnnotation.alloc.initWithCoordinate(
        Utilities::format_to_location_coord(marker['coordinate'])
      )

      marker_annotation.color = UIColor.alloc.initWithCIColor(
        CIColor.alloc.initWithString(marker['color'])
      )

      annotations << marker_annotation
    end

    annotations
  end
end

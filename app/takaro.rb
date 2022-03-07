class Takaro
  extend Utilities

  attr_accessor :ref,
                :uuid,
                :local_player_ref,
                # :nga_kapa,
                # :nga_kapa_hash,
                :kapa_array,
                :machine,
                :kapa_observer_handle,
                :nga_kapa_observer_handle_array,
                :player_observer_handle,
                :local_player_locationCoords,
                :local_player_name,
                :local_player_kapa_ref,
                :local_kaitakaro,
                :local_kaitakaro_hash,
                :taiapa, # the field, as MKRect
                :taiapa_center, # as MKMapPoint
                :taiapa_region, # as MKCoordinateRegion
                :pouwhenua,
                :pouwhenua_array,
                :player_classes

  DEBUGGING = false
  TEAM_DISTANCE = 3
  MOVE_THRESHOLD = 2
  TEAM_COUNT = 2
  FIELD_SCALE = 1.5

  @accepting_new_players = true

  ##
  # DATA STRUCTURES
  #
  # LOCAL
  # kapa_array
  # [
  #   {
  #     "id" => id,
  #     "players" => ["player_a", "player_b", ...]
  #     "coordinate" =>
  #     {
  #       "latitude" => x,
  #       "longitude" => y
  #     },
  #     "color" =>
  #      {
  #
  #      }
  #   }
  # ]
  #
  # pouwhenua_array
  # [
  #   {
  #     "title" => title,
  #     "color =>
  #     {
  #       ???
  #     },
  #     "coordinate" =>
  #     {
  #       "latitude" => x,
  #       "longitude" => y
  #     }
  #   }
  # ]
  #
  #
  # FIREBASE
  # GAME
  # - uuid
  #   - gamecode
  #   - KAPA
  #     - created
  #     - KAITAKARO
  #       - firebase_id
  #         - COORDINATE
  #           - latitude
  #           - longitude
  #         - name
  #     - COORDINATE
  #       - latitude
  #       - longitude
  #   - PLAYERS
  #     - firebase_id
  #       - COORDINATE
  #         - latitude
  #         - longitude
  #       - display_name
  #       - email
  #       - team
  #       - user_id

  ##
  # Creates a new Takaro, or initializes from a +in_uuid+ string.
  # uuid is a string.
  def initialize(in_id = nil)
    puts "TAKARO INITIALIZE".light_blue if DEBUGGING
    @kapa_array = []
    @pouwhenua_array = []
    @local_kaitakaro_hash = {}

    # set up the new game
    if in_id
      @ref = Machine.instance.db.referenceWithPath("games/#{in_id}")
    else
      @ref = Machine.instance.db.referenceWithPath("games").childByAutoId
    end

    new_gamecode = generate_new_id
    @ref.updateChildValues({"gamecode" => new_gamecode}, withCompletionBlock:
      lambda do | error, game_ref |
        App.notification_center.post("GamecodeNew", new_gamecode)
      end
    ) unless in_id

    # get the player classes
    Machine.instance.db.referenceWithPath('player_classes').getDataWithCompletionBlock(
      lambda do | error, data |
        @player_classes = data.valueInExportFormat
        puts "Player classes: #{@player_classes}".focus
      end
    )

    #################
    # Machine Stuff
    #################

    @machine = StateMachine::Base.new start_state: :start, verbose: DEBUGGING
    @machine.when :start do |state|
      state.on_entry { puts "Takaro state start".pink }
      state.transition_to :pull_remote_kapa, on: :go_to_pull_remote_kapa
    end
    @machine.when :pull_remote_kapa do |state|
      state.on_entry {
        init_kapa
        # pull_remote_kapa
      }
      state.transition_to :set_up_observers, on: :go_to_set_up_observers
    end
    @machine.when :set_up_observers do |state|
      state.on_entry { set_up_observers }
      state.transition_to :awaiting_players, on: :go_to_awaiting_players
      # state.transition_to :clean_up, on: :go_to_clean_up
    end
    # @machine.when :clean_up do |state|
    #   state.on_entry { puts "Takaro clean_up".pink }
    #   # state.transition_to :awaiting_players, on: :go_to_awaiting_players
    # end
    @machine.when :awaiting_players do |state|
      state.on_entry { puts "Takaro awaiting_players".pink }
    end
    @machine.start!
    @machine.event :go_to_pull_remote_kapa

    add_local_player

    # TODO do we need this?
    self
  end

  #################
  # Sync Functions
  #################
  # Not entirely sure we need this.

  # def start_syncing
  #   puts "TAKARO START_SYNCING".blue if DEBUGGING
  #   # keep everything up to date
  #   @ref.keepSynced true
  # end
  #
  # def stop_syncing
  #   puts "TAKARO STOP_SYNCING".blue if DEBUGGING
  #   @ref.keepSynced false
  # end

  # This method should check to see if any kapa exist on the server
  # and if not, it should create them
  ##
  #
  # INITIALIZE THE KAPA (TEAMS)
  #
  def init_kapa
    puts "TAKARO INIT_KAPA".blue if DEBUGGING

    # Check first for server kapa
    @ref.child("kapa").getDataWithCompletionBlock(
      lambda do | error, kapa_snapshot |
        # childCount = kapa_snapshot?.hasChildren || 0
        childCount = kapa_snapshot.nil? ? 0 : kapa_snapshot.childrenCount
        TEAM_COUNT.times do |i|
          if childCount > i
            # There is already one on the server
            # get its data and add it to the local hash
            current_kapa_snapshot = kapa_snapshot.children.allObjects[i]
            current_kapa_ref = current_kapa_snapshot.ref
            @kapa_array[i] = {
              "id" => current_kapa_snapshot.key,
              "players" => [],
              "coordinate" => {},
              "color" => current_kapa_snapshot.childSnapshotForPath("color").value
            }
            # and pull down the player names
            kapa_snapshot.ref.child("kaitakaro").getDataWithCompletionBlock(
              lambda do | error, player_snapshot |
                player_snapshot.children.each do |current_player_snapshot|
                  current_player_name = current_player_snapshot.childSnapshotForPath("display_name").value
                  @kaitakaro_hash["display_name"] = current_player_name
                  # puts "current_player_name:#{current_player_name}".focus
                  @kapa_array[i]["players"] << current_player_name
                end
              end
            )
          else
            # We need to create a new one
            color_string = rand.to_s.slice(0..4)
            color_string << " "
            color_string << rand.to_s.slice(0..4)
            color_string << " "
            color_string << rand.to_s.slice(0..4)
            color_string << " 1.0"

            current_kapa_ref = @ref.child("kapa").childByAutoId
            current_kapa_ref.updateChildValues(
              {
                "created" => FIRServerValue.timestamp,
                "color" => color_string
              }
            )
            @kapa_array << {
              "id" => current_kapa_ref.key,
              "players" => [],
              "coordinate" => {},
              "color" => color_string
            }
          end

          # then we need to add the observers
          current_kapa_ref.child("kaitakaro").observeEventType(FIRDataEventTypeChildAdded,
            withBlock: lambda do |kaitakaro_snapshot|
              puts "TAKARO INIT_KAPA KAITAKARO CHILD ADDED".blue if DEBUGGING
              puts "Info: #{kaitakaro_snapshot.value}"
              # puts "kapa_snapshot: #{kapa_snapshot.ref.URL}"
              update_kapa_location(current_kapa_ref)
            end
          )

          @machine.event :go_to_set_up_observers
        end
      end
    )
  end

  #################
  # Database Observers
  #################

  def set_up_observers
    puts "TAKARO SET_UP_OBSERVERS".blue if DEBUGGING

    ##
    #
    # PLAYER ADDED
    #
    @ref.child("players").queryLimitedToLast(1).observeEventType(FIRDataEventTypeChildAdded,
      withBlock: proc do |player_snapshot|
        puts "TAKARO PLAYERADDED".red if DEBUGGING

        # Let's take a look at who the player is
        puts "new player: #{player_snapshot.value}" if DEBUGGING
      end # player lambda
    )

    ##
    #
    # PLAYER EDITED
    #
    @ref.child("players").observeEventType(FIRDataEventTypeChildChanged,
      withBlock: proc do |player_snapshot|
        # TODO this adds an existing player, need to change!
        puts "Updated player: #{player_snapshot.value}" if DEBUGGING

        # Okay what is going on here
        # if the player _has_ a team, we need to check if they are already in the team
        player_team = player_snapshot.childSnapshotForPath("team")
        if player_team.exists
          player_team_id = player_team.value
          # puts "player_team_id: #{player_team_id}"
          player_display_name = player_snapshot.childSnapshotForPath("display_name").value
          # puts "player_display_name: #{player_display_name}"

          # puts "kapa_array (241): #{@kapa_array}".focus
          kapa_in_array = @kapa_array.find { |k| k["id"] == player_team_id }
          # puts "kapa_in_array: #{kapa_in_array}".focus

          unless kapa_in_array["players"].include?(player_display_name)
            kapa_in_array["players"] << player_display_name
          end

          # puts "kapa_array: #{@kapa_array}"
          App.notification_center.post "PlayerNew"
        end
      end
    )

    ##
    #
    # LOCAL PLAYER LOCATION UPDATED
    #
    @takaro_update_location_observer_coord = App.notification_center.observe "UpdateLocation" do |data|
      puts "TAKARO UPDATELOCALPLAYERPOSITION LOCATION".yellow if DEBUGGING

      new_location = data.object["new_location"]
      old_location = data.object["old_location"]

      puts "new_location: #{new_location.coordinate.latitude}" if DEBUGGING
      puts "old_location: #{old_location.coordinate.latitude}" if DEBUGGING

      App.notification_center.post("UpdateLocalPlayerPositionAsLocation",
        {"new_location" => new_location, "old_location" => old_location}
      )

      @local_player_locationCoords = new_location.coordinate
      @local_kaitakaro_hash["coordinate"] = new_location.coordinate.to_firebase
    end

    ##
    #
    # ADD NEW POUWHENUA
    #
    @takaro_add_new_pouwhenua = App.notification_center.observe "PouwhenuaNew" do |data|
      puts "TAKARO ADD NEW POUWHENUA".focus
      puts "data object: #{data.object}"
    end

    puts @machine.current_state.name
    @machine.event :go_to_awaiting_players
    # puts "Transitioning out".focus
    @machine.event :go_to_awaiting_players
    puts @machine.current_state.name
  end

  #################
  # Local Data
  #################

  def create_new_remote_kapa
    puts "TAKARO CREATE_NEW_REMOTE_KAPA".blue if DEBUGGING
    # TODO We need to check here if there are existing kapa!
    @ref.child("kapa").childByAutoId.updateChildValues({index: 0}, withCompletionBlock:
      lambda do | error, child_ref |
        @ref.child("kapa").childByAutoId.updateChildValues({index: 1})
      end
    )
  end

  # This needs to do the hard labour of setting the kapa
  # and it all needs to be local, then sent to server
  # does this need to be a separate method?
  # Also, this fails when not connected to the internet
  def add_local_player(in_user = Machine.instance.user)
    puts "TAKARO ADD_LOCAL_PLAYER".blue if DEBUGGING
    @local_kaitakaro = Kaitarako.new(@ref.child("players").childByAutoId, {"takaro" => self})
    @local_kaitakaro.user_id = in_user.uid
    @local_kaitakaro.display_name = in_user.displayName
    @local_kaitakaro.email = in_user.email
    @local_kaitakaro.is_local = true
    @local_kaitakaro.player_class = @local_kaitakaro_hash['player_class']

    @local_kaitakaro_hash = {
      'user_id' => in_user.uid,
      'display_name' => in_user.displayName,
      'email' => in_user.email,
      'is_local' => true,
      # 'player_class' => kaitakaro_hash['player_class']
    }
    puts @local_kaitakaro_hash
  end

  # TODO: This is not working -- maybe the kapa aren't made yet?
  # This might be working now?
  def update_kapa_location(kapa_ref)
    puts "TAKARO UPDATE_KAPA_LOCATION".blue if DEBUGGING
    loc = CLLocationCoordinate2DMake(0, 0)

    puts "kapa_ref: #{kapa_ref.URL}" if DEBUGGING

    kapa_ref.child("kaitakaro").observeSingleEventOfType(FIRDataEventTypeValue , withBlock:
      lambda do |kapa_snapshot|
        lats = []
        longs = []
        # puts "observe version: #{kapa_snapshot.value}".focus

        # TODO This is an error
        kapa_snapshot.children.each do |pl|
          # puts "Coordinate: #{pl.childSnapshotForPath("coordinate").value}".focus
          pl_coord = pl.childSnapshotForPath("coordinate").value
          # puts pl_loc["latitude"].to_s
          # puts pl_loc["longitude"].to_s
          lats << pl_coord["latitude"]
          longs << pl_coord["longitude"]
        end
        lats_average = lats.inject{ |sum, el| sum + el }.to_f / lats.size
        longs_average = longs.inject{ |sum, el| sum + el }.to_f / longs.size
        kapa_ref.updateChildValues(
          {"coordinate" => {"latitude" => lats_average, "longitude" => longs_average}}
        )

        # update local kapa array
        @kapa_array.find { |k| k["id"] == kapa_ref.key}["coordinate"] = {
          "latitude" => lats_average,
          "longitude" => longs_average
        }
        # puts "kapa_array: #{@kapa_array}".focus
      end
    )
  end

  #################
  # Data for UI
  #################

  ##
  # Lists players for a given index.
  # TODO Not sure we need this
  def list_player_names_for_index(in_index)
    puts "TAKARO LIST_PLAYER_NAMES_FOR_INDEX".blue if DEBUGGING
    # @nga_kapa_hash.values[in_index]
    @kapa_array[in_index]["players"]
  end

  ##
  # Returns player count for a given index.
  def player_count_for_index(in_index)
    puts "TAKARO PLAYER_COUNT_FOR_INDEX".blue if DEBUGGING

    return 0 if @kapa_array.empty? || @kapa_array[in_index].empty? || @kapa_array[in_index]["players"].empty?
    @kapa_array[in_index]["players"].count
  end

  def list_player_classes_for_index(in_index)
    puts "TAKARO LIST_PLAYER_CLASSES_FOR_INDEX".blue if DEBUGGING
  end

  #################
  # Utility Functions
  #################

  def generate_new_id
    puts "TAKARO GENERATE_NEW_ID".blue if DEBUGGING
    # update the UI with the gamecode
    # https://gist.github.com/mbajur/2aba832a6df3fc31fe7a82d3109cb626
    rand(36**6).to_s(36)
  end

  #################
  # Pouwhenua Stuff
  #################

  ##
  #
  # Takes the first two kapa's locations as the starting Pouwhenua.
  #
  def set_initial_pouwhenua
    puts "TAKARO SET_INITIAL_POUWHENUA".blue if DEBUGGING

    coord_array = []

    @kapa_array.each do |k|
      # create remote instance
      # puts "Creating remote instance".focus
      create_new_pouwhenua(k["coordinate"], k['color'])

      # add to local coords
      coord_array << k["coordinate"]
    end

    # use coords to calculate play area
    lats = coord_array.map {|c| c["latitude"]}.minmax
    longs = coord_array.map {|c| c["longitude"]}.minmax

    # This is a hack way to find the midpoint
    # A more accurate solution is here:
    # https://stackoverflow.com/questions/10559219/determining-midpoint-between-2-coordinates
    midpoint_array = [(lats[0]+lats[1])*0.5, (longs[0]+longs[1])*0.5]
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

    @taiapa_region = MKCoordinateRegionMakeWithDistance(
      midpoint_location.coordinate, latitude_delta * 2 * FIELD_SCALE, longitude_delta * 2 * FIELD_SCALE
    )

    # We need to set all the teams for local players?
    # TODO sort this out
    # @local_kaitakaro.kapa_color = "0.8 1.0 1.0 1.0"
    puts "@local_kaitakaro.kapa_color: #{@local_kaitakaro.kapa_color}".focus

    # Then send us to the game
    # TODO should this be here?
    @local_kaitakaro.is_playing = true
    Machine.instance.segue("ToGame")
  end

  def start_observing_pouwhenua
    puts "TAKARO START_OBSERVING_POUWHENUA".blue if DEBUGGING
    # puts "TAKARO START_OBSERVING_POUWHENUA".focus

    @ref.child("pouwhenua").observeEventType(FIRDataEventTypeChildAdded,
      withBlock: lambda do | data |
        # puts "\n\nPOUWHENUA ADDED\n\n".focus

        # We've received a FIRDataSnapshot!
        new_pouwhenua = {}
        puts "data: #{data}"
        data.children.each do |s|
          new_pouwhenua[s.key] = s.value
        end
        # puts "#{new_pouwhenua}".focus
        # puts "#{(NSDate.now.timeIntervalSince1970 * 1000).round}"

        # Add the pouwhenua to the local array
        pouwhenua_array << new_pouwhenua
        puts "pouwhenua_array: #{pouwhenua_array}".focus

        # Should we turn it into a better-formed hash here?
        App.notification_center.post("PouwhenuaNew", data)
    end)
  end

  def create_new_pouwhenua(coord = @local_player_locationCoords, color = @local_kaitakaro.kapa_color)
    puts "TAKARO CREATE_NEW_POUWHENUA".blue if DEBUGGING
    coord = Utilities::format_to_location_coord(coord)
    puts "Color: #{color}".focus
    # puts "create_new_pouwhenua coord: #{coord.latitude}, #{coord.longitude}".focus
    # TODO restructure Pouwhenua
    # We need to create it remotely, then have the observers create the local version?
    @ref.child("pouwhenua").childByAutoId.updateChildValues(
      {
        'created' => FIRServerValue.timestamp,
        # 'color' => CIColor.blueColor.stringRepresentation,
        'color' => color,
        'location' => { 'latitude' => coord.latitude, 'longitude' => coord.longitude },
        'title' => 'Baked Beans'
      },
      withCompletionBlock: lambda do | error, child_ref |
        # puts "CREATED REMOTE POUWHENUA".focus
      end
    )
  end

  #################
  # Bot Stuff
  #################

  def create_bot_player
    puts "TAKARO CREATE_BOT_PLAYER".blue if DEBUGGING

    # TODO this doesn't create a real player?
    @bot = Kaitarako.new(@ref.child("players").childByAutoId, { "takaro" => self })
    @bot.player_class = @player_classes['tank']
    @bot.display_name = "Bot McBotface #{rand(30)}"
    @bot.email = "lucashaley@yahoo.com"
    lat = rand(37.336144370126..37.336144370127)
    long = -rand(122.059911595149..122.059911595150)
    # puts "#{lat}, #{long}".focus
    # @bot.coordinate = CLLocationCoordinate2DMake(37.33014437012663, -122.05991159514932)
    @bot.coordinate = CLLocationCoordinate2DMake(lat, long)
  end
end

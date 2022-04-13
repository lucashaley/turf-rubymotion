class Takaro
  extend Utilities

  attr_accessor :ref,
                :uuid,
                :local_player_ref,
                :nga_kapa,
                :nga_kapa_hash,
                :kapa_array,
                :machine,
                :kapa_observer_handle,
                :nga_kapa_observer_handle_array,
                :player_observer_handle,
                :local_player_locationCoords,
                :local_player_name,
                :local_player_kapa_ref,
                :local_kaitakaro_hash,
                :local_kaitakaro,
                :taiapa, # the field, as MKRect
                :taiapa_center, # as MKMapPoint
                :taiapa_region, # as MKCoordinateRegion
                :pouwhenua,
                :pouwhenua_array

  DEBUGGING = true
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
  #     "players" =>
  #     [
  #       {
  #         'display_name',
  #         'character'
  #       }, ...
  #     ]
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

  # def initialize(in_uuid = NSUUID.UUID.UUIDString
  def initialize(in_key = nil)
    puts 'TAKARO INITIALIZE'.light_blue if DEBUGGING
    puts "Creating new takaro with key: #{in_key}".pink if DEBUGGING

    if in_key.nil?
      @ref = Machine.instance.db.referenceWithPath('games').childByAutoId
    else
      @ref = Machine.instance.db.referenceWithPath("games/#{in_key}")
    end
    # unless in_key.nil?
    #   @ref = Machine.instance.db.referenceWithPath("games/#{in_key}")
    # else
    #   @ref = Machine.instance.db.referenceWithPath('games').childByAutoId
    # end

    # # TODO do we do this if we're not creating from scratch? Won't it overwrite?
    # # TODO yes it totally does
    # new_gamecode = generate_new_id
    # @ref.updateChildValues({"gamecode" => new_gamecode}, withCompletionBlock:
    #   lambda do | error, game_ref |
    #     App.notification_center.post("GamecodeNew", new_gamecode)
    #   end
    # ) unless in_key

    puts "New takaro: #{@ref.URL}" if DEBUGGING

    # This is used for updating the UI
    # And needs to have 0 and 1 indecies
    @nga_kapa_hash = {}
    @nga_kapa = []
    @kapa_array = []
    @pouwhenua_array = []
    @local_kaitakaro_hash = {}

    #################
    # Machine Stuff
    #################

    @machine = StateMachine::Base.new start_state: :start, verbose: DEBUGGING
    @machine.when :start do |state|
      state.on_entry { puts 'Takaro state start'.pink }
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

    # TODO: do we need this?
    self
  end

  #################
  # Sync Functions
  #################
  # Not entirely sure we need this.

  def start_syncing
    puts 'TAKARO START_SYNCING'.blue if DEBUGGING
    # keep everything up to date
    @ref.keepSynced true
  end

  def stop_syncing
    puts 'TAKARO STOP_SYNCING'.blue if DEBUGGING
    @ref.keepSynced false
  end

  # This method should check to see if any kapa exist on the server
  # and if not, it should create them
  ##
  #
  # INITIALIZE THE KAPA (TEAMS)
  #
  def init_kapa
    puts 'TAKARO INIT_KAPA'.blue if DEBUGGING
    
    @nga_kapa << Kapa.new(@ref.child('nga_kapa').childByAutoId)
    @nga_kapa << Kapa.new(@ref.child('nga_kapa').childByAutoId)

    # Check first for server kapa
    @ref.child('kapa').getDataWithCompletionBlock(
      lambda do | error, kapa_snapshot |
        # childCount = kapa_snapshot?.hasChildren || 0
        childCount = kapa_snapshot.nil? ? 0 : kapa_snapshot.childrenCount
        TEAM_COUNT.times do |i|
          puts "i: #{i}".yellow
          puts "childCount: #{childCount}".yellow
          if childCount > i
            # There is already one on the server
            # get its data and add it to the local hash
            current_kapa_snapshot = kapa_snapshot.children.allObjects[i]
            # current_kapa_ref = current_kapa_snapshot.ref

            # set up blank array
            @kapa_array[i] = {
              'id' => current_kapa_snapshot.key,
              'players' => [],
              'coordinate' => {},
              'color' => random_color_string
            }
            @nga_kapa_hash[current_kapa_snapshot.key] = 
            {
              'players' => [],
              'coordinate' => {},
              'color' => random_color_string
            }
            puts "nga_kapa_hash: #{@nga_kapa_hash.inspect}".yellow

            # and pull down the player names
            puts "current_kapa_snapshot: #{current_kapa_snapshot.inspect}".yellow
            # kapa_snapshot.ref.child("kaitakaro").getDataWithCompletionBlock(

            # TODO I'm totally not sure what is going on here
            # can't we just use the snapshot?
            # WHUT
            current_kapa_snapshot.ref.child('kaitakaro').getDataWithCompletionBlock(
              lambda do | error, player_snapshot |
                player_snapshot.children.each do |current_player_snapshot|
                  current_player_name = current_player_snapshot.childSnapshotForPath('display_name').value
                  current_player_character = current_player_snapshot.childSnapshotForPath('character').value
                  # puts "current_player_name:#{current_player_name}".focus
                  @kapa_array[i]['players'] << {
                    'display_name' => current_player_name,
                    'character' => current_player_character
                  }
                  puts current_kapa_ref.key
                  @nga_kapa_hash[current_kapa_snapshot.key].merge 
                  {
                    'display_name' => current_player_name,
                    'character' => current_player_character
                  }
                  puts "kapa_array: #{@kapa_array.inspect}".yellow
                  puts "nga_kapa_hash: #{@nga_kapa_hash.inspect}".yellow
                end
              end
            )
          else
            # We need to create a new one
            # THIS IS APPARENTLY WHERE WE MAKE NEW SERVER KAPA
            current_kapa_ref = @ref.child("kapa").childByAutoId
            current_kapa_ref.updateChildValues({ "created" => FIRServerValue.timestamp })
            current_kapa_ref.child('kaitakaro').updateChildValues({ "testing" => "value" })
            new_color = random_color_string
            current_kapa_ref.updateChildValues({ 'color' => new_color })
            @kapa_array << {
              "id" => current_kapa_ref.key,
              "players" => [],
              "coordinate" => {},
              'color' => new_color
            }
            @nga_kapa_hash[current_kapa_ref.key] = 
            {
              'players' => [],
              'coordinate' => {},
              'color' => new_color
            }
            puts "nga_kapa_hash: #{@nga_kapa_hash.inspect}".yellow
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
        App.notification_center.post "PlayerNew"
      end # player lambda
    )

    ##
    #
    # PLAYER EDITED
    # When the player is edited, chances are it's the location
    # And if it is, we need to re-check the kapa teams
    @ref.child("players").observeEventType(FIRDataEventTypeChildChanged,
      withBlock: proc do |player_snapshot|
        # TODO this adds an existing player, need to change!
        puts "Updated player: #{player_snapshot.value}" if DEBUGGING

        # Okay what is going on here
        # if the player _has_ a team, 
        # we add it to the kapa_array
        player_team = player_snapshot.childSnapshotForPath("team")
        if player_team.exists
          player_team_id = player_team.value
          # puts "player_team_id: #{player_team_id}"
          player_display_name = player_snapshot.childSnapshotForPath("display_name").value
          player_character = player_snapshot.childSnapshotForPath("character/title").value
          # puts "player_display_name: #{player_display_name}"

          kapa_in_array = @kapa_array.find { |k| k["id"] == player_team_id }

          # Here we check if the player is already in the kapa_array
          # and if not, we add it
          # and if so, we update with the character
          player_index = kapa_in_array['players'].index { |p| p['display_name']==player_display_name }
          if player_index.nil?
            puts "ADDING TO KAPA!!! #{player_display_name}".blue
            kapa_in_array["players"] << {
              'display_name' => player_display_name,
              'character' => player_character
            }
          else
            kapa_in_array['players'][player_index]['character'] = player_character
          end
          
          puts "Updated Kapa: #{@kapa_array}"

          # puts "takaro kapa_array: #{@kapa_array}".red
          App.notification_center.post 'PlayerChanged'
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

      # puts "new_location: #{new_location.coordinate.latitude}" if DEBUGGING
      # puts "old_location: #{old_location.coordinate.latitude}" if DEBUGGING

      App.notification_center.post("UpdateLocalPlayerPositionAsLocation",
        {"new_location" => new_location, "old_location" => old_location}
      )

      @local_player_locationCoords = new_location.coordinate
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
    
    @k_fbo = KaitakaroFbo.new(@ref.child("kaitakaro").childByAutoId, {'user_id' => in_user.uid})
  end

  
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
          { "coordinate" => { "latitude" => lats_average, "longitude" => longs_average }}
        )

        # update local kapa array
        @kapa_array.find { |k| k["id"] == kapa_ref.key }["coordinate"] = {
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
    puts 'TAKARO LIST_PLAYER_NAMES_FOR_INDEX'.blue if DEBUGGING
    puts "in_index: #{in_index}".red
    
    puts "Kapa array: #{@kapa_array[in_index]['players'].inspect}".red
    @kapa_array[in_index]['players']
  end

  ##
  # Returns player count for a given index.
  def player_count_for_index(in_index)
    puts 'TAKARO PLAYER_COUNT_FOR_INDEX'.blue if DEBUGGING
    # return 0 if @nga_kapa_hash.values[in_index].nil?
    # @nga_kapa_hash.values[in_index].count

    return 0 if @kapa_array.empty? || @kapa_array[in_index].empty? || @kapa_array[in_index]["players"].empty?
    @kapa_array[in_index]['players'].count
  end

  #################
  # Utility Functions
  #################

  def generate_new_id
    puts 'TAKARO GENERATE_NEW_ID'.blue if DEBUGGING
    # update the UI with the gamecode
    # https://gist.github.com/mbajur/2aba832a6df3fc31fe7a82d3109cb626
    rand(36**6).to_s(36)
  end
  
  def random_color_string
    "#{rand().round(2)} #{rand().round(2)} #{rand().round(2)} 1"
  end

  #################
  # Pouwhenua Stuff
  #################

  ##
  #
  # Takes the first two kapa's locations as the starting Pouwhenua.
  #
  def set_initial_pouwhenua
    puts 'TAKARO SET_INITIAL_POUWHENUA'.blue if DEBUGGING

    coord_array = []

    # TODO Could this be using the local info?
    puts "kapa_array for default pouwhenua: #{@kapa_array.inspect}".yellow
    puts "nga_kapa_hash for default pouwhenua: #{@nga_kapa_hash.inspect}".yellow
    @kapa_array.each do |k|
      # create remote instance
      # puts "Creating remote instance".focus
      # this uses the same local color for each!
      # TODO change to use the kapa colors
      create_new_pouwhenua(k['coordinate'], k['color'])

      # add to local coords
      coord_array << k['coordinate']
    end

    # use coords to calculate play area
    lats = coord_array.map {|c| c['latitude']}.minmax
    longs = coord_array.map {|c| c['longitude']}.minmax

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

    # Then send us to the game
    # TODO should this be here?
    Machine.instance.segue('ToGame')
  end

  def start_observing_pouwhenua
    puts 'TAKARO START_OBSERVING_POUWHENUA'.blue if DEBUGGING
    # puts "TAKARO START_OBSERVING_POUWHENUA".focus

    @ref.child('pouwhenua').observeEventType(FIRDataEventTypeChildAdded,
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
        puts "#{pouwhenua_array}".focus

        # Should we turn it into a better-formed hash here?
        App.notification_center.post('PouwhenuaNew', data)
    end)
  end

  def create_new_pouwhenua(coord = @local_player_locationCoords, color = @nga_kapa_hash[@local_kaitakaro.kapa_ref.key]['color'])
    puts 'TAKARO CREATE_NEW_POUWHENUA'.blue if DEBUGGING
    coord = Utilities::format_to_location_coord(coord)
    
    # we also need to get the color
    puts "local_kaitakaro: #{local_kaitakaro.inspect}".green
    puts "nga_kapa_hash: #{@nga_kapa_hash[@local_kaitakaro.kapa_ref.key]['color'].inspect}".green
    @ref.child('pouwhenua').childByAutoId.updateChildValues(
      {
        'created' => FIRServerValue.timestamp,
        'color' => color,
        'location' => { 'latitude' => coord.latitude, 'longitude' => coord.longitude },
        'title' => 'Baked Beans',
        'kapa' => @local_kaitakaro.kapa_ref.key,
        'lifespan' => @local_kaitakaro.character['lifespan_ms']
      },
      withCompletionBlock: lambda do | error, child_ref |
        # puts "CREATED REMOTE POUWHENUA".focus
      end
    )
  end

  # Return all the pouwhenua as coords
  # For the voronoi to calculate
  # TODO figure out a FIRDatabaseQuery for this
  def get_all_pouwhenua_coords
    puts 'TAKARO get_all_pouwhenua_coords'.blue if DEBUGGING
    @ref.child('pouwhenua').observeSingleEventOfType(FIRDataEventTypeValue, withBlock:
      lambda do |pouwhenua_snapshot|

      end
    )
  end

  #################
  # Bot Stuff
  #################

  def create_bot_player
    puts "TAKARO CREATE_BOT_PLAYER".blue if DEBUGGING

    # TODO this doesn't create a real player?
    @bot = Kaitarako.new(@ref.child('players').childByAutoId, { 'takaro' => self })
    @bot.display_name = "Bot McBotface #{rand(30)}"
    @bot.email = 'lucashaley@yahoo.com'
    @bot.character = {
      'deploy_time' => 4,
      'lifespan_ms' => 280000,
      'pouwhenua_start' => 3,
      'title' => 'Bot Character'
    }
    
    
    # Here we're going to use the team A coordinate as a starting point
    @ref.child('kapa').observeSingleEventOfType(FIRDataEventTypeValue , withBlock:
      lambda do |kapa_snapshot|
        # Make sure team A has a coordinate! Otherwise it's screwed. But this is a hack!
        puts "kapa_snapshot: #{kapa_snapshot.inspect}".yellow
        team_a_coordinate_snapshot = kapa_snapshot.children.nextObject.childSnapshotForPath('coordinate')
        puts "team_a_coordinate_snapshot: #{team_a_coordinate_snapshot.valueInExportFormat}".yellow
        
        # and then randomly move away from that point
        lat = team_a_coordinate_snapshot.valueInExportFormat['latitude'] + rand(-0.01..0.01)
        long = team_a_coordinate_snapshot.valueInExportFormat['longitude'] + rand(-0.01..0.01)
        @bot.coordinate = CLLocationCoordinate2DMake(lat, long)
        puts "Updated bot coordinate: #{CLLocationCoordinate2DMake(lat, long).inspect}".yellow
      end
    )
  end
end

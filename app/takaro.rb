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
                :taiapa, # the field, as MKRect
                :taiapa_center, # as MKMapPoint
                :taiapa_region, # as MKCoordinateRegion
                :pouwhenua,
                :pouwhenua_array

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
  #     }
  #   }
  # ]
  #
  # pouwhenua_array
  # [
  #   {
  #     "id" => id,
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
  def initialize(in_uuid = nil)
    puts "TAKARO INITIALIZE".light_blue if DEBUGGING
    puts "Creating new takaro with uuid: #{in_uuid}".pink if DEBUGGING
    @uuid = in_uuid || NSUUID.UUID.UUIDString
    @ref = Machine.instance.db.referenceWithPath("games/#{uuid}")

    # TODO do we do this if we're not creating from scratch? Won't it overwrite?
    # TODO yes it totally does
    new_gamecode = generate_new_id
    @ref.updateChildValues({"gamecode" => new_gamecode}, withCompletionBlock:
      lambda do | error, game_ref |
        App.notification_center.post("GamecodeNew", new_gamecode)
      end
    ) unless in_uuid

    puts "New takaro: #{@ref.URL}" if DEBUGGING

    # This is used for updating the UI
    # And needs to have 0 and 1 indecies
    # @nga_kapa_hash = {}
    @kapa_array = []
    @pouwhenua_array = []

    # what was I thinking here?
    # @nga_kapa_observer_handle_array = Array.new

    # setup_group = Dispatch::Group.new
    # setup_queue = Dispatch::Queue.new("turf")
    # other_queue = Dispatch::Queue.new("poop")
    # setup_queue.async(setup_group) {
    #   init_kapa
    # }
    # setup_group.notify(other_queue) {
    #   puts "BAAAAALLLLLLLLLLLLSSSSSSSSSS".focus
    # }


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

  def start_syncing
    puts "TAKARO START_SYNCING".blue if DEBUGGING
    # keep everything up to date
    @ref.keepSynced true
  end

  def stop_syncing
    puts "TAKARO STOP_SYNCING".blue if DEBUGGING
    @ref.keepSynced false
  end

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
              "coordinate" => {}
            }
            # and pull down the player names
            kapa_snapshot.ref.child("kaitakaro").getDataWithCompletionBlock(
              lambda do | error, player_snapshot |
                player_snapshot.children.each do |current_player_snapshot|
                  current_player_name = current_player_snapshot.childSnapshotForPath("display_name").value
                  # puts "current_player_name:#{current_player_name}".focus
                  @kapa_array[i]["players"] << current_player_name
                end
              end
            )
          else
            # We need to create a new one
            current_kapa_ref = @ref.child("kapa").childByAutoId
            current_kapa_ref.updateChildValues({"created" => FIRServerValue.timestamp})
            @kapa_array << {
              "id" => current_kapa_ref.key,
              "players" => [],
              "coordinate" => {}
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
          puts "player_team_id: #{player_team_id}"
          player_display_name = player_snapshot.childSnapshotForPath("display_name").value
          puts "player_display_name: #{player_display_name}"

          # puts "kapa_array (241): #{@kapa_array}".focus
          kapa_in_array = @kapa_array.find { |k| k["id"] == player_team_id }
          # puts "kapa_in_array: #{kapa_in_array}".focus

          unless kapa_in_array["players"].include?(player_display_name)
            kapa_in_array["players"] << player_display_name
          end

          puts "kapa_array: #{@kapa_array}"
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
  end

  # TODO This is not working -- maybe the kapa aren't made yet?
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
        puts "kapa_array: #{@kapa_array}".focus
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
    # return 0 if @nga_kapa_hash.values[in_index].nil?
    # @nga_kapa_hash.values[in_index].count

    return 0 if @kapa_array.empty? || @kapa_array[in_index].empty? || @kapa_array[in_index]["players"].empty?
    @kapa_array[in_index]["players"].count
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

    # TODO Could this be using the local info?
    @kapa_array.each do |k|
      # create local pouwhenua with coordinate
      p = Pouwhenua.new(k["coordinate"])

      # add to local pouwhenua array
      @pouwhenua_array << {
        "id" => p.uuid_string,
        "color" => p.color.stringRepresentation,
        "coordinate" => {
          "latitude" => p.location.latitude,
          "longitude" => p.location.longitude
        }
      }
      puts "pouwhenua_array: #{pouwhenua_array}".focus

      # add to local coords
      coord_array << k["coordinate"]
    end

    # use coords to calculate play area
    lats = coord_array.map {|c| c["latitude"]}.minmax
    longs = coord_array.map {|c| c["longitude"]}.minmax
    start_coord_hash = {"latitude" => lats[0], "longitude" => longs[0]}
    end_coord_hash = {"latitude" => lats[1], "longitude" => longs[1]}
    # puts "start_coord: #{start_coord_hash}".focus
    # puts "end_coord: #{end_coord_hash}".focus
    start_coord_array = [lats[0], longs[0]]
    end_coord_array = [lats[1], longs[1]]

    # start_coord = CLLocationCoordinate2DMake(lats[0], longs[0])
    # end_coord = CLLocationCoordinate2DMake(lats[1], longs[1])
    top_right_coord = CLLocation.alloc.initWithLatitude(lats[0], longitude: longs[0])
    bottom_right_coord = CLLocation.alloc.initWithLatitude(lats[0], longitude: longs[1])
    bottom_left_coord = CLLocation.alloc.initWithLatitude(lats[1], longitude: longs[1])

    # Get the midpoint
    midpoint_hash = {
      "latitude" => (start_coord_hash["latitude"] + end_coord_hash["latitude"]) * 0.5,
      "longitude" => (start_coord_hash["longitude"] + end_coord_hash["longitude"]) * 0.5
    }
    # puts "midpoint: #{midpoint_hash}".focus
    midpoint_array = [(lats[0]+lats[1])*0.5, (longs[0]+longs[1])*0.5]
    # midpoint_coord = CLLocationCoordinate2DMake(midpoint_array[0],midpoint_array[1])

    @taiapa_center = MKMapPointForCoordinate(CLLocationCoordinate2DMake(midpoint_array[0], midpoint_array[1]))
    # puts "\ntaiapa_center: #{@taiapa_center.x}, #{@taiapa_center.y}".focus

    test_point = CLLocationCoordinate2DMake(midpoint_array[0], midpoint_array[1]).to_cgpoint
    # puts "test_point: #{test_point.x}, #{test_point.y}".focus

    # Get the distance between the points
    distance = Utilities.get_distance(start_coord_hash, end_coord_hash)
    # puts "distance: #{distance}".focus

    # Grunt scaling
    # Start
    start_scaled = start_coord_array.each_with_index.map {| value, index | ((value-midpoint_array[index])*FIELD_SCALE)+midpoint_array[index] }
    end_scaled = end_coord_array.each_with_index.map {| value, index | ((value-midpoint_array[index])*FIELD_SCALE)+midpoint_array[index] }
    # puts "start_scaled: #{start_scaled}".focus
    # puts "end_scaled: #{end_scaled}".focus


    # Do we need this to be a MKCoordinateRegion?
    # MKCoordinateRegionMakeWithDistance?
    # MKCoordinateRegionMake
    # MKCoordinateRegionForMapRect
    @taiapa = MKMapRectMake(
      @taiapa_center.x,
      @taiapa_center.y,
      end_scaled[0]-start_scaled[0],
      end_scaled[1]-start_scaled[1]
    )
    puts "taiapa: #{taiapa.origin.x}:#{taiapa.origin.y}, #{taiapa.size.height}:#{taiapa.size.width}".focus

    # tried this, seems small?
    # @taiapa_region = MKCoordinateRegionForMapRect(@taiapa)
    # @taiapa_region = MKCoordinateRegionMake(
    #   CLLocationCoordinate2DMake(midpoint_array[0], midpoint_array[1]),
    #   MKCoordinateSpanMake(0.01, 0.01)
    # )

    @taiapa_region = MKCoordinateRegionForMapRect(@taiapa)
    puts "taiapa_region take 1: #{@taiapa_region.center.latitude}, #{@taiapa_region.center.longitude}; #{@taiapa_region.span.latitudeDelta}, #{@taiapa_region.span.longitudeDelta}".focus

    @taiapa_region = MKCoordinateRegionMakeWithDistance(
      CLLocationCoordinate2DMake(midpoint_array[0], midpoint_array[1]),
      top_right_coord.distanceFromLocation(bottom_right_coord) * FIELD_SCALE,
      bottom_right_coord.distanceFromLocation(bottom_left_coord) * FIELD_SCALE
    )
    puts "taiapa_region take 2: #{@taiapa_region.center.latitude}, #{@taiapa_region.center.longitude}; #{@taiapa_region.span.latitudeDelta}, #{@taiapa_region.span.longitudeDelta}".focus

    # Then send us to the game
    # TODO should this be here?
    Machine.instance.segue("ToGame")

    # # puts "kapa_array: #{@kapa_array}".focus
    # @ref.child("kapa").observeSingleEventOfType(FIRDataEventTypeValue, withBlock:
    #   lambda do |kapa_snapshot|
    #     # puts "kapa_snapshot: #{kapa_snapshot}".focus
    #
    #     kapa_snapshot.children.each do |k|
    #       coords = k.childSnapshotForPath("coordinate").value
    #       # puts "coords: #{coords}".focus
    #       p = create_new_pouwhenua(coords)
    #
    #       # add to local array
    #       pouwhenua_array << {
    #         "id" => p.uuid_string,
    #         "color" => p.color.stringRepresentation,
    #         "coordinate" => {
    #           "latitude" => p.location["latitude"],
    #           "longitude" => p.location["longitude"]
    #         }
    #       }
    #       puts "pouwhenua_array: #{pouwhenua_array}".focus
    #
    #       # Add coords for calculations
    #       coord_array << coords
    #     end
    #     cache_pouwhenua
    #
    #     # set the bounding box
    #     # could we just flip the coords?
    #     # puts "coord_array: #{coord_array}".focus
    #     lats = coord_array.map {|c| c["latitude"]}.minmax
    #     longs = coord_array.map {|c| c["longitude"]}.minmax
    #     start_coord_hash = {"latitude" => lats[0], "longitude" => longs[0]}
    #     end_coord_hash = {"latitude" => lats[1], "longitude" => longs[1]}
    #     # puts "start_coord: #{start_coord_hash}".focus
    #     # puts "end_coord: #{end_coord_hash}".focus
    #     start_coord_array = [lats[0], longs[0]]
    #     end_coord_array = [lats[1], longs[1]]
    #
    #     # Get the midpoint
    #     midpoint_hash = {
    #       "latitude" => (start_coord_hash["latitude"] + end_coord_hash["latitude"]) * 0.5,
    #       "longitude" => (start_coord_hash["longitude"] + end_coord_hash["longitude"]) * 0.5
    #     }
    #     # puts "midpoint: #{midpoint_hash}".focus
    #     midpoint_array = [(lats[0]+lats[1])*0.5, (longs[0]+longs[1])*0.5]
    #     @taiapa_center = MKMapPointForCoordinate(CLLocationCoordinate2DMake(midpoint_array[0], midpoint_array[1]))
    #
    #     # Get the distance between the points
    #     distance = Utilities.get_distance(start_coord_hash, end_coord_hash)
    #     # puts "distance: #{distance}".focus
    #
    #     # Grunt scaling
    #     # Start
    #     start_scaled = start_coord_array.each_with_index.map {| value, index | ((value-midpoint_array[index])*FIELD_SCALE)+midpoint_array[index] }
    #     end_scaled = end_coord_array.each_with_index.map {| value, index | ((value-midpoint_array[index])*FIELD_SCALE)+midpoint_array[index] }
    #     # puts "start_scaled: #{start_scaled}".focus
    #     # puts "end_scaled: #{end_scaled}".focus
    #
    #     @taiapa = MKMapRectMake(
    #       midpoint_array[0],
    #       midpoint_array[1],
    #       end_scaled[0]-start_scaled[0],
    #       end_scaled[1]-start_scaled[1]
    #     )
    #     puts "taiapa: #{taiapa}".focus
    #
    #     Machine.instance.bounding_box = CGRectMake(
    #       start_scaled[0],
    #       start_scaled[1],
    #       end_scaled[0]-start_scaled[0],
    #       end_scaled[1]-start_scaled[1]
    #     )
    #
    #   # create_new_pouwhenua(CLLocationCoordinate2DMake(coords["latitude"], coords["longitude"]))
    #   Machine.instance.segue("ToGame")
    # end
    # )
  end

  def start_observing_pouwhenua
    puts "TAKARO START_OBSERVING_POUWHENUA".blue if DEBUGGING

    @ref.child("pouwhenua").observeEventType(FIRDataEventTypeChildAdded,
      withBlock: proc do |data|
        # Should we turn it into a better-formed hash here?
        App.notification_center.post("PouwhenuaNew", data)
    end)
  end

  def create_new_pouwhenua(coord = @local_player_locationCoords)
    puts "TAKARO CREATE_NEW_POUWHENUA".blue if DEBUGGING
    # TODO restructure Pouwhenua
    new_pouwhenua = Pouwhenua.new(coord)
    puts "#{new_pouwhenua.uuid_string}".focus
    # puts "New pouwhenua: #{new_pouwhenua.uuid_string}".focus
    @ref.child("pouwhenua/#{new_pouwhenua.uuid_string}").setValue(new_pouwhenua.to_hash)
    return new_pouwhenua
  end

  ##
  # Return all of the current pouwhenua
  # def cache_pouwhenua()
  #   @ref.child("pouwhenua").observeSingleEventOfType(FIRDataEventTypeValue, withBlock:
  #     lambda do |pouwhenua_snapshot|
  #       puts "pouwhenua: #{pouwhenua}".focus
  #       @pouwhenua = pouwhenua_snapshot.children.value.values
  #     end
  #   )
  # end

  # Return all the pouwhenua as coords
  # For the voronoi to calculate
  # TODO figure out a FIRDatabaseQuery for this
  def get_all_pouwhenua_coords
    puts "TAKARO get_all_pouwhenua_coords".blue if DEBUGGING
    @ref.child("pouwhenua").observeSingleEventOfType(FIRDataEventTypeValue, withBlock:
      lambda do |pouwhenua_snapshot|

      end
    )
  end

  #################
  # Bot Stuff
  #################

  def create_bot_player
    puts "TAKARO CREATE_BOT_PLAYER".blue if DEBUGGING
    @bot = Kaitarako.new(@ref.child("players").childByAutoId, { "takaro" => self })
    @bot.display_name = "Bot McBotface #{rand(30)}"
    @bot.email = "lucashaley@yahoo.com"
    lat = rand(37.330144370126..37.330144370127)
    long = -rand(122.059911595149..122.059911595150)
    # puts "#{lat}, #{long}".focus
    # @bot.coordinate = CLLocationCoordinate2DMake(37.33014437012663, -122.05991159514932)
    @bot.coordinate = CLLocationCoordinate2DMake(lat, long)
  end
end

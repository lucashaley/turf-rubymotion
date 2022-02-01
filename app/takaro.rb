class Takaro
  attr_accessor :ref,
                :uuid,
                :local_player_ref,
                # :nga_kapa,
                :nga_kapa_hash,
                :machine,
                :kapa_observer_handle,
                :nga_kapa_observer_handle_array,
                :player_observer_handle,
                :local_player_locationCoords,
                :local_player_name,
                :local_player_kapa_ref

  DEBUGGING = true
  TEAM_DISTANCE = 3
  MOVE_THRESHOLD = 2
  TEAM_COUNT = 2

  @accepting_new_players = true

  ##
  # Creates a new Takaro, or initializes from a +in_uuid+ string.
  # uuid is a string.

  def initialize(in_uuid = NSUUID.UUID.UUIDString)
    puts "TAKARO INITIALIZE".light_blue if DEBUGGING
    puts in_uuid
    @uuid = in_uuid
    @ref = Machine.instance.db.referenceWithPath("games/#{uuid}")

    # TODO do we do this if we're not creating from scratch? Won't it overwrite?
    new_gamecode = generate_new_id
    @ref.updateChildValues({"gamecode" => new_gamecode}, withCompletionBlock:
      lambda do | error, game_ref |
        App.notification_center.post("GamecodeNew", new_gamecode)
      end
    )

    puts "New takaro: #{@ref.URL}" if DEBUGGING

    # TODO add empty kapa
    # TODO do we still need the array?
    # @nga_kapa = Array.new

    # This is used for updating the UI
    # And needs to have 0 and 1 indecies
    @nga_kapa_hash = {}
    @nga_kapa_observer_handle_array = Array.new

    # This is only good for the creating player
    # @nga_kapa_objects = []
    # TEAM_COUNT.times { |i| @nga_kapa_objects << Kapa.new(@ref.child("kapa").childByAutoId, {"name" => "Team_#{i}", "color" => "1 0 1 0"}) }
    # puts @nga_kapa_objects

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
  def init_kapa
    puts "TAKARO INIT_KAPA".blue if DEBUGGING

    # Check first for server kapa
    @ref.child("kapa").getDataWithCompletionBlock(
      lambda do | error, kapa_snapshot |

        childCount = kapa_snapshot.hasChildren || 0
        puts "childCount: #{childCount}".focus
        TEAM_COUNT.times do |i|
          if childCount > i
            # There is already one on the server
            # get its data and add it to the local hash
            current_kapa_snapshot = kapa_snapshot.children.allObjects[i]
            current_kapa_ref = current_kapa_snapshot.ref
            # and pull down the player names
            kapa_snapshot.ref.child("kaitakaro").getDataWithCompletionBlock(
              lambda do | error, player_snapshot |
                player_snapshot.children.each do |current_player_snapshot|
                  @setup_queue.async(@setup_group) do
                    current_player_name = current_player_snapshot.childSnapshotForPath("name").value
                    @nga_kapa_hash[i] << current_player_name
                  end # async
                end
              end
            )
          else
            # We need to create a new one
            current_kapa_ref = @ref.child("kapa").childByAutoId
            current_kapa_ref.updateChildValues({"created" => FIRServerValue.timestamp})
          end
          puts "current_kapa_ref: #{current_kapa_ref.URL}".focus

          # then we need to add the observers
          current_kapa_ref.child("kaitakaro").observeEventType(FIRDataEventTypeChildAdded,
            withBlock: lambda do |kaitakaro_snapshot|
              puts "TAKARO INIT_KAPA KAITAKARO CHILD ADDED".focus
              puts "Info: #{kaitakaro_snapshot.value}"
              puts "kapa_snapshot: #{kapa_snapshot.ref.URL}"
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

    # Oh noes
    # I think this needs to be all local
    @ref.child("players").queryLimitedToLast(1).observeEventType(FIRDataEventTypeChildAdded,
      withBlock: proc do |player_snapshot|
        puts "TAKARO PLAYERADDED".red if DEBUGGING

        # Let's take a look at who the player is
        puts "new player: #{player_snapshot.value}" if DEBUGGING
      end # player lambda
    ) # player observer

    @ref.child("players").observeEventType(FIRDataEventTypeChildChanged,
      withBlock: proc do |player_snapshot|
        # TODO this adds an existing player, need to change!
        puts "Updated player: #{player_snapshot.value}" if DEBUGGING

        # Okay what is going on here
        # if the player _has_ a team, we need to check if they are already in the team
        player_team = player_snapshot.childSnapshotForPath("team")
        if player_team.exists
          player_team_value = player_team.value

          puts "adding player name to hash: #{player_team_value}" if DEBUGGING
          player_display_name = player_snapshot.childSnapshotForPath("display_name").value
          # TODO whew this can be shorter
          # TODO maybe this could be a hash instead, using the object id?
          unless @nga_kapa_hash[player_team_value].include?(player_display_name)
            @nga_kapa_hash[player_team_value] << player_display_name
          end
          puts "#{nga_kapa_hash}" if DEBUGGING
          App.notification_center.post "PlayerNew"
        end
      end
    )

    @takaro_update_location_observer_coord = App.notification_center.observe "UpdateLocation" do |data|
      puts "TAKARO UPDATELOCALPLAYERPOSITION LOCATION".yellow if DEBUGGING

      new_location = data.object["new_location"]
      old_location = data.object["old_location"]

      puts "new_location: #{new_location.coordinate.latitude}"
      puts "old_location: #{old_location.coordinate.latitude}"

      App.notification_center.post("UpdateLocalPlayerPositionAsLocation",
        {"new_location" => new_location, "old_location" => old_location}
      )
    end

    puts @machine.current_state.name
    @machine.event :go_to_awaiting_players
    puts "Transitioning out".focus
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

  # This  is not working -- maybe the kapa  aren;t made yet?
  def update_kapa_location(kapa_ref)
    puts "TAKARO UPDATE_KAPA_LOCATION".blue if DEBUGGING
    loc = CLLocationCoordinate2DMake(0, 0)

    puts "kapa_ref: #{kapa_ref.URL}"

    kapa_ref.child("kaitakaro").observeSingleEventOfType(FIRDataEventTypeValue , withBlock:
      lambda do |kapa_snapshot|
        lats = []
        longs = []
        puts "observe version: #{kapa_snapshot.value}"

        # TODO This is an errorgith
        kapa_snapshot.children.each do |pl|
          pl_loc = pl.childSnapshotForPath("location").value
          # puts pl_loc["latitude"].to_s
          # puts pl_loc["longitude"].to_s
          lats << pl_loc["latitude"]
          longs << pl_loc["longitude"]
        end
        lats_average = lats.inject{ |sum, el| sum + el }.to_f / lats.size
        longs_average = longs.inject{ |sum, el| sum + el }.to_f / longs.size
        kapa_ref.updateChildValues(
          {"location" => {"latitude" => lats_average, "longitude" => longs_average}}
        )
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
    @nga_kapa_hash.values[in_index]
  end

  ##
  # Returns player count for a given index.
  def player_count_for_index(in_index)
    puts "TAKARO PLAYER_COUNT_FOR_INDEX".blue if DEBUGGING
    return 0 if @nga_kapa_hash.values[in_index].nil?
    @nga_kapa_hash.values[in_index].count
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

  def set_initial_pouwhenua
    puts "TAKARO SET_INITIAL_POUWHENUA".blue if DEBUGGING
    @nga_kapa_hash.each do |k|
      puts "Current Kapa: #{k}"
    end
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
    new_pouwhenua = Pouwhenua.new(coord)
    puts new_pouwhenua.uuid_string if DEBUGGING
    @ref.child("pouwhenua/#{new_pouwhenua.uuid_string}").setValue(new_pouwhenua.to_hash)
  end

  #################
  # Bot Stuff
  #################

  def create_bot_player
    puts "TAKARO CREATE_BOT_PLAYER".focus if DEBUGGING
    @bot = Kaitarako.new(@ref.child("players").childByAutoId, { "takaro" => self })
    @bot.display_name = "Bot McBotface"
    @bot.email = "lucashaley@yahoo.com"
    @bot.coordinate = CLLocationCoordinate2DMake(37.33014437012663, -122.05991159514932)
  end
end

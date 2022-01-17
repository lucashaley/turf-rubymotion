class Takaro
  attr_accessor :ref,
                :uuid,
                :local_player_ref,
                :nga_kapa,
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

  # uuid is a string.
  def initialize(in_uuid = NSUUID.UUID.UUIDString)
    puts "TAKARO INITIALIZE".light_blue if DEBUGGING
    puts in_uuid
    @uuid = in_uuid
    @ref = Machine.instance.db.referenceWithPath("games/#{uuid}")
    # @ref = Machine.instance.db.referenceWithPath("games").childByAutoId
    new_gamecode = generate_new_id
    @ref.updateChildValues({"gamecode" => new_gamecode}, withCompletionBlock:
      lambda do | error, game_ref |
        App.notification_center.post("GamecodeNew", new_gamecode)
      end
    )
    puts "New takaro: #{@ref.URL}"

    # TODO add empty kapa
    @nga_kapa = Array.new
    # @nga_kapa << Array.new
    # @nga_kapa << Array.new
    # trying out hash instead of array
    @nga_kapa_hash = {}
    @nga_kapa_observer_handle_array = Array.new

    @machine = StateMachine::Base.new start_state: :start, verbose: DEBUGGING
    @machine.when :start do |state|
      state.on_entry { puts "Takaro state start".pink }

      state.transition_to :pull_remote_kapa,
        on: :go_to_pull_remote_kapa
    end
    @machine.when :pull_remote_kapa do |state|
      state.on_entry { pull_remote_kapa }
      state.transition_to :set_up_observers,
        on: :go_to_set_up_observers
    end
    @machine.when :set_up_observers do |state|
      state.on_entry { set_up_observers }
      state.transition_to :clean_up,
        on: :go_to_clean_up
    end
    @machine.when :clean_up do |state|
      state.on_entry { puts "Takaro clean_up".pink }
    end
    @machine.start!
    @machine.event :go_to_pull_remote_kapa

    # This is a force to get the most recent
    # TODO figure out if we can comment out
    # @ref.getDataWithCompletionBlock(
    #   proc do | error, snapshot |
    #     puts "Snapshot: #{snapshot}"
    #
    #     # pre-populate existing kapa?
    #     snapshot.childSnapshotForPath("kapa").children.each do |k|
    #       puts "k: #{k.ref.URL}"
    #       puts @nga_kapa
    #       k.childSnapshotForPath("kaitakaro").children.each do |p|
    #         @nga_kapa[k.childSnapshotForPath("index").value] << p.value
    #       end
    #     end
    #   end
    # )

    puts "Going Online!"
    FIRDatabaseReference.goOnline

    add_local_player

    self
  end

  def start_syncing
    puts "TAKARO START_SYNCING".blue if DEBUGGING
    # keep everything up to date
    @ref.keepSynced true
  end

  def stop_syncing
    puts "TAKARO STOP_SYNCING".blue if DEBUGGING
    @ref.keepSynced false
  end

  # Possibly rename this to set up or something?
  def pull_remote_kapa
    # This needs to happen for joining games?
    puts "TAKARO PULL_REMOTE_KAPA".blue if DEBUGGING

    # check if there are any kapa still left to make
    # and initialize them if not
    @ref.child("kapa").getDataWithCompletionBlock(
      lambda do | error, kapa_snapshot|
        puts "\nCurrent kapa count: #{kapa_snapshot.childrenCount}\n".pink
        (TEAM_COUNT - kapa_snapshot.childrenCount).times do |i|
          kapa_snapshot.ref.childByAutoId.setValue(
            {"created" => FIRServerValue.timestamp}
          )
        end
        kapa_snapshot.children.each do |kapa|
          puts "\npull_remote_kapa: #{kapa.value}\n".pink if DEBUGGING
        end unless kapa_snapshot.nil?
        @machine.event :go_to_set_up_observers
      end
    )
  end

  def set_up_observers
    puts "TAKARO SET_UP_OBSERVERS".blue if DEBUGGING

    @ref.child("kapa").observeEventType(FIRDataEventTypeChildAdded,
      withBlock: proc do |kapa_snapshot|
        puts "\nTAKARO KAPA ADDED".red if DEBUGGING
        puts "Kapa added: #{kapa_snapshot.ref.URL}" if DEBUGGING

        # Hash version
        unless @nga_kapa_hash.length >= 2
          # add new array to kapa hash
          # TODO change this to a set?
          @nga_kapa_hash[kapa_snapshot.key] = []
          # add a new kapa to the hash array?
          puts "new kapa loop hash: #{@nga_kapa_hash.to_s}" if DEBUGGING
        end
      end
    )

    @ref.child("kapa").observeEventType(FIRDataEventTypeChildChanged,
      withBlock: proc do |kapa_snapshot|
        puts "\nTAKARO KAPA CHANGED".red if DEBUGGING
        puts "#{kapa_snapshot.ref.URL}" if DEBUGGING
        if kapa_snapshot.childSnapshotForPath("location").exists
          update_kapa_location(kapa_snapshot.ref)
        end
      end
    )

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

    @takaro_update_location_observer = App.notification_center.observe "UpdateLocalPlayerPosition" do |data|
      puts "TAKARO UPDATELOCALPLAYERPOSITION".blue if DEBUGGING

      update_local_player_location({
        "latitude" => data.object["latitude"],
        "longitude" => data.object["longitude"]
      })
    end
    @takaro_update_location_observer_coord = App.notification_center.observe "UpdateLocalPlayerPositionAsLocation" do |data|
      puts "TAKARO UPDATELOCALPLAYERPOSITION LOCATION".yellow if DEBUGGING

      new_location = data.object["new_location"]
      old_location = data.object["old_location"]

      # puts "new_location: #{new_location.coordinate}"
      # puts "old_location: #{old_location.coordinate}"

      if @local_player_locationCoords.nil? || new_location.distanceFromLocation(old_location) > MOVE_THRESHOLD
        update_local_player_location({
          "latitude" => new_location.coordinate.latitude,
          "longitude" => new_location.coordinate.longitude
        })
      end
    end
    @machine.event :go_to_clean_up
  end

  # this expects a hash
  def update_local_player_location(in_location)
    puts "TAKARO UPDATE_LOCAL_PLAYER_LOCATION".blue if DEBUGGING
    # update the local version
    @local_player_locationCoords = CLLocationCoordinate2DMake(in_location["latitude"], in_location["longitude"])
    puts "local_player_locationCoords: #{@local_player_locationCoords}"

    # update server version
    player_kapa_ref = nil
    @local_player_ref.updateChildValues(
      {"location" => {
        "latitude" => in_location["latitude"],
        "longitude" => in_location["longitude"]
      }}, withCompletionBlock:
      lambda do | error, player_ref |
        observing_local_player_position = true

        @ref.child("kapa").getDataWithCompletionBlock(
          lambda do | error, kapa_snapshot |
            puts "TAKARO UPDATE_LOCAL_PLAYER_LOCATION CHECKING MOVE".blue if DEBUGGING
            puts "local player kapa ref: #{@local_player_kapa_ref}"


            puts "TAKARO UPDATE_LOCAL_PLAYER_LOCATION ITERATING".blue if DEBUGGING
            # iterate through the existing kapa
            kapa_snapshot.children.each do |k|
              # check if kapa has a location already
              unless k.childSnapshotForPath("location").exists
                @local_player_kapa_ref ||= k.ref
              end
              # and check if we're close enough
              if k.childSnapshotForPath("location").exists && get_distance(@local_player_locationCoords, k.childSnapshotForPath("location").value) < TEAM_DISTANCE
                puts "Close enough!".yellow
                @local_player_kapa_ref ||= k.ref
              end # if get distance
            end unless kapa_snapshot.childrenCount == 0

            # if we are prepopulating the kapa, we should never get here
            if @local_player_kapa_ref.nil?
              # if we get here, the player hasn't matched a kapa
              puts "TAKARO UPDATE_LOCAL_PLAYER_LOCATION NO KAPA FOUND".blue if DEBUGGING
              # if there are less than two kapa, make a new one
              if kapa_snapshot.childrenCount < 2
                puts "TAKARO UPDATE_LOCAL_PLAYER_LOCATION CREATING NEW KAPA".blue if DEBUGGING
                @local_player_kapa_ref = kapa_snapshot.ref.childByAutoId
              else
                # otherwise the player is too far from everyone
                puts "TOO FAR FROM EVERYONE!!!".pink
              end
            end

            # TODO we need to check if they already have a kapa
            # send the data up
            puts "TAKARO UPDATE_LOCAL_PLAYER_LOCATION SENDING DATA".blue if DEBUGGING
            @local_player_kapa_ref.child("kaitakaro/#{@local_player_ref.key}").updateChildValues(
              {"name" => @local_player_name, "location" => {
                "latitude" => in_location["latitude"],
                "longitude" => in_location["longitude"]}
              }, withCompletionBlock:
              lambda do | error, player_ref |
                puts "TAKARO UPDATE_LOCAL_PLAYER_LOCATION SETTING KAPA".blue if DEBUGGING
                puts "TAKARO UPDATE_LOCAL_PLAYER_LOCATION kapa_ref: #{@local_player_kapa_ref.URL}"
                update_kapa_location(@local_player_kapa_ref)

                # update the player record
                @local_player_ref.updateChildValues(
                  {"team" => @local_player_kapa_ref.key}
                )
                # update the local kapa hash?
              end
            )
          end
        )
      end
    )
  end

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
    @local_player_name = in_user.displayName
    # first get a new ref for the player
    @local_player_ref = @ref.child("players").childByAutoId

    # then set it's variables
    # we should be able to get the location
    @local_player_ref.updateChildValues(
      {"user_id" => in_user.uid,
        "display_name" => in_user.displayName,
        "email" => in_user.email}
    )

    puts "local_player_ref: #{@local_player_ref}"
    return @local_player_ref
  end

  # hash version
  # Not sure if this is used
  def add_player_to_kapa_ref(player_snapshot, kapa_ref)
    puts "TAKARO ADD_PLAYER_TO_KAPA_REF".blue if DEBUGGING
    puts "Adding #{player_snapshot.childSnapshotForPath("display_name").value} to #{kapa_ref.URL}"
    kapa_ref.child("kaitakaro").updateChildValues({
      player_snapshot.key => player_snapshot.childSnapshotForPath("display_name").value},
      withCompletionBlock: proc do | error, ref |
        # add the team uuid to the player
        player_snapshot.ref.updateChildValues({"team" => kapa_ref.key}, withCompletionBlock:
          lambda do | error, player_ref |
            # update the average location in the kapa
            puts "Trying to update location"
            update_kapa_location(kapa_ref)
          end
        )

        # add the player name to the local kapa hash
        @nga_kapa_hash[kapa_ref.key] << player_snapshot.childSnapshotForPath("display_name").value
        App.notification_center.post("KapaNew", kapa_ref)
      end
    )
  end

  # array version
  # Not sure this is used
  def add_player_to_kapa_ref_with_index(player_snapshot, kapa_ref, index)
    puts "TAKARO ADD_PLAYER_TO_KAPA".blue if DEBUGGING
    puts "Adding #{player_snapshot.childSnapshotForPath("display_name").value} to #{kapa_ref.URL} at index: #{index}"
    kapa_ref.child("kaitakaro").updateChildValues({
      player_snapshot.key => player_snapshot.childSnapshotForPath("display_name").value},
      withCompletionBlock: proc do | error, ref |
        player_snapshot.ref.updateChildValues({"team" => kapa_ref.key}, withCompletionBlock:
          lambda do | error, player_ref |
            update_kapa_location(kapa_ref)
          end
        )

        # add the player to the local hash
        @nga_kapa[index] << player_snapshot.childSnapshotForPath("display_name").value

        # let the UI know to refresh
        App.notification_center.post("KapaNew", kapa_ref)
      end
    )
  end

  # This  is not working -- maybe the kapa  aren;t made yet?
  def update_kapa_location(kapa_ref)
    puts "TAKARO UPDATE_KAPA_LOCATION".blue if DEBUGGING
    loc = CLLocationCoordinate2DMake(0, 0)

    kapa_ref.child("kaitakaro").observeSingleEventOfType(FIRDataEventTypeValue , withBlock:
      lambda do |k_s|
        lats = []
        longs = []
        puts "observe version: #{k_s.value}"
        k_s.children.each do |pl|
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

  def list_player_names
    puts "TAKARO LIST_PLAYER_NAMES".blue if DEBUGGING
    @ref.child("kapa").getDataWithCompletionBlock(
      # Using a lambda allows us to return?!?
      lambda do | error, kapa_snapshot |
        puts kapa_snapshot.childrenCount
        kapa_hash = kapa_snapshot.value
        # puts "kapa_hash: #{kapa_hash}"
        puts kapa_snapshot.children.each { |c| puts "\nc: #{c.value}" }
        # player_names = player_hash.map { |k| k.last["display_name"] }
        # puts player_names
        # return player_names
      end
    )
  end

  def list_player_names_for_kapa_ref(kapa_ref)
    puts "TAKARO LIST_PLAYER_NAMES_FOR_KAPA_REF".blue if DEBUGGING
    puts "TAKARO LIST_PLAYER_NAMES_FOR_KAPA_REF kapa_ref: #{kapa_ref.key}".yellow if DEBUGGING
    @ref.child("players").queryOrderedByChild("team").queryEqualToValue(kapa_ref.key).getDataWithCompletionBlock(
      # Using a lambda allows us to return?!?
      lambda do | error, player_snapshot |
        player_hash = player_snapshot.value
        player_names = player_hash.map { |k| k.last["display_name"] }
        puts player_names
        return player_names
      end
    )
  end

  def list_player_names_for_index(in_index)
    puts "TAKARO LIST_PLAYER_NAMES_FOR_INDEX".blue if DEBUGGING
    # index_query = @ref.child("kapa").queryOrderedByChild("index").queryEqualToValue(in_index)

    #  array version
    # @nga_kapa[in_index]

    # hash version
    @nga_kapa_hash.values[in_index]
  end

  def player_count_for_index(in_index)
    puts "TAKARO PLAYER_COUNT_FOR_INDEX".blue if DEBUGGING
    # array version
    # return 0 if @nga_kapa[in_index].nil?
    # @nga_kapa[in_index].count

    # hash version
    return 0 if @nga_kapa_hash.values[in_index].nil?
    @nga_kapa_hash.values[in_index].count
  end

  def get_distance(coord_a, coord_b)
    puts "TAKARO GET_DISTANCE".blue if DEBUGGING
    distance = MKMetersBetweenMapPoints(
      MKMapPointForCoordinate(
        format_to_location_coord(coord_a)),
      MKMapPointForCoordinate(
        format_to_location_coord(coord_b))
    )
    puts distance
    distance
  end

  def format_to_location_coord(input)
    puts "TAKARO FORMAT_TO_LOCATION_COORD".blue if DEBUGGING
    puts "Input: #{input}".red if DEBUGGING
    case input
    when Hash
      return CLLocationCoordinate2DMake(input["latitude"], input["longitude"])
    when CLLocationCoordinate2D
      return input
    end
    0
  end

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
    @ref.child("players").childByAutoId.updateChildValues(
      {
        "display_name" => "Test Bot", "email" => "test@test.com"
      },
      withCompletionBlock:
        lambda do | error, p |
          p.updateChildValues({
            "location" =>
            {
              "latitude" => 37.32889895124122,
              "longitude" => -122.03668383752265
            }
          })
        end
    )
  end
end

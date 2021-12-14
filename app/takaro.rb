class Takaro
  attr_accessor :ref,
                :uuid,
                :local_player_ref,
                :nga_kapa,
                :machine,
                :kapa_observer_handle,
                :nga_kapa_observer_handle_array,
                :player_observer_handle

  DEBUGGING = true
  TEAM_DISTANCE = 5

  @accepting_new_players = true

  # I don't really want to hard-code the team indecies here.
  # I expect I'll only ever have two teams, but still.

  # uuid is a string.
  def initialize(in_uuid = NSUUID.UUID.UUIDString)
    puts "TAKARO INITIALIZE".light_blue if DEBUGGING
    puts in_uuid
    @uuid = in_uuid
    @ref = Machine.instance.db.referenceWithPath("games/#{uuid}")
    # @ref = Machine.instance.db.referenceWithPath("games").childByAutoId
    puts "New takaro: #{@ref.URL}"

    # TODO add empty kapa
    @nga_kapa = Array.new
    # @nga_kapa << Array.new
    # @nga_kapa << Array.new
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

    # # TODO We need to check here if there are existing kapa!
    # @ref.child("kapa").childByAutoId.updateChildValues({index: 0}, withCompletionBlock:
    #   lambda do | error, child_ref |
    #     @ref.child("kapa").childByAutoId.updateChildValues({index: 1})
    #   end
    # )
    create_new_remote_kapa

    # This is a force to get the most recent
    # TODO figure out if we can comment out
    @ref.getDataWithCompletionBlock(
      proc do | error, snapshot |
        puts "Snapshot: #{snapshot}"

        # pre-populate existing kapa?
        snapshot.childSnapshotForPath("kapa").children.each do |k|
          puts "k: #{k.ref.URL}"
          puts @nga_kapa
          k.childSnapshotForPath("kaitakaro").children.each do |p|
            @nga_kapa[k.childSnapshotForPath("index").value] << p.value
          end
        end
      end
    )

    puts "Going Online!"
    FIRDatabaseReference.goOnline

    # @ref.child("kapa").observeEventType(FIRDataEventTypeChildAdded,
    #   withBlock: proc do |kapa_snapshot|
    #     puts "TAKARO KAPAADDED".red if DEBUGGING
    #   end
    # )
    #
    # @ref.child("players").queryLimitedToLast(1).observeEventType(FIRDataEventTypeChildAdded,
    #   withBlock: proc do |player_snapshot|
    #     puts "TAKARO PLAYERADDED".red if DEBUGGING
    #
    #     # Determine if there is a base team
    #     # puts player_snapshot.key
    #     # player_snapshot.children.each do |child|
    #     #   puts child.key
    #     # end
    #
    #     @ref.child("kapa").queryOrderedByChild("index").getDataWithCompletionBlock(
    #       lambda do | error, kapa_snapshot |
    #         puts "Exists: #{kapa_snapshot.exists}"
    #
    #       # Iterate through all the kapa
    #         kapa_snapshot.children.each do |k|
    #           index = k.childSnapshotForPath('index').value
    #           puts "kapa index: #{index}"
    #       # Check if the kapa has a location
    #           unless k.childSnapshotForPath("location").exists
    #       # If not, use this one
    #             add_player_to_kapa_ref(player_snapshot, k.ref, index)
    #             break
    #           else
    #       # If the player is close enough use this one
    #             if get_distance(
    #               player_snapshot.childSnapshotForPath("location").value,
    #               k.childSnapshotForPath("location").value
    #             ) < TEAM_DISTANCE
    #       # Add the player
    #               add_player_to_kapa_ref(player_snapshot, k.ref, index)
    #               break
    #             else
    #               # If no matches, tell them to move
    #               puts "NOT CLOSE ENOUGH".pink if DEBUGGING
    #             end
    #           end
    #         end
    #         puts "FINISHED NEW VERSION".pink if DEBUGGING
    #       end
    #     )
    #   end
    # )
    #
    # @takaro_update_location_observer = App.notification_center.observe "UpdateLocalPlayerPosition" do |data|
    #   puts "TAKARO UPDATELOCALPLAYERPOSITION".yellow if DEBUGGING
    #   @local_player_ref.updateChildValues(
    #     "location" => {
    #       "latitude" => data.object["latitude"],
    #       "longitude" => data.object["longitude"]
    #     }
    #   )
    # end

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

  def pull_remote_kapa
    puts "TAKARO PULL_REMOTE_KAPA".blue if DEBUGGING
    @ref.child("kapa").queryOrderedByChild("index").getDataWithCompletionBlock(
      lambda do | error, kapa_snapshot |
        # Iterate through each kapa, and pull the player names
        kapa_snapshot.children.each do |kapa|
          puts "\npull_remote_kapa: #{kapa.value}\n".pink
        end unless kapa_snapshot.nil?
        @machine.event :go_to_set_up_observers
      end
    )
  end

  def set_up_observers
    puts "TAKARO SET_UP_OBSERVERS".blue if DEBUGGING
    observing_kapa = false
    observing_players = false
    observing_local_player_position = false

    @ref.child("kapa").observeEventType(FIRDataEventTypeChildAdded,
      withBlock: proc do |kapa_snapshot|
        puts "\nTAKARO KAPAADDED".red if DEBUGGING
        puts "#{kapa_snapshot.ref.URL}"

        unless @nga_kapa.length >= 2
          @nga_kapa << Array.new
          @nga_kapa_observer_handle_array << kapa_snapshot.ref.observeEventType(
            FIRDataEventTypeChildAdded,
            withBlock: proc do |new_snapshot|
              # puts "New thingy for #{new_snapshot.key}: #{new_snapshot.value}".yellow
              # puts new_snapshot.class
              # puts new_snapshot.value.class
              # puts new_snapshot.value.first.class unless new_snapshot.key == "index"
              new_snapshot.value.each do | k, v |
                puts "k: #{k}; v: #{v}"
                @nga_kapa.last << v
                puts @nga_kapa
              end unless new_snapshot.key == "index"
            end
          )
        end

        observing_kapa = true
      end
    )

    @ref.child("players").queryLimitedToLast(1).observeEventType(FIRDataEventTypeChildAdded,
      withBlock: proc do |player_snapshot|
        puts "TAKARO PLAYERADDED".red if DEBUGGING

        @ref.child("kapa").queryOrderedByChild("index").getDataWithCompletionBlock(
          lambda do | error, kapa_snapshot |
            puts "Exists: #{kapa_snapshot.exists}"

          # Iterate through all the kapa
            kapa_snapshot.children.each do |k|
              index = k.childSnapshotForPath('index').value
              puts "kapa index: #{index}"
          # Check if the kapa has a location
              unless k.childSnapshotForPath("location").exists
          # If not, use this one
                add_player_to_kapa_ref(player_snapshot, k.ref, index)
                break
              else
          # If the player is close enough use this one
                if get_distance(
                  player_snapshot.childSnapshotForPath("location").value,
                  k.childSnapshotForPath("location").value
                ) < TEAM_DISTANCE
          # Add the player
                  add_player_to_kapa_ref(player_snapshot, k.ref, index)
                  break
                else
                  # If no matches, tell them to move
                  puts "NOT CLOSE ENOUGH".pink if DEBUGGING
                end
              end
              observing_players = true
            end
            puts "FINISHED NEW VERSION".pink if DEBUGGING
          end
        )
      end
    )

    @takaro_update_location_observer = App.notification_center.observe "UpdateLocalPlayerPosition" do |data|
      puts "TAKARO UPDATELOCALPLAYERPOSITION".yellow if DEBUGGING
      @local_player_ref.updateChildValues(
        {"location" => {
          "latitude" => data.object["latitude"],
          "longitude" => data.object["longitude"]
        }}, withCompletionBlock:
          lambda do | error, player_ref |
            observing_local_player_position = true
          end
      )
    end

    # until observing_kapa && observing_players && observing_local_player_position
    #   puts "waiting"
    # end

    @machine.event :go_to_clean_up
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

  def add_local_player(in_user = Machine.instance.user)
    puts "TAKARO ADD_LOCAL_PLAYER".blue if DEBUGGING
    # @local_player_ref = @ref.child("players/#{NSUUID.UUID.UUIDString}")
    @local_player_ref = @ref.child("players").childByAutoId
    @local_player_ref.updateChildValues(
      {"user_id" => in_user.uid,
        "display_name" => in_user.displayName,
        "email" => in_user.email}
    )
    puts "local_player_ref: #{@local_player_ref}"
    return @local_player_ref
  end

  def update_local_player_location(in_location)

  end

  def add_player_to_kapa_ref(player_snapshot, kapa_ref, index)
    puts "TAKARO ADD_PLAYER_TO_KAPA".blue if DEBUGGING
    puts "Adding #{player_snapshot.childSnapshotForPath("display_name").value} to #{kapa_ref.URL}"
    kapa_ref.child("kaitakaro").updateChildValues({
      player_snapshot.key => player_snapshot.childSnapshotForPath("display_name").value},
      withCompletionBlock: proc do | error, ref |
        player_snapshot.ref.updateChildValues({"team" => kapa_ref.key})
        update_kapa_location(kapa_ref)
        @nga_kapa[index] << player_snapshot.childSnapshotForPath("display_name").value
        App.notification_center.post("KapaNew", kapa_ref)
      end
    )
  end

  def update_kapa_location(kapa_ref)
    puts "TAKARO UPDATE_KAPA_LOCATION".blue if DEBUGGING
    loc = CLLocationCoordinate2DMake(0, 0)
    # puts "Players url: #{@ref.child('players').URL}"
    @ref.child('players/').queryOrderedByChild("team").queryEqualToValue(kapa_ref.key).getDataWithCompletionBlock(
      lambda do | error, new_snapshot |
        # puts "new_snapshot: #{new_snapshot.value}"
        return if new_snapshot.nil?

        new_snapshot.children.each do |child|
          # puts child.childSnapshotForPath("location").value
          loc += format_to_location_coord(child.childSnapshotForPath("location").value)
        end
        loc /= new_snapshot.childrenCount
        # puts "new loc: #{loc}"
        kapa_ref.updateChildValues({"location" => {"latitude" => loc.latitude, "longitude" => loc.longitude}})
      end
    )
  end

  # def list_player_names_for_index(index)
  #   puts "TAKARO LIST_PLAYER_NAMES_FOR_INDEX".blue if DEBUGGING
  #   @ref.child("kapa/").queryStartingAtValue(index).getDataWithCompletionBlock(
  #     lambda do | error, kapa_snapshot |
  #       puts "kapa_snapshot: #{kapa_snapshot.ref.URL}"
  #       puts "kapa_snapshot: #{kapa_snapshot.value}"
  #       return list_player_names_for_kapa_ref(kapa_snapshot.ref)
  #     end
  #   )
  # end

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
    puts "kapa_ref: #{kapa_ref.key}".yellow if DEBUGGING
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

    # puts "list index: #{in_index}"
    # puts "List: #{@nga_kapa[in_index]}"
    @nga_kapa[in_index]
  end

  def player_count_for_index(in_index)
    puts "TAKARO PLAYER_COUNT_FOR_INDEX".blue if DEBUGGING
    # puts "Callee: #{__callee__}"
    # puts "player count in_index: #{in_index}"
    # puts "player count: #{@nga_kapa[in_index].count}"
    return 0 if @nga_kapa[in_index].nil?
    @nga_kapa[in_index].count
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
    puts "GAME: GENERATE_NEW_ID".blue if DEBUGGING
    # update the UI with the gamecode
    # https://gist.github.com/mbajur/2aba832a6df3fc31fe7a82d3109cb626
    rand(36**6).to_s(36)
  end
end

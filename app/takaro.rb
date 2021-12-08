class Takaro
  attr_accessor :ref,
                :uuid,
                :local_player_ref

  DEBUGGING = true
  TEAM_DISTANCE = 5

  @accepting_new_players = true

  # uuid is a string.
  def initialize(in_uuid = NSUUID.UUID.UUIDString)
    puts "TAKARO INITIALIZE".light_blue if DEBUGGING
    puts in_uuid
    @uuid = in_uuid
    @ref = Machine.instance.db.referenceWithPath("games/#{uuid}")
    # @ref = Machine.instance.db.referenceWithPath("games").childByAutoId
    puts @ref.URL

    # TODO add empty kapa

    # This is a force to get the most recent
    # TODO figure out if we can comment out
    @ref.getDataWithCompletionBlock(proc do | error, snapshot |
      puts "Snapshot: #{snapshot}"
    end)

    puts "Going Online!"
    FIRDatabaseReference.goOnline

    @ref.child("players").queryLimitedToLast(1).observeEventType(FIRDataEventTypeChildAdded,
      withBlock: proc do |player_snapshot|
        puts "TAKARO PLAYERADDED".red if DEBUGGING

        # Determine if there is a base team
        puts player_snapshot.key
        player_snapshot.children.each do |child|
          puts child.key
        end

        @ref.child("kapa").queryOrderedByChild("name").getDataWithCompletionBlock(
          proc do | error, kapa_snapshot |
            puts "Exists: #{kapa_snapshot.exists}"

          # Iterate through all the kapa
            kapa_snapshot.children.each do |k|
              puts "kapa: #{k.childSnapshotForPath('title').value}"
          # Check if the kapa has a location
              unless k.childSnapshotForPath("location").exists
          # If not, use this one
                add_player_to_kapa_ref(player_snapshot, k.ref)
              else
          # If the player is close enough use this one
                if get_distance(
                  player_snapshot.childSnapshotForPath("location").value,
                  k.childSnapshotForPath("location").value
                ) < TEAM_DISTANCE
          # Add the player
                  add_player_to_kapa_ref(player_snapshot, k.ref)
                else
                  # If no matches, tell them to move
                  puts "NOT CLOSE ENOUGH".pink if DEBUGGING
                end
              end
            end
            puts "FINISHED NEW VERSION".pink if DEBUGGING
          end
        )
      end
    )

    @takaro_update_location_observer = App.notification_center.observe "UpdateLocalPlayerPosition" do |data|
      puts "TAKARO UPDATELOCALPLAYERPOSITION".yellow if DEBUGGING
      @local_player_ref.updateChildValues(
        "location" => {
          "latitude" => data.object["latitude"],
          "longitude" => data.object["longitude"]
        }
      )
    end

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

  def add_player_to_kapa_ref(player_snapshot, kapa_ref)
    puts "TAKARO ADD_PLAYER_TO_KAPA".blue if DEBUGGING
    puts "Adding #{player_snapshot.childSnapshotForPath("display_name").value} to #{kapa_ref.URL}"
    kapa_ref.child("kaitakaro").updateChildValues({
      player_snapshot.key => player_snapshot.childSnapshotForPath("display_name").value},
    withCompletionBlock: proc do | error, ref |
      player_snapshot.ref.updateChildValues({"team" => kapa_ref.key})
      update_kapa_location(kapa_ref)
      end
    )

  end

  def update_kapa_location(kapa_ref)
    puts "TAKARO UPDATE_KAPA_LOCATION".blue if DEBUGGING
    loc = CLLocationCoordinate2DMake(0, 0)
    # puts "Players url: #{@ref.child('players').URL}"
    @ref.child('players/').queryOrderedByChild("team").queryEqualToValue(kapa_ref.key).getDataWithCompletionBlock(
      proc do | error, new_snapshot |
        # puts "new_snapshot: #{new_snapshot.value}"
        new_snapshot.children.each do |child|
          # puts child.childSnapshotForPath("location").value
          loc += format_to_location_coord(child.childSnapshotForPath("location").value)
        end
        loc /= new_snapshot.childrenCount
        # puts "new loc: #{loc}"
        kapa_ref.updateChildValues({"location" => {"latitude" => loc.latitude, "longitude" => loc.longitude}})

        # Just testing
        list_player_names
        # list_player_names_for_kapa_ref(kapa_ref)
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
        puts "kapa_hash: #{kapa_hash}"
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
end

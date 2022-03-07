class Kaitarako
  extend Utilities # Use extend with RubyMotion?

  attr_accessor :takaro,
                :kaitakaro_ref,
                :kapa_ref,
                :is_local,
                :kapa_color,
                :is_playing, # TODO this should not be here, should be in Takaro instead
                :deploy_time_ms,
                :lifespan_ms,
                :pouwhenua_start

  attr_reader :display_name,
              :email,
              :coordinate,
              :user_id

  DEBUGGING = false
  TEAM_DISTANCE = 3

  def initialize(ref, args={})
    puts "KAITAKARO INITIALIZE".light_blue if DEBUGGING
    @kaitakaro_ref = ref
    @is_local = false
    @is_playing = false

    @takaro = args["takaro"] ? args["takaro"] : nil

    @local_player_location_observer_coord = App.notification_center.observe "UpdateLocalPlayerPositionAsLocation" do |data|
      puts "DATA: #{data.object}" if DEBUGGING
      if @is_local && (@location_coords.nil? || data.object["new_location"].distanceFromLocation(data.object["old_location"]) > MOVE_THRESHOLD)
        self.coordinate = data.object["new_location"].coordinate
      end
    end
    puts "KAITAKARO REF: #{@kaitakaro_ref.URL}"
  end

  def display_name=(in_name)
    puts "KAITAKARO SET DISPLAY_NAME".blue if DEBUGGING
    @display_name = in_name
    @kaitakaro_ref.updateChildValues(
      {"display_name" => in_name}, withCompletionBlock:
      lambda do | error, ref |
        puts "KAITAKARO SET DISPLAY_NAME COMPLETE".blue if DEBUGGING
      end
    )
  end

  def display_name
    Dispatch.once { @display_name ||= get_remote_display_name }
    @display_name
  end

  def get_remote_display_name
    puts "KAITAKARO GET_REMOTE_DISPLAY_NAME".blue if DEBUGGING
    @kaitakaro_ref.child("display_name").getDataWithCompletionBlock(
      lambda do | error, data |
        puts "KAITAKARO GET_REMOTE_DISPLAY_NAME: #{data.value}"
        return data.value
      end
    )
  end

  def player_class=(in_player_class)
    @player_class = in_player_class
    @kaitakaro_ref.updateChildValues(
      {"player_class" => in_player_class}, withCompletionBlock:
      lambda do | error, ref |
        puts "KAITAKARO SET PLAYER_CLASS COMPLETE".blue if DEBUGGING
      end
    )
  end

  def player_class
    Dispatch.once { @player_class ||= get_remote_player_class }
    @player_class
  end

  def get_remote_player_class
    puts "KAITAKARO GET_REMOTE_PLAYER_CLASS".blue if DEBUGGING
    @kaitakaro_ref.child("player_class").getDataWithCompletionBlock(
      lambda do | error, data |
        puts "KAITAKARO GET_REMOTE_PLAYER_CLASS: #{data.value}"
        return data.value
      end
    )
  end

  def email=(in_email)
    puts "KAITAKARO SET EMAIL".blue if DEBUGGING
    @email = in_email
    @kaitakaro_ref.updateChildValues(
      {"email" => in_email}, withCompletionBlock:
      lambda do | error, ref |
        puts "KAITAKARO SET EMAIL COMPLETE".blue if DEBUGGING
      end
    )
  end

  def email
    puts "KAITAKARO EMAIL".blue if DEBUGGING
    # Dispatch.once { @email ||= get_remote_email }
    Dispatch.once { @email || do_with_remote_data("email") { |value| @email = value } }
    # do_with_remote_data("email") { |value| return value }
    @email
  end

  def get_remote_email
    puts "KAITAKARO GET_REMOTE_EMAIL".blue if DEBUGGING
    @kaitakaro_ref.child("email").getDataWithCompletionBlock(
      lambda do | error, data |
        puts "KAITAKARO GET_REMOTE_EMAIL: #{data.value}"
        return data.value
      end
    )
  end

  def user_id=(in_user_id)
    @user_id = in_user_id
    @kaitakaro_ref.updateChildValues(
      {"user_id" => in_user_id}, withCompletionBlock:
      lambda do | error, ref |
        puts "KAITAKARO SET USER_ID COMPLETE".blue if DEBUGGING
      end
    )
  end

  def coordinate=(in_coordinate)
    puts "KAITAKARO SET COORDINATE".blue if DEBUGGING
    @color_string = "0.0 0.0 0.0 1.0"
    @coordinate = in_coordinate
    # puts "coordinate: #{@coordinate}".focus
    @kaitakaro_ref.updateChildValues(
      {"coordinate" => {
        "latitude" => in_coordinate.latitude,
        "longitude" => in_coordinate.longitude
      }}, withCompletionBlock:
      lambda do | error, player_ref |
        # Here we need to check if we're still in the same Kapa
        # Maybe great with a closure, but hell if I understand them

        unless @is_playing

          @takaro.ref.child("kapa").getDataWithCompletionBlock(
            lambda do | error, kapa_snapshot |
              puts "KAITAKARO UPDATE_LOCAL_PLAYER_LOCATION ITERATING".blue if DEBUGGING
              # iterate through the existing kapa
              kapa_snapshot.children.each do |k|

                # This kapa doesn't have a location, so we can add this player
                unless k.childSnapshotForPath("coordinate").exists
                  # puts "KAITAKARO kapa doesn't have a coordinate".focus
                  @kapa_ref ||= k.ref
                  @color_string = k.childSnapshotForPath("color").value
                  # puts "new kapa color_string: #{@color_string}".focus
                else

                  # But if it does have a location
                  # check if we're close
                  if k.childSnapshotForPath("coordinate").exists && Utilities.get_distance(@coordinate, k.childSnapshotForPath("coordinate").value) < TEAM_DISTANCE
                    puts "Close enough!".yellow
                    @kapa_ref ||= k.ref
                    @color_string = k.childSnapshotForPath("color").value
                    # puts "add to kapa color_string: #{@color_string}".focus

                    # TODO where does this go…
                    break
                  else
                    # Under what circumstances do we end up here?
                    # TODO figure this shit out
                    # This is possibly when the bot gets added?
                    puts "testing for kapa_ref: #{@kapa_ref}"
                    # puts k.key
                    # puts k.childSnapshotForPath("coordinate").exists
                    # puts @coordinate
                    # puts k.childSnapshotForPath("coordinate").value
                    puts Utilities.get_distance(@coordinate, k.childSnapshotForPath("coordinate").value)
                    puts "\n\nDANGERZONE\n\n".focus
                    @color_string = "0.9 0.0 0.1 1.0"
                  end
                end
              end unless kapa_snapshot.childrenCount == 0
              # this checks in case there are no Kapa in the db

              # We should have a kapa_ref
              # But if not, we need to make a new one
              # if we are prepopulating the kapa, we should never get here
              if @kapa_ref.nil?
                # if we get here, the player hasn't matched a kapa
                puts "KAITAKARO UPDATE_LOCAL_PLAYER_LOCATION NO KAPA FOUND".blue if DEBUGGING
                # if there are less than two kapa, make a new one
                if kapa_snapshot.childrenCount < 2
                  puts "KAITAKARO UPDATE_LOCAL_PLAYER_LOCATION CREATING NEW KAPA".blue if DEBUGGING
                  @kapa_ref = @takaro.ref.child("kapa").childByAutoId
                else
                  # otherwise the player is too far from everyone
                  puts "#{@display_name} is TOO FAR FROM EVERYONE!!!".pink
                end
              end

              # TODO we need to check if they already have a kapa
              # send the data up
              # TODO why are we sending the name? Is it not there already?
              puts "KAITAKARO UPDATE_LOCAL_PLAYER_LOCATION SENDING DATA".blue if DEBUGGING
              @kapa_ref.child("kaitakaro/#{@kaitakaro_ref.key}").updateChildValues(
                {"name" => @display_name, "coordinate" => {
                  "latitude" => in_coordinate.latitude,
                  "longitude" => in_coordinate.longitude}
                }, withCompletionBlock:
                lambda do | error, player_ref |
                  puts "KAITAKARO UPDATE_LOCAL_PLAYER_LOCATION SETTING KAPA".blue if DEBUGGING
                  # update the player record
                  @kaitakaro_ref.updateChildValues(
                    {"team" => @kapa_ref.key}
                  )
                  # set the player color
                  # puts "color_string: #{@color_string}".focus
                  @kapa_color = defined?(@color_string) ? @color_string : "0.0 0.0 0.0 1.0"
                  # puts "kapa_color: #{kapa_color}".focus
                end
              )
            end
          )
        end
        puts "KAITAKARO SET COORDINATE COMPLETE"
      end
    )
  end

  def get_remote_data(in_key)
    puts "KAITAKARO GET_REMOTE_DATA".blue if DEBUGGING
    @kaitakaro_ref.child(in_key).getDataWithCompletionBlock(
      lambda do | error, data |
        puts "KAITAKARO GET_REMOTE_DATA: #{in_key} = #{data.value}"
        return data.value
      end
    )
  end

  def do_with_remote_data(in_key, &block)
    puts "KAITAKARO DO_WITH_REMOTE_DATA".blue if DEBUGGING
    @kaitakaro_ref.child(in_key).getDataWithCompletionBlock(
      lambda do | error, data |
        puts "KAITAKARO DO_WITH_REMOTE_DATA: #{in_key} = #{data.value}"
        block.call(data.value)
      end
    )
  end
end

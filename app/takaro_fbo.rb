# {
#   duration,
#   gamecode,
#   is_playing,
#   is_waiting,
#   kaitakaro
#   {
#   },
#   kapa
#   {
#     []
#   },
#   pouwhenua
#   {
#   },
#   taiapa
#   {
#     center
#     {
#     },
#     span
#     {
#     }
#   }
# }

# rubocop:disable Metrics/ClassLength
class TakaroFbo < FirebaseObject
  attr_accessor :kaitakaro_array,
                :kaitakaro_hash,
                :local_kapa_array,
                :local_kaitakaro,
                :local_pouwhenua,
                :taiapa_region # TODO: this might be hash later?

  DEBUGGING = true

  TEAM_DISTANCE = 3
  MOVE_THRESHOLD = 2
  TEAM_COUNT = 2
  FIELD_SCALE = 1.5

  def initialize(in_ref, in_data_hash)
    @kaitakaro_array = []
    @kaitakaro_hash = {}
    @local_kapa_array = []
    @local_pouwhenua = []

    puts 'TakaroFbo initialize'.red
    super.tap do |t|
      t.init_states
      t.init_kapa
      t.init_pouwhenua
    end
    Utilities::puts_close
  end

  def init_states
    # should this be part of the Machine?
    update({ 'is_waiting' => 'false' })
    update({ 'is_playing' => 'false' })
    self.waiting = false
    self.playing = false
  end

  def init_pouwhenua
    puts "FBO:#{@class_name} INIT_POUWHENUA".green if DEBUGGING

    @ref.child('pouwhenua').observeEventType(
      FIRDataEventTypeChildAdded, withBlock:
      lambda do |_data_snapshot|
        puts "FBO:#{@class_name} POUWHENUA ADDED".red if DEBUGGING
        pull_with_block { App.notification_center.post 'PouwhenuaFbo_New' }
      end
    )
  end

  def init_kapa
    puts "FBO:#{@class_name} INIT_KAPA".green if DEBUGGING

    @ref.child('kapa').observeEventType(
      FIRDataEventTypeChildAdded, withBlock:
      lambda do |_data_snapshot|
        puts "FBO:#{@class_name} KAPA ADDED".red if DEBUGGING
        # mp data_snapshot.valueInExportFormat

        App.notification_center.post 'KapaNew'
        pull
      end
    )

    @ref.child('kapa').observeEventType(
      FIRDataEventTypeChildRemoved, withBlock:
      lambda do |_data_snapshot|
        puts "FBO:#{@class_name} KAPA REMOVED".red if DEBUGGING
        # App.notification_center.post("#{@class_name}Changed", data_snapshot.valueInExportFormat)

        # puts "Removed snapshot: #{data_snapshot.valueInExportFormat}".focus
        # puts "Local kapa array: #{@local_kapa_array}".focus
        # # puts @kapa_array.delete_if { |k| k['id'] }
        App.notification_center.post 'KapaDelete'
        pull
      end
    )
  end

  def init_local_kaitakaro(in_character)
    puts "FBO:#{@class_name} init_local_kaitakaro".green if DEBUGGING
    kaitakaro_ref = @ref.child('kaitakaro').childByAutoId
    k = KaitakaroFbo.new(kaitakaro_ref, { 'character' => in_character })
    @local_kaitakaro = k

    add_kaitakaro(k)
  end

  def create_kapa(coordinate)
    puts 'Creating new kapa'
    kapa_ref = @ref.child('kapa').childByAutoId
    # puts "kapa_ref: #{kapa_ref.URL}".yellow
    # TODO: This uses random colors, which is an issue
    k = KapaFbo.new(kapa_ref, { 'color' => Utilities::random_color, 'coordinate' => coordinate })
    # mp k
    @local_kapa_array << k
    k
  end

  def remove_kapa(_in_ref)
    puts "FBO:#{@class_name} remove_kapa".green if DEBUGGING
    # puts "in_ref: #{in_ref}".focus
  end

  def create_bot_player
    puts "FBO:#{@class_name} create_bot_player".green if DEBUGGING

    bot_ref = @ref.child('kaitakaro').childByAutoId
    bot = KaitakaroFbo.new(bot_ref, { id: 666 }, true)
    bot.display_name = 'Jimmy Bot'
    bot.character = {
      'deploy_time' => 4,
      'lifespan_ms' => 280_000,
      'pouwhenua_start' => 3,
      'title' => 'Bot Character'
    }
    coord = @local_kaitakaro.coordinate

    bot.coordinate = {
      'latitude' => coord['latitude'] + rand(-0.01..0.01),
      'longitude' => coord['longitude'] + rand(-0.01..0.01)
    }

    add_kaitakaro(bot)
  end

  def add_kaitakaro(in_kaitakaro)
    puts "FBO:#{@class_name} add_kaitakaro".green if DEBUGGING

    @kaitakaro_array << in_kaitakaro
    @kaitakaro_hash[in_kaitakaro.data_hash['display_name']] = in_kaitakaro

    # send update to UI
    # This should ultimately be in the Kapa
    App.notification_center.post('PlayerNew', @kaitakaro_hash)
  end

  # This need to delete from both array and Hash
  # and then delete the kapa if empty
  def remove_kaitakaro_from_kapa(in_kaitakaro_id, in_kapa_id)
    puts 'remove_kaitakaro_from_kapa'.light_blue
    # puts @local_kapa_array
    # puts in_kapa_id
    # puts in_kaitakaro_id

    # Find the kapa
    kapa = @local_kapa_array.select { |k| k.ref.key == in_kapa_id }.first
    # puts "kapa: #{kapa}".focus
    kapa_empty = kapa.remove_kaitakaro(in_kaitakaro_id)
    # puts "kapa_empty: #{kapa_empty}".focus

    kapa = nil if kapa_empty
    # puts "remove_kaitakaro_from_kapa kapa_array after nil: #{@kapa_array.inspect}".focus
    @local_kapa_array.delete_if { |k| k.ref.key == in_kapa_id }.first
  end

  def kapa_with_key(in_key)
    @local_kapa_array.select { |k| k.ref.key == in_key }.first
  end

  # TODO: When a player moves too much, they can make a new kapa. Check for this?
  # TODO: if it's the only member, it can't move too far away?
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
  def set_initial_pouwhenua
    puts "FBO:#{@class_name}:#{__LINE__} set_initial_pouwhenua".green if DEBUGGING
    coord_array = []
    @local_kapa_array.each do |k|
      # mp k
      # create_new_pouwhenua(k['coordinate'], k['color'])
      # create_new_pouwhenua(k)
      data = k.data_for_pouwhenua

      # TODO: Should these initial pouwhenua ever die?
      data.merge!('lifespan_ms' => 120_000)
      # create_new_pouwhenua_from_hash(k.data_for_pouwhenua)
      create_new_pouwhenua_from_hash(data)

      # add to local coords
      coord_array << k.coordinate
    end

    # use coords to calculate play area
    lats = coord_array.map { |c| c['latitude'] }.minmax
    longs = coord_array.map { |c| c['longitude'] }.minmax

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

    @taiapa_region = MKCoordinateRegionMakeWithDistance(
      midpoint_location.coordinate, latitude_delta * 3, longitude_delta * 3
    )
    self.taiapa = {
      'midpoint' => midpoint_location.coordinate.to_hash,
      'latitude_delta' => latitude_delta * 3,
      'longitude_delta' => longitude_delta * 3
    }

    # TODO: Should this be in the Machine?
    Machine.instance.is_waiting = false
    Machine.instance.current_view.performSegueWithIdentifier('ToGameCountdown', sender: self)
  end
  # rubocop:enable Metrics/AbcSize

  def create_new_pouwhenua_from_hash(arg_hash = {})
    puts "FBO:#{@class_name}:#{__LINE__} create_new_pouwhenua_from_hash".green if DEBUGGING

    # the format we want to end up with:
    # color,
    # coordinate,
    # title,
    # kapa_key,
    # lifespan

    # get the player info
    new_pouwhenua_hash = @local_kaitakaro.data_for_pouwhenua.merge arg_hash

    p = PouwhenuaFbo.new(
      @ref.child('pouwhenua').childByAutoId, new_pouwhenua_hash
    )
    @local_pouwhenua << p

    pull
  end

  def create_new_pouwhenua(in_kapa = @local_kaitakaro.kapa)
    puts "FBO:#{@class_name}:#{__LINE__} create_new_pouwhenua".green if DEBUGGING

    # check if we're receiving a kapa
    # in which case we're probably setting up the initial pouwhenua
    # and we use the local player's coordinate
    # otherwise we use the kapa coordinate

    # check what format the kapa data is coming in as
    in_kapa = in_kapa.data_hash if in_kapa.is_a?(KapaFbo)

    # hash version
    p = PouwhenuaFbo.new(
      @ref.child('pouwhenua').childByAutoId,
      {
        'color' => in_kapa['color'],
        'coordinate' => in_kapa['coordinate'],
        'title' => 'Fbo Version',
        'kapa' => in_kapa['key'],
        # This should be a generic value across all teams
        # or perhaps based on number of people on a team
        'lifespan_ms' => 3000
      }
    )
    @local_pouwhenua << p

    pull
  end

  # TableView methods
  def player_count_for_index(in_index)
    puts "FBO:#{@class_name} player_count_for_index".green if DEBUGGING

    return 0 if kapa_array.nil?
    return 0 if kapa_array[in_index].nil?

    kapa_array[in_index]['kaitakaro']&.count
  end

  def list_player_names_for_index(in_index)
    puts "FBO:#{@class_name} list_player_names_for_index".green if DEBUGGING
    # puts "in_index: #{in_index}".red

    return nil if kapa_array.nil?

    nga_kaitakaro = kapa_array[in_index]['kaitakaro'].values
    nga_kaitakaro.flatten(1).map { |k| { 'display_name' => k['display_name'], 'character' => k['character'] } }
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

  def pouwhenua_array
    puts "pouwhenua_array: #{@data_hash['pouwhenua']&.values}"
    @data_hash['pouwhenua']&.values

    # TODO: This doesn't seem to work
    # h = @data_hash['pouwhenua']&.select { |p| p['enabled'] == 'true' }
    # h&.values
  end

  def pouwhenua_array_enabled_only
    pouwhenua_array.select { |p| p['enabled'] == 'true' }
  end

  def taiapa=(in_region)
    update({ 'taiapa' => in_region })
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
end
# rubocop:enable Metrics/ClassLength

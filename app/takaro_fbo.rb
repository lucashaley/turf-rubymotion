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
      unless in_data_hash.nil?
        t.init_states
        t.init_kapa
        t.init_pouwhenua
      end
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
        pull_with_block { Notification.center.post 'PouwhenuaFbo_New' }
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

        Notification.center.post 'KapaNew'
        pull
      end
    )

    @ref.child('kapa').observeEventType(
      FIRDataEventTypeChildRemoved, withBlock:
      lambda do |_data_snapshot|
        puts "FBO:#{@class_name} KAPA REMOVED".red if DEBUGGING
        # Notification.center.post("#{@class_name}Changed", data_snapshot.valueInExportFormat)

        # puts "Removed snapshot: #{data_snapshot.valueInExportFormat}".focus
        # puts "Local kapa array: #{@local_kapa_array}".focus
        # # puts @kapa_array.delete_if { |k| k['id'] }
        Notification.center.post 'KapaDelete'
        pull
      end
    )
  end

  def init_local_kaitakaro(in_character)
    puts "FBO:#{@class_name} init_local_kaitakaro".green if DEBUGGING
    kaitakaro_ref = @ref.child('kaitakaro').childByAutoId
    k = KaitakaroFbo.new(
      kaitakaro_ref,
      {
        'character' => in_character,
        'display_name' => Machine.instance.user.displayName
      }
    )
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

    bot_data = {
      'display_name' => 'Jimmy Bot',
      'character' => {
        'deploy_time' => 4,
        'lifespan_ms' => 280_000,
        'pouwhenua_start' => 3,
        'title' => 'Bot Character'
      }
    }

    bot_ref = @ref.child('kaitakaro').childByAutoId
    bot = KaitakaroFbo.new(bot_ref, bot_data, true)

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
    Notification.center.post('PlayerNew', @kaitakaro_hash)
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
    puts "takaro_fbo kapa_with_key: #{in_key}"
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
      data = k.data_for_pouwhenua
      # mp data

      # TODO: Should these initial pouwhenua ever die?
      # data.merge!('lifespan_ms' => 120_000)
      data.merge!('lifespan_ms' => duration * 60 * 1000)

      create_new_pouwhenua_from_hash(data, true)

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

  def create_new_pouwhenua_from_hash(arg_hash = {}, is_initial = false)
    puts "FBO:#{@class_name}:#{__LINE__} create_new_pouwhenua_from_hash".green if DEBUGGING

    # Check if the player still has available pouwhenua
    # puts @local_kaitakaro.pouwhenua_current.to_s.focus
    return if @local_kaitakaro.pouwhenua_current <= 0

    # the format we want to end up with:
    # color,
    # coordinate,
    # title,
    # kapa_key,
    # lifespan

    # get the player info
    new_pouwhenua_hash = @local_kaitakaro.data_for_pouwhenua.merge arg_hash

    # remove the kaitakaro for initial pouwhenua
    # TODO: not sure we need this, it's also super clunky
    new_pouwhenua_hash.delete('kaitakaro_key') if is_initial

    p = PouwhenuaFbo.new(
      @ref.child('pouwhenua').childByAutoId, new_pouwhenua_hash
    )
    @local_pouwhenua << p

    @local_kaitakaro.pouwhenua_decrement unless is_initial

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

    return nil if kapa_array.nil?

    nga_kaitakaro = kapa_array[in_index]['kaitakaro'].values
    nga_kaitakaro.flatten(1).map { |k| { 'display_name' => k['display_name'], 'character' => k['character'] } }
  end

  def calculate_score
    puts 'calculate_score'
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

  def taiapa=(in_region)
    update({ 'taiapa' => in_region })
  end

  def taiapa
    @data_hash['taiapa']
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

  def score(kapa_key, score)
    puts "Score for #{kapa_key}: #{score}".focus
    # mp kapa_hash
    # mp local_kapa_array
  end

  def kaitakaro_annotations
    annotations = []

    # this just gets the local kaitakaro's kapa
    kaitakaro_for_kapa.each do |k|
      # TODO: this is a hack
      # perhaps we need to massage in the kaitakaro method
      k_hash = k[1]

      ka = KaitakaroAnnotation.alloc.initWithCoordinate(
        Utilities::format_to_location_coord(k_hash['coordinate'])
      )
      ka.color = UIColor.alloc.initWithCIColor(CIColor.alloc.initWithString(k_hash['kapa']['color']))
      ka.title = k_hash['display_name']
      ka.subtitle = k_hash['character']['title']
      annotations << ka
    end

    puts "Annotations: #{annotations}".focus
    annotations
  end

  def pouwhenua_annotations
    annotations = []

    # this just gets the local kaitakaro's kapa
    pouwhenua_array_for_kapa.each do |p|
      pa = KaitakaroAnnotation.alloc.initWithCoordinate(
        Utilities::format_to_location_coord(p['coordinate'])
      )
      pa.color = UIColor.alloc.initWithCIColor(CIColor.alloc.initWithString(p['color']))
      annotations << pa
    end

    puts "Annotations: #{annotations}".focus
    annotations
  end
end

# {
#   color,
#   coordinate
#   {
#     latitude,
#     longitude
#   },
#   created,
#   kaitakaro
#   {
#
#   }
# }

class KapaFbo < FirebaseObject
  attr_reader :kaitakaro_array

  DEBUGGING = true

  def initialize(in_ref, in_data_hash)
    puts "FBO:#{@class_name}:#{__LINE__} initialize".green if DEBUGGING
    @team_distance = 50
    @kaitakaro_array = []
    # @kaitakaro_hash = {}
    super.tap do
      Notification.center.post 'Kapafbo_New'
    end
    Utilities::puts_close
  end

  def add_kaitakaro(in_kaitakaro)
    puts "FBO:#{@class_name}:#{__LINE__} add_kaitakaro".green if DEBUGGING

    in_kaitakaro.kapa = self

    @kaitakaro_array << in_kaitakaro

    update({ 'kaitakaro' => kaitakaro_hash })

    Notification.center.post 'PlayerChanged'
    recalculate_coordinate
  end

  # TODO: Check if it's the last kaitakaro, and delete kapa if so
  # do we also need to delete the object too?
  def remove_kaitakaro(in_kaitakaro)
    puts 'Removing kaitakaro from kapa'.red
    puts "To remove: #{in_kaitakaro.inspect}"
    puts "To remove: #{@kaitakaro_array.inspect}"

    @kaitakaro_array.delete_if { |k| k.key == in_kaitakaro }
    puts "Array after delete: #{@kaitakaro_array}".yellow
    # @kaitakaro_hash.delete in_kaitakaro
    puts "hash after delete: #{@kaitakaro_hash}".yellow
    update({ 'kaitakaro' => kaitakaro_hash })

    delete if @data_hash['kaitakaro'].empty?
    Machine.instance.takaro_fbo.remove_kapa(@ref) if @data_hash['kaitakaro'].empty?

    @data_hash['kaitakaro'].empty?
  end

  def self.remove_kaitakaro_with_key(in_kaitakaro, in_key)
    puts 'remove_kaitakaro_with_key'.red

    # first, find the Kapa
    k = Machine.instance.takaro_fbo.kapa_with_key(in_key)

    # then remove the kaitakaro
    k.remove_kaitakaro(in_kaitakaro)
  end

  def empty?
    @kaitakaro_array.empty?
  end

  def check_distance(in_coordinate)
    get_distance(coordinate, in_coordinate) < @team_distance
  end

  def recalculate_coordinate
    puts 'Recaluclating coordinate'.red
    lat = 0
    long = 0
    @kaitakaro_array.each do |k|
      coordinate = k.coordinate

      lat += coordinate['latitude'].to_f
      long += coordinate['longitude'].to_f
    end
    lat /= @kaitakaro_array.count
    long /= @kaitakaro_array.count
    self.coordinate = { 'latitude' => lat, 'longitude' => long }

    # TODO: Do we need to update all the kaitakaro?
    @kaitakaro_array.each { |k| k.kapa = self }
  end

  def list_display_names_and_classes
    puts "FBO:#{@class_name} list_display_names_and_classes".blue if DEBUGGING
    return if @kaitakaro_array.empty?

    # @kaitakaro_array.map { |k| k.name_and_character }
    # old data_for_kapa version
    # @kaitakaro_array.map { |k| { 'display_name' => k['display_name'], 'character' => k['character'] } }
    # @kaitakaro_array.map { |k| { 'display_name' => k.display_name, 'character' => k.character } }

    # @kaitakaro_array.map { |k| k.name_and_character }
    @kaitakaro_array.map(&:name_and_character)
  end

  # Helpers
  def kaitakaro
    @data_hash['kaitakaro']
  end

  def kaitakaro_hash
    # TODO: make a Kaitarako method to spit out hash version?
    # @kaitakaro_array.to_h { |k| [k.key, k.data_for_kapa] }
    h = {}
    @kaitakaro_array.each do |k|
      h[k.key] = k.data_for_kapa
    end
    h
  end

  def color
    @data_hash['color']
  end

  def color=(in_color)
    update({ 'color' => in_color })
  end

  def coordinate
    @data_hash['coordinate']
  end

  def coordinate=(in_coordinate)
    update({ 'coordinate' => in_coordinate })
  end

  def data_for_kaitakaro
    {
      'kapa_key' => @ref.key,
      'color' => color,
      'coordinate' => coordinate
    }
  end

  def data_for_pouwhenua
    {
      'kapa_key' => key,
      'color' => color,
      'coordinate' => coordinate
    }
  end

  # Utilities, why is this not being pulled in
  def get_distance(coord_a, coord_b)
    MKMetersBetweenMapPoints(
      MKMapPointForCoordinate(
        format_to_location_coord(coord_a)
      ),
      MKMapPointForCoordinate(
        format_to_location_coord(coord_b)
      )
    )
  end

  def format_to_location_coord(input)
    case input
    when Hash
      h = recursive_symbolize_keys(input)
      return CLLocationCoordinate2DMake(h[:latitude], h[:longitude])
    when CLLocationCoordinate2D
      return input
    end
    0
  end

  def recursive_symbolize_keys(hsh)
    case hsh
    when Hash
      Hash[
        hsh.map do |k, v|
          [k.respond_to?(:to_sym) ? k.to_sym : k, recursive_symbolize_keys(v)]
        end
      ]
    when Enumerable
      hsh.map { |v| recursive_symbolize_keys(v) }
    else
      hsh
    end
  end
end

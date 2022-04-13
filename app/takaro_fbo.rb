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

class TakaroFbo < FirebaseObject
  extend Utilities

  attr_accessor :kaitakaro_array,
                :kaitakaro_hash,
                :kapa_array,
                :kapa_hash,
                :local_kaitakaro

  TEAM_DISTANCE = 3
  MOVE_THRESHOLD = 2
  TEAM_COUNT = 2
  FIELD_SCALE = 1.5

  def initialize(in_ref, in_data_hash)
    @duration = 0
    @kaitakaro_array = []
    @kaitakaro_hash = {}
    @kapa_array = []
    @kapa_hash = {}

    puts 'TakaroFbo initialize'.red
    super.tap do |t|
      t.init_states
      t.init_kapa
      t.init_local_kaitakaro
    end
  end

  def init_states
    # should this be part of the Machine?
    update({ 'is_waiting' => 'false' })
    update({ 'is_playing' => 'false' })
  end

  def init_kapa
    puts "FBO:#{@class_name} INIT_KAPA".green if DEBUGGING
    TEAM_COUNT.times do |i|
      kapa_ref = @ref.child('kapa').childByAutoId
      puts "kapa_ref: #{kapa_ref.URL}".yellow
      k = KapaFbo.new(kapa_ref, { id: i })
      @kapa_array << k
      @kapa_hash[kapa_ref.key] = k
    end

    puts @kapa_array
    puts @kapa_hash
    puts @data_hash
  end

  def init_local_kaitakaro
    kaitakaro_ref = @ref.child('kaitakaro').childByAutoId
    k = KaitakaroFbo.new(kaitakaro_ref, { id: 1 })
    @local_kaitakaro = k

    add_kaitakaro(k)
  end

  def add_kaitakaro(in_kaitakaro)
    puts "FBO:#{@class_name} ADD_KAITAKARO".green if DEBUGGING

    @kaitakaro_array << in_kaitakaro
    @kaitakaro_hash[in_kaitakaro.data_hash['display_name']] = in_kaitakaro

    puts @kaitakaro_array.inspect
    puts @kaitakaro_hash.inspect
  end

  # Helpers
  def gamecode
    data_hash['gamecode']
  end

  def gamecode=(in_gamecode)
    update({ 'gameode' => in_gamecode })
  end

  def duration
    data_hash['duration']
  end

  def duration=(in_duration)
    update({ 'duration' => in_duration })
  end
end

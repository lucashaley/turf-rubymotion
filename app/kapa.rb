# == Kapa
# The kapa is the team for the current game.
# The teams will be different for every game.
class Kapa < FirebaseObject
  extend Debugging

  attr_accessor :color,
                :uuid,
                :nga_kaitakaro,
                :location,
                :title

  DEBUGGING = true
  FIREBASE_CLASSPATH = "kapa"

  def initialize(in_ref, in_title)
    super(in_ref.child(FIREBASE_CLASSPATH)).tap do |k|
      puts "KAPA INITIALIZE".green if DEBUGGING
      k.nga_kaitakaro = {}
      k.title = in_title
      k.uuid = NSUUID.UUID
      k.color = CIColor.alloc.initWithColor(UIColor.whiteColor)

      k.variables_to_save = ["color",
                             "title"]
      k.update_all
    end
  end

  def update_average_location
    puts "KAPA UPDATE_AVERAGE_LOCATION".blue if DEBUGGING
    @nga_kaitakaro.each do |kaitakaro|

    end
  end

  def add_player_to_kapa(uuid, name)
    puts "KAPA ADD_PLAYER_TO_KAPA".blue if DEBUGGING
    @nga_kaitakaro[uuid] = name
    puts self.count
    # this is handled in game
    # App.notification_center.post("PlayerNewInKapa", object: self)

    # every time we add a new player, we have to recalculate the average location
    update_average_location
  end

  def count
    puts "KAPA COUNT".blue if DEBUGGING
    @nga_kaitakaro.length
  end

  def player_names
    @nga_kaitakaro.values
  end

  def to_s
    "Kapa. Title: #{@title}, uuid: #{@uuid.UUIDString}, color: #{@color}"
  end
end
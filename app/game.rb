class Game
  attr_accessor :uuid,
                :gamecode,
                :update_handler,
                :pylons

  def initialize
    puts "\n\nGame.initialize"

    @uuid = NSUUID.UUID
    @gamecode = generate_new_id

    @update_handler = Proc.new do |error, snapshot|
      puts "update_handler: #{snapshot}"
    end
    puts "#{@update_handler}"
  end

  def init_new_game
    puts "Game initialize"
    @gamecode = generate_new_id
    puts "Gamecode: #{@gamecode}"
  end

  def self.init_from_firebase(data)
    puts "\n\n----\ninit_from_firebase\ndata: #{data}\n\n"
    @pylons = []
    _pylons = {}
    # _this_ref = Machine.instance.db.child("games").orderByChild("gamecode").equalTo(data[:gamecode]).on("value")
    _games_ref = Machine.instance.db.referenceWithPath("games")
    _this_query = _games_ref.queryOrderedByChild("gamecode").queryEqualToValue(data[:gamecode])
    puts "_this_query: #{_this_query}"
    _this_query.observeSingleEventOfType(FIRDataEventTypeValue, withBlock:
      lambda do |snapshot|
        snapshot.children.each do |child|
          _pylons = child.value[:pylons]
          _pylons.each do |p|
            _new_pylon = Pylon.initWithHash(p[1])
            # this is awkward, should be part of natural init
            _new_pylon.set_uuid(p[0])
            puts "\n_new_pylon: #{_new_pylon}"
            @pylons << _new_pylon
          end
        end
        puts "@pylons:\n#{@pylons}"
      end
    )
  end

  def generate_new_id
    puts "Machine generate_new_id"
    # update the UI with the gamecode
    # https://gist.github.com/mbajur/2aba832a6df3fc31fe7a82d3109cb626
    new_id = rand(36**6).to_s(36)

    # check if it exists already
    # puts @db_ref.child("games")
  end

  def add_pylon(pylon)
    Machine.instance.db_game_ref.child("pylons/pylon-03").setValue("Hairline")
  end

end

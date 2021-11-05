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
    # _this_ref = Machine.instance.db.child("games").orderByChild("gamecode").equalTo(data[:gamecode]).on("value")
    _games_ref = Machine.instance.db.referenceWithPath("games")
    puts "_games_ref: #{_games_ref.URL}\n"
    _games_ref.observeEventType(FIRDataEventTypeValue, withBlock:
      lambda do |data|
        puts "data: #{data}"
        data.children.each do |c|
          puts "\n#{c.value}"
        end
      end
    )
    puts data[:gamecode]
    _this_ref = _games_ref.queryEqualToValue(data[:gamecode], childKey:"gamecode")
    # Machine.instance.@db.referenceWithPath("games/#{data[:gamecode]}").observeEventType(FIRDataEventTypeValue, withBlock:Machine.instance.handleDataResult)
    puts "_this_ref: #{_this_ref}"
    _pylons = []
    # _data = BW::JSON.parse(data.value)
    # _this_ref.childSnapshotForPath("pylons").children.each do |p|
    #   puts p.childSnapshotForPath("title").value
    #   _pylons << Pylon.initWithLocation(\
    #             CLLocationCoordinate2DMake( \
    #             p.childSnapshotForPath("location/latitude").value, \
    #             p.childSnapshotForPath("location/longitude").value), \
    #             p.childSnapshotForPath("color").value, \
    #             p.childSnapshotForPath("title").value)
    # end
    _games_ref.queryEqualToValue(data[:gamecode], childKey:"gamecode").observeSingleEventOfType(FIRDataEventTypeValue, withBlock:
      lambda do |snapshot|
        puts "Snapshot: #{snapshot.hasChildren?}\n"
        snapshot.children.each do |child|
          puts "Child value: #{child.value}\n"
        end
      end
    )
    puts _pylons
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

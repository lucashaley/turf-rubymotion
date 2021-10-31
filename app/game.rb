class Game
  attr_accessor :gamecode, :update_handler

  def initialize
    puts "\n\nGame.initialize"
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
    _pylons = []
    # _data = BW::JSON.parse(data.value)
    data.childSnapshotForPath("pylons").children.each do |p|
      puts p.childSnapshotForPath("title").value
      _pylons << Pylon.initWithLocation(\
                CLLocationCoordinate2DMake( \
                p.childSnapshotForPath("location/latitude").value, \
                p.childSnapshotForPath("location/longitude").value), \
                p.childSnapshotForPath("color").value, \
                p.childSnapshotForPath("title").value)
    end
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

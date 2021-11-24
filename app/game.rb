class Game
  extend Debugging
  attr_accessor :uuID,
                :gamecode,
                :update_handler,
                :pylons,
                :pouwhenua,
                :firebase_ref,
                :nga_kapa

  DEBUGGING = true

  def initialize
    puts "GAME: INITIALIZE".green if DEBUGGING

    @uuID = NSUUID.UUID
    @gamecode = generate_new_id
    @pylons = []
    @pouwhenua = []

    @update_handler = proc do |error, snapshot|
      puts "update_handler: #{snapshot}"
    end
  end

  def self.init_with_hash(args)
    puts "GAME INIT_WITH_HASH".green if DEBUGGING

    puts "args: #{args}".green if DEBUGGING
    symbol_args = recursive_symbolize_keys(args)

    new_game = Game.new
    new_game.uuID = symbol_args[:key]
    symbol_args[:pylons].each do |pylon|
      h = {key: pylon[0]}.merge(pylon[1])
      new_game.pylons << Pylon.initWithHash(h)
    end
    symbol_args[:pouwhenua].each do |pouwhenua|
      new_game.pouwhenua << Pouwhenua.init_with_hash(pouwhenua)
    end
    # new_game.color = symbol_args[:color] ? CIColor.alloc.initWithString(args[:color]) : CIColor.alloc.initWithColor(UIColor.systemYellowColor)
    # new_game.title = symbol_args[:title] || "MungMung"
    # new_game.lifespan = symbol_args[:lifespan] || 0
    new_game
  end

  def self.init_new_game
    puts "GAME: INIT_NEW_GAME".green if DEBUGGING
    new_game = Game.new
    puts "Gamecode: #{new_game.gamecode}"

    # Create new game on Firebase
    Machine.instance.db.referenceWithPath("games")
      .child(new_game.uuID.UUIDString)
      .setValue({gamecode: new_game.gamecode},
      withCompletionBlock: lambda do |error, ref|
        new_game.firebase_ref = ref
        new_game.set_ref(ref)
        puts "\nNew game reference: #{ref}".red
        # ref.child("pylons/plug").setValue("foo")
        # _game.firebase_ref.child("pylons/plug").setValue("foo")

        # Add some pylons in for testing
        # These should end up being the starting positions
        ### PYLON FIX
        # puts "Creating test pylons".red
        # new_game.create_new_pylon(CLLocationCoordinate2DMake(37.33350562755614, -122.02849767766669))
        # new_game.create_new_pylon(CLLocationCoordinate2DMake(37.33063930240253, -122.03102976399545))
        puts "Creating test pouwhenua".red
        new_game.create_new_pouwhenua(CLLocationCoordinate2DMake(37.33350562755614, -122.02849767766669))
        new_game.create_new_pouwhenua(CLLocationCoordinate2DMake(37.33063930240253, -122.03102976399545))

        new_game.add_player(Machine.instance.user) if Machine.instance.user
      end)
    return new_game
  end

  # def self.init_from_firebase(data)
  #   puts "GAME: INIT_FROM_FIREBASE".green if DEBUGGING
  #   _game = Game.new
  #   _game.gamecode = data[:gamecode] || "abc123"
  #   _game.pylons = []
  #   _pylons = {}
  #   # _this_ref = Machine.instance.db.child("games").orderByChild("gamecode").equalTo(data[:gamecode]).on("value")
  #   _games_ref = Machine.instance.db.referenceWithPath("games")
  #   _this_query = _games_ref.queryOrderedByChild("gamecode")
  #                           .queryEqualToValue(data[:gamecode])
  #   # puts "_this_query: #{_this_query}"
  #   _this_query.getDataWithCompletionBlock(
  #     lambda do | error, snapshot |
  #       snapshot.children.each do |child|
  #         puts "\nchild: #{child.ref.URL}".red
  #         # This seems really crude
  #         # and probably problematic
  #         _game.firebase_ref = child.ref
  #         _game.set_ref(child.ref)
  #         puts "new firebase ref: #{_game.firebase_ref}".red
  #         # SET UP OBSERVERS
  #         # It would be nice to do this in the controller?
  #         # _game.firebase_ref.child("pylons").observeEventType(FIRDataEventTypeChildAdded,
  #         #   withBlock: proc do |data|
  #         #     puts "New pylon data: #{data}"
  #         #     App.notification_center.post("PylonNew", data)
  #         #   end)
  #         #
  #         # _pylons = child.value[:pylons]
  #         # _pylons.each do |p|
  #         #   _new_pylon = Pylon.initWithHash(p[1])
  #         #   # this is awkward, should be part of natural init
  #         #   _new_pylon.set_uuid(p[0])
  #         #   # puts "\n_new_pylon: #{_new_pylon}"
  #         #   _game.pylons << _new_pylon
  #         # end
  #       end
  #       # puts "@pylons:\n#{_game.pylons}"
  #
  #       _game.firebase_ref.child("pylons").observeEventType(FIRDataEventTypeChildAdded,
  #         withBlock: proc do |data|
  #           puts "New pylon data: #{data}"
  #           puts "#{data.childrenCount}"
  #           puts "#{data.value}"
  #           App.notification_center.post("PylonNew", data)
  #         end)
  #     end
  #   )
  #
  #   return _game
  # end

  def set_ref(ref)
    puts "GAME: SET_REF".blue if DEBUGGING
    @firebase_ref = ref
  end

  def generate_new_id
    puts "GAME: GENERATE_NEW_ID".blue if DEBUGGING
    # update the UI with the gamecode
    # https://gist.github.com/mbajur/2aba832a6df3fc31fe7a82d3109cb626
    new_id = rand(36**6).to_s(36)

    # check if it exists already
    # puts @db_ref.child("games")

    # TODO firebase call to find existing, just to make sure?
  end

  def add_player(player)
    puts "GAME ADD_PLAYER".blue if DEBUGGING

    puts "adding player: #{player}".red if DEBUGGING

    new_player = Player.new({user_id: player.userID, given_name: player.profile.givenName, email: player.profile.email})
    puts "new_player: #{new_player}".red if DEBUGGING

    @firebase_ref.child("players/#{new_player.uuid.UUIDString}").setValue(new_player.to_hash) # if @firebase_ref
    @firebase_ref.child("teams/00/user_id").setValue(new_player.uuid.UUIDString)
  end

  def create_new_pylon(coord)
    puts "GAME: CREATE NEW PYLON".blue if DEBUGGING

    puts "Input location: #{coord.longitude}, #{coord.latitude}".red

    # CREATE NEW PYLON OBJECT
    new_pylon = Pylon.initWithHash({:location => coord})
    puts "_new_pylon: #{new_pylon}"
    puts "firebase_ref: #{@firebase_ref}"

    # SEND THE NEW PYLON TO FIREBASE
    # TODO this should probably be threaded
    @firebase_ref.child("pylons/#{new_pylon.uuID.UUIDString}").setValue(new_pylon.to_hash) # if @firebase_ref

    # ONCE ITS POSTED, THE MODEL SHOULD COLLECT IT
  end

  def create_new_pouwhenua(coord)
    puts "GAME CREATE_NEW_POUWHENUA".blue if DEBUGGING
    new_pouwhenua = Pouwhenua.new(coord)
    @firebase_ref.child("pouwhenua/#{new_pouwhenua.uuid_string}").setValue(new_pouwhenua.to_hash)
  end

  def modify_pylon
    puts "GAME: MODIFY PYLON".blue if DEBUGGING

    # FIND PYLON

    # UPDATE PYLON
  end

  def start_observing_pylons
    puts "GAME: START_OBSERVING_PYLONS".blue if DEBUGGING

    @firebase_ref.child("pylons").observeEventType(FIRDataEventTypeChildAdded,
      withBlock: proc do |data|
        # Should we turn it into a better-formed hash here?
        App.notification_center.post("PylonNew", data)
    end)
  end

  def start_observing_pouwhenua
    puts "GAME: START_OBSERVING_POUWHENUA".blue if DEBUGGING

    @firebase_ref.child("pouwhenua").observeEventType(FIRDataEventTypeChildAdded,
      withBlock: proc do |data|
        # Should we turn it into a better-formed hash here?
        App.notification_center.post("PouwhenuaNew", data)
    end)
  end

  def check_for_game(gamecode)
    puts "GAME CHECK_FOR_GAME".blue if DEBUGGING

  end

  def start_observing_players
    puts "GAME START_OBSERVING_PLAYERS".blue if DEBUGGING

    @firebase_ref.child("players").observeEventType(FIRDataEventTypeChildAdded,
      withBlock: proc do |data|
        App.notification.center.post("PlayerNew", data)
    end)
  end
end

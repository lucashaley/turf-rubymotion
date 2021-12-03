class GameOld
  extend Debugging
  attr_accessor :uuID,
                :gamecode,
                :update_handler, #what is this for?
                :pylons,
                :pouwhenua,
                :firebase_ref,
                :nga_kapa,
                :nga_kaitakaro,
                :local_player

  DEBUGGING = true

  def initialize
    puts "GAME: INITIALIZE".green if DEBUGGING

    @uuID = NSUUID.UUID
    @gamecode = generate_new_id
    @pylons = []
    @pouwhenua = []

    # make the teams, and populate with two default teams
    @nga_kapa = []
    @nga_kaitakaro = {}

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
    # TODO Convert this to a tap
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
        new_game.start_observing_players

        # Add some pylons in for testing
        # These should end up being the starting positions
        ### PYLON FIX
        puts "Creating test pylons".red
        new_game.create_new_pylon(CLLocationCoordinate2DMake(37.33350562755614, -122.02849767766669))
        new_game.create_new_pylon(CLLocationCoordinate2DMake(37.33063930240253, -122.03102976399545))
        # puts "Creating test pouwhenua".red
        # new_game.create_new_pouwhenua(CLLocationCoordinate2DMake(37.33350562755614, -122.02849767766669))
        # new_game.create_new_pouwhenua(CLLocationCoordinate2DMake(37.33063930240253, -122.03102976399545))

        # Can't add until we have a firebase_ref
        new_game.nga_kapa << Kapa.new(new_game.firebase_ref, "TeamA")
        new_game.nga_kapa << Kapa.new(new_game.firebase_ref, "TeamB")

        # Add the current player
        # TODO should this be here? Issues with observing above
        # What is the user?
        puts Machine.instance.user
        new_game.add_local_player(Machine.instance.user) if Machine.instance.user
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

  def add_local_player(user)
    puts "GAME ADD_LOCAL_PLAYER".blue if DEBUGGING

    puts "adding user: #{user}".red if DEBUGGING
    puts user.providerData

    @local_player = Player.new({ref: @firebase_ref, user_id: user.uid, given_name: user.displayName, email: user.email})
    puts "new_player: #{@local_player}".red if DEBUGGING
    @nga_kaitakaro[@local_player.uuid => @local_player]
    puts @nga_kaitakaro
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
    # Do we even still need to do this?
    puts "GAME START_OBSERVING_PLAYERS".blue if DEBUGGING
    puts @firebase_ref

    @firebase_ref.child("players").observeEventType(FIRDataEventTypeChildAdded,
      withBlock: proc do |data|
        puts "GAME RECEIVED NEW PLAYER".yellow if DEBUGGING
        # what does this data look like?
        puts "Data.key: #{data.key}"

        # data.key gives the uuid
        # data.childSnapshotForPath("display_name").value gives the user name

        # check if first team is empty
        if @nga_kapa[0].count == 0
          # team a is empty, so add to that team
          @nga_kapa[0].add_player_to_kapa(data)
          @nga_kapa[0].player_names
        end
        # first team is not empty, so we have to either put it in a team, or distance warning.
        puts data.childSnapshotForPath("location").value
        # post notification for UI
        App.notification_center.post("PlayerNew", data)
    end)
  end

  def start_observing_kapa
    puts "GAME START_OBSERVING_KAPA".blue if DEBUGGING

    @firebase_ref.child("teams").observeEventType(FIRDataEventTypeChildAdded,
      withBlock: proc do |data|
        App.notification.center.post("KapaNew", data)
    end)
  end
end

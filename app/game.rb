class Game < FirebaseObject
  extend Debugging
  attr_accessor :gamecode,
                :update_handler, #what is this for?
                :pylons,
                :pouwhenua,
                # :firebase_ref,
                :nga_kapa,
                :nga_kaitakaro,
                :local_player

  DEBUGGING = true
  FIREBASE_CLASSPATH = "games"

  def initialize
    super(Machine.instance.db.referenceWithPath(FIREBASE_CLASSPATH)).tap do |g|
      puts "GAME INITIALIZE".green if DEBUGGING
      g.gamecode = generate_new_id
      g.pylons = []
      g.pouwhenua = []
      g.nga_kapa = []
      g.nga_kaitakaro = {}

      g.variables_to_save = ["gamecode"]

      # Can we do this without an update?
      g.update_all.tap do |gg|
        puts "#{g.uuid_string}".pink
        g.start_observing_pylons
        puts "Creating test pylons".red
        g.create_new_pylon(CLLocationCoordinate2DMake(37.33350562755614, -122.02849767766669))
        g.create_new_pylon(CLLocationCoordinate2DMake(37.33063930240253, -122.03102976399545))

        # Can't add until we have a firebase_ref
        g.nga_kapa << Kapa.new(g.ref, "TeamA")
        g.nga_kapa << Kapa.new(g.ref, "TeamB")

        g.add_local_player(Machine.instance.user) if Machine.instance.user

        # TODO this probably shouldn't be here
        puts "Turning on tracking".light_blue
        Machine.instance.tracking = true
      end
    end
  end

  def self.init_with_hash(args)
    Game.new.tap do |g|
      puts "GAME INIT_FROM_HASH".light_blue if DEBUGGING
      puts "args: #{args}".green if DEBUGGING
      symbol_args = recursive_symbolize_keys(args)

      g.set_uuid_with_string = symbol_args[:key]
      g.gamecode = symbol_args[:gamecode]

      symbol_args[:kapa].each do |kapa|
        puts "Adding Kapa: #{kapa}"
      end

      symbol_args[:players].each do |player|
        puts "Adding player: #{player}"
      end
    end
  end

  def generate_new_id
    puts "GAME: GENERATE_NEW_ID".blue if DEBUGGING
    # update the UI with the gamecode
    # https://gist.github.com/mbajur/2aba832a6df3fc31fe7a82d3109cb626
    new_id = rand(36**6).to_s(36)
  end

  # TODO do we use this?
  def add_local_player(user)
    puts "GAME ADD_LOCAL_PLAYER".focus

    puts "adding user: #{user}".red if DEBUGGING
    puts user.providerData

    @local_player = Player.new({ref: @ref, user_id: user.uid, given_name: user.displayName, email: user.email})
    puts "new_player: #{@local_player}".red if DEBUGGING

    @local_kaitakaro = Kaitarako.new(@ref,{user_id: user.uid, given_name: user.displayName, email: user.email})
    puts @local_kaitakaro

    @nga_kaitakaro[@local_player.uuid => @local_player]
    puts @nga_kaitakaro

    # Add player to first team?
    nga_kapa[0].add_player_to_kapa(@local_player)
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
    @ref.child("pylons/#{new_pylon.uuID.UUIDString}").setValue(new_pylon.to_hash) # if @firebase_ref

    # ONCE ITS POSTED, THE MODEL SHOULD COLLECT IT
  end

  def create_new_pouwhenua(coord)
    puts "GAME CREATE_NEW_POUWHENUA".blue if DEBUGGING
    new_pouwhenua = Pouwhenua.new(coord)
    @ref.child("pouwhenua/#{new_pouwhenua.uuid_string}").setValue(new_pouwhenua.to_hash)
  end

  def modify_pylon
    puts "GAME: MODIFY PYLON".blue if DEBUGGING

    # FIND PYLON

    # UPDATE PYLON
  end

  def start_observing_pylons
    puts "GAME: START_OBSERVING_PYLONS".blue if DEBUGGING

    @ref.child("pylons").observeEventType(FIRDataEventTypeChildAdded,
      withBlock: proc do |data|
        # Should we turn it into a better-formed hash here?
        App.notification_center.post("PylonNew", data)
    end)
  end

  def start_observing_pouwhenua
    puts "GAME: START_OBSERVING_POUWHENUA".blue if DEBUGGING

    @ref.child("pouwhenua").observeEventType(FIRDataEventTypeChildAdded,
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
    puts @ref

    @ref.child("players").observeEventType(FIRDataEventTypeChildAdded,
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

    @ref.child("teams").observeEventType(FIRDataEventTypeChildAdded,
      withBlock: proc do |data|
        App.notification.center.post("KapaNew", data)
    end)
  end
end

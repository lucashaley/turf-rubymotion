class Game
  attr_accessor :uuID,
                :gamecode,
                :update_handler,
                :pylons,
                :firebase_ref

  DEBUGGING = true

  def initialize
    puts "GAME: INITIALIZE".green if DEBUGGING

    @uuID = NSUUID.UUID
    @gamecode = generate_new_id

    @update_handler = proc do |error, snapshot|
      puts "update_handler: #{snapshot}"
    end
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
        puts "Creating test pylons".red
        new_game.create_new_pylon(CLLocationCoordinate2DMake(37.33350562755614, -122.02849767766669))
        new_game.create_new_pylon(CLLocationCoordinate2DMake(37.33063930240253, -122.03102976399545))
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

  def create_new_pylon(location)
    puts "GAME: CREATE NEW PYLON".blue if DEBUGGING

    # CREATE NEW PYLON OBJECT
    new_pylon = Pylon.initWithHash({:location => location})
    puts "_new_pylon: #{new_pylon}"
    puts "firebase_ref: #{@firebase_ref}"

    # SEND THE NEW PYLON TO FIREBASE
    # TODO this should probably be threaded
    @firebase_ref.child("pylons/#{new_pylon.uuID.UUIDString}").setValue(new_pylon.to_hash) # if @firebase_ref

    # ONCE ITS POSTED, THE MODEL SHOULD COLLECT IT
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
        App.notification_center.post("PylonNew", data)
    end)
  end
end

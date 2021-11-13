class Machine
  attr_accessor :name,
                :fsm,
                :delegate,
                :rootview,
                :db_app,
                :user,
                :player,
                :bounding_box,
                :db_game_ref,
                :db_ref,
                :db,
                :current_view,
                :location_manager

  attr_reader :handleDataResult,
    :game

  DEBUGGING = true

  def initialize
    puts "MACHINE: INITIALIZE".green if DEBUGGING

    @delegate = UIApplication.sharedApplication.delegate
    @rootview = UIApplication.sharedApplication.delegate.window.rootViewController

    @tracking = false
    # @game = Game.new
    # @bounding_box = UIScreen.mainScreen.bounds

    ####################
    # FIREBASE
    FIRApp.configure
    @db_app = FIRApp.defaultApp()
    puts "app:#{@db_app.name}"
    @db = FIRDatabase.databaseForApp(@db_app)
    @db_ref = @db.reference
    @db_game_ref = @db.referenceWithPath('games/test-game-01')

    @handleDataResult = Proc.new do | data |
      # puts "\n----\nhandleDataResult\n----\n"
      # puts "Data: #{data}"
      # data.children.each do |c|
      #   puts "\n#{c.value}"
      # end
      # _test_game = Game.init_from_firebase(data) # what is this doing here
    end

    #####################
    # AUTHENTICATION
    # this was so useful
    # https://www.rubyguides.com/2016/02/ruby-procs-and-lambdas/
    # also
    # http://www.zenruby.info/2016/05/procs-and-lambdas-closures-in-ruby.html
    handleAuthStateChanged = Proc.new do | auth, b |
      puts "handleAuthStateChanged"
      # puts auth
      # puts auth.inspect
      # @fsm.event(:log_in)
    end

    # Not sure if this is even used any more
    handleAuthDataResult = Proc.new do | authResult, error |
      unless error.nil?
        puts error.localizedDescription
        puts error.userInfo
      end
      # puts authResult.user
      @user = authResult.user

      # remember that with objective-c, boolean proprties must have the ?
      puts @user.anonymous?
    end

    ####################
    # FIREBASE AUTH
    @user = nil
    @auth = FIRAuth.authWithApp(@db_app)
    puts "User: #{@auth.currentUser}"
    FIRAuth.auth.addAuthStateDidChangeListener(handleAuthStateChanged)

    ####################
    # STATEMACHINE
    @fsm = StateMachine::Base.new start_state: :splash, verbose: DEBUGGING

    ####################
    # SPLASH SCREEN
    @fsm.when :splash do |state|
      state.on_entry { puts "Machine start splash".pink }
      state.on_exit { puts "Machine end splash".pink }

      state.transition_to :menu,
        after: 10,
        on: :splashToMenu,
        # on: :ready_for_splash,
        action: Proc.new { segue("ToMenu") }
        # action: Proc.new { UIApplication.sharedApplication.delegate.window.rootViewController.performSegueWithIdentifier("ToMenu", sender: self) }
    end

    ####################
    # MENU SCREEN
    @fsm.when :menu do |state|
      state.on_entry { puts "Machine starting menu" }
      state.on_exit { puts "Machine ending menu" }

      state.transition_to :logging_in,
        on: :log_in
    end

    ####################
    # LOGGING IN MODAL
    @fsm.when :logging_in do |state|
      state.on_entry { puts "Machine starting logging_in!" }
      state.on_exit { puts "Machine ending logging_in!" }
    end

    # calling this from the application instead
    # @fsm.start!
  end

  #####################
  # SINGLETON
  def self.instance
    # puts "MACHINE: INSTANCE"
    @instance ||= self.new
  end

  def set_state(state)
    puts ("set_state")
    @fsm.event(state)
  end

  def segue (name)
    @delegate.window.rootViewController.performSegueWithIdentifier(name, sender: self)

    # this doesn't work!
    # @rootview.performSegueWithIdentifier(name, sender: self)
  end

  # def generate_new_id
  #   puts "MACHINE: GENERATE_NEW_ID".blue if DEBUGGING
  #   # update the UI with the gamecode
  #   # https://gist.github.com/mbajur/2aba832a6df3fc31fe7a82d3109cb626
  #   new_id = rand(36**6).to_s(36)
  #   # can also use NSUUID?
  #
  #   # check if it exists already
  #   # puts @db_ref.child("games")
  # end

  def initialize_location_manager
    puts "MACHINE: INITIALIZE_LOCATION_MANAGER".blue if DEBUGGING
    @location_manager ||= CLLocationManager.alloc.init.tap do |lm|
      lm.requestWhenInUseAuthorization

      # constant needs to be capitalized because Ruby
      lm.desiredAccuracy = KCLLocationAccuracyBest
      lm.startUpdatingLocation
      lm.delegate = self
    end
  end

  # https://github.com/HipByte/RubyMotionSamples/blob/a387842594fd0ac9d8560d2dc64eff4d87534093/ios/Locations/app/locations_controller.rb
  def locationManager(manager, didUpdateToLocation:newLocation, fromLocation:oldLocation)
    puts "MACHINE: DIDUPDATETOLOCATION".blue if DEBUGGING
    return unless @tracking
    if MKMapRectContainsPoint(@bounding_box, MKMapPointForCoordinate(newLocation.coordinate))
      @player.machine.event(:enter_bounds)
    else
      @player.machine.event(:exit_bounds)
    end
    locationUpdate(newLocation)
  end

  def locationManager(manager, didFailWithError:error)
    puts "\n\nOOPS LOCATION MANAGER FAIL\n\n"
    App.notification_center.post "PlayerDisappear"
  end

  def locationUpdate(location)
    loc = location.coordinate
    # @player_location = location.coordinate
    @layer.location = location
    # map_view.setCenterCoordinate(loc)
  end

  def set_player(player)
    puts "MACHINE: SET_PLAYER".blue if DEBUGGING
    @player = player
  end

  def create_new_game
    puts "MACHINE: CREATE_NEW_GAME".blue if DEBUGGING
    @game = Game.init_new_game
  end

  def set_game(game)
    puts "MACHINE: SET_GAME".blue if DEBUGGING
    puts "#{game}"
    @game = game
  end

  def create_new_pylon(location)
    puts "MACHINE: CREATE_NEW_PYLON".blue if DEBUGGING
    @game.create_new_pylon(location)
  end
end

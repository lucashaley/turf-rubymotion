# This is the main brain for the app
class Machine
  attr_accessor :fsm,
                :delegate,
                :rootview,
                :db_app,
                :user,
                # :player,
                :bounding_box,
                # :db_game_ref,
                # :db_ref,
                :db,
                :current_view,
                :location_manager,
                :tracking,
                :auth_view_controller,
                :takaro,
                :takaro_fbo,
                :game_duration,
                :local_character,
                :gamecode,
                :is_waiting,
                :is_playing

  DEBUGGING = true

  # rubocop:disable Metrics, Layout/LineLength
  def initialize
    puts 'MACHINE: INITIALIZE'.green if DEBUGGING

    @delegate = UIApplication.sharedApplication.delegate
    @rootview = UIApplication.sharedApplication.delegate.window.rootViewController

    @tracking = false
    @is_playing = false
    @is_waiting = false
    # @game = Game.new
    # @bounding_box = UIScreen.mainScreen.bounds

    # @player = Player.new
    # @player

    ####################
    # FIREBASE
    FIRApp.configure
    @db_app = FIRApp.defaultApp
    puts "Machine App:#{@db_app.name}"
    @db = FIRDatabase.databaseForApp(@db_app)
    # @db.persistenceEnabled = true
    # @db_ref = @db.reference
    # @db_game_ref = @db.referenceWithPath("games/test-game-01")

    # @handle_data_result = proc do |data|
    #   # puts "\n----\nhandleDataResult\n----\n"
    #   # puts "Data: #{data}"
    #   # data.children.each do |c|
    #   #   puts "\n#{c.value}"
    #   # end
    #   # _test_game = Game.init_from_firebase(data) # what is this doing here
    # end

    #####################
    # AUTHENTICATION
    # this was so useful
    # https://www.rubyguides.com/2016/02/ruby-procs-and-lambdas/
    # also
    # http://www.zenruby.info/2016/05/procs-and-lambdas-closures-in-ruby.html
    handle_auth_state_changed = proc do |auth, user|
      puts 'handle_auth_state_changed'.red

      if auth.currentUser
        puts 'User already logged in'.pink
        @user = auth.currentUser
      else
        puts 'No user logged in'.pink
        @user = nil
      end
    end
    ####################
    # FIREBASE AUTH

    @user = nil
    @auth = FIRAuth.authWithApp(@db_app)
    puts "User: #{@auth.currentUser}".red
    FIRAuth.auth.addAuthStateDidChangeListener(handle_auth_state_changed)

    authUI = FUIAuth.defaultAuthUI
    authUI.delegate = self
    puts "Machine AuthUI: #{authUI}".red
    provider_apple = FUIOAuth.appleAuthProvider
    puts "Machine provider: #{provider_apple}".red

    # https://firebaseopensource.com/projects/firebase/firebaseui-ios/auth/readme/
    providers = []
    providers << FUIGoogleAuth.alloc.init
    providers << FUIOAuth.appleAuthProvider
    authUI.providers = providers

    @auth_view_controller = authUI.authViewController
    puts "Machine auth_view_controller: #{auth_view_controller}"

    ####################
    # STATEMACHINE
    @fsm = StateMachine::Base.new start_state: :splash, verbose: DEBUGGING

    ####################
    # SPLASH SCREEN
    @fsm.when :splash do |state|
      state.on_entry { puts 'Machine start splash'.pink }
      state.on_exit { puts 'Machine end splash'.pink }

      state.transition_to :menu,
        after: 10,
        on: :splashToMenu,
        # on: :ready_for_splash,
        action: proc { segue('ToMenu') }
        # action: Proc.new { UIApplication.sharedApplication.delegate.window.rootViewController.performSegueWithIdentifier("ToMenu", sender: self) }
    end

    ####################
    # MENU SCREEN
    @fsm.when :menu do |state|
      state.on_entry { puts 'Machine starting menu' }
      state.on_exit { puts 'Machine ending menu' }

      state.transition_to :logging_in,
        on: :log_in
    end

    ####################
    # LOGGING IN MODAL
    @fsm.when :logging_in do |state|
      state.on_entry { puts 'Machine starting logging_in!' }
      state.on_exit { puts 'Machine ending logging_in!' }
    end

    # calling this from the application instead
    # @fsm.start!
  end
  # rubocop:enable Metrics, Layout/LineLength

  #####################
  # SINGLETON
  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def state=(state)
    puts 'MACHINE SET_STATE'.blue if DEBUGGING
    @fsm.event(state)
  end

  def segue(name)
    puts 'MACHINE SEGUE'.blue if DEBUGGING

    # Can't we just use the current view controller shortcut?
    @delegate.window.rootViewController.performSegueWithIdentifier(name, sender: self)
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

  def authUI(authUI, didSignInWithAuthDataResult: result, error: _error)
    puts 'MACHINE DID_SIGN_IN'.blue if DEBUGGING
    puts 'insane'.red
  end

  def initialize_location_manager
    puts 'MACHINE: INITIALIZE_LOCATION_MANAGER'.blue if DEBUGGING
    @location_manager ||= CLLocationManager.alloc.init.tap do |lm|
      lm.requestWhenInUseAuthorization

      # constant needs to be capitalized because Ruby
      lm.desiredAccuracy = KCLLocationAccuracyBest
      lm.startUpdatingLocation
      lm.delegate = self
    end
  end

  # https://github.com/HipByte/RubyMotionSamples/blob/a387842594fd0ac9d8560d2dc64eff4d87534093/ios/Locations/app/locations_controller.rb
  def locationManager(_manager, didUpdateToLocation: new_location, fromLocation: old_location)
    puts 'MACHINE: DIDUPDATETOLOCATION'.blue if DEBUGGING

    App.notification_center.post(
      'UpdateLocation',
      { 'new_location' => new_location, 'old_location' => old_location }
    )
  end

  def locationManager(_manager, didFailWithError: error)
    puts "\n\nOOPS LOCATION MANAGER FAIL\n\n"
    App.notification_center.post 'PlayerDisappear'
  end

  def check_for_game(gamecode)
    puts 'MACHINE CHECK_FOR_GAME'.blue if DEBUGGING
    puts gamecode.red if DEBUGGING
    games_ref = @db.referenceWithPath('games')
    puts "Games ref: #{games_ref.URL}"
    this_query = games_ref.queryOrderedByChild('gamecode').queryEqualToValue(gamecode).queryLimitedToLast(1)
    # puts this_query.ref.URL
    # puts "_this_query: #{_this_query}"
    this_query.getDataWithCompletionBlock(
      lambda do |_error, snapshot|
        puts "#{snapshot.key}: #{snapshot.value}".red
        next_snapshot = snapshot.children.nextObject # rename this, not a ref
        # game = Game.init_with_hash({key: next_ref.key}.merge(next_ref.value))
        # game.set_ref(next_ref.ref)
        # set_game(game)

        # return true
        return next_snapshot.key
      end
    )
  end

  def check_location_in_taiapa(in_location)
    puts 'MACHINE check_location_in_taiapa'.blue if DEBUGGING
    puts "in_location: #{in_location}"
  end
end

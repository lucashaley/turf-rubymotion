# This is the main brain for the app
class Machine
  attr_accessor :fsm,
                :delegate,
                :rootview,
                :db_app,
                :user,
                :google_user,
                :firebase_user,
                :firebase_displayname,
                :firebase_email,
                :recovery_displayname,
                :bounding_box,
                :db,
                :current_view,
                :location_manager,
                :tracking,
                :auth_view_controller,
                :takaro_fbo,
                :game_duration,
                :local_character,
                :gamecode,
                :is_waiting,
                :is_playing,
                :horizontal_accuracy,
                :app_state_machine,
                :login_machine,
                :location_machine

  DEBUGGING = false
  DESIRED_ACCURACY = 30

  # rubocop:disable Metrics
  def initialize
    mp __method__
    # puts 'MACHINE: INITIALIZE'.green if DEBUGGING

    @delegate = UIApplication.sharedApplication.delegate
    @rootview = UIApplication.sharedApplication.delegate.window.rootViewController

    @tracking = false
    @is_playing = false
    @is_waiting = false

    @login_machine = MachineLogin.new
    @location_machine = MachineLocation.new

    ####################
    # FIREBASE
    FIRApp.configure
    @db_app = FIRApp.defaultApp
    # puts "Machine App:#{@db_app.name}"

    # this connects to the default asia db
    # @db = FIRDatabase.databaseForApp(@db_app)
    # this connects to the US
    @db = FIRDatabase.databaseWithURL('https://turf-us.firebaseio.com')

    #####################
    # AUTHENTICATION
    # this was so useful
    # https://www.rubyguides.com/2016/02/ruby-procs-and-lambdas/
    # also
    # http://www.zenruby.info/2016/05/procs-and-lambdas-closures-in-ruby.html
    handle_auth_state_changed = proc do |auth, user|
      puts 'handle_auth_state_changed'.red
      Utilities::breadcrumb('handle_auth_state_changed')

      if auth.currentUser
        puts 'User already logged in'.pink
        @user = auth.currentUser
        @firebase_user = auth.currentUser
        Notification.center.post 'UserLogIn'
      else
        puts 'No user logged in'.pink
        @user = nil
        Notification.center.post 'UserLogOut'
      end
    end
    ####################
    # FIREBASE AUTH

    @user = nil
    @auth = FIRAuth.authWithApp(@db_app)
    # puts "User: #{@auth.currentUser}".red
    mp @auth
    mp @auth.currentUser
    FIRAuth.auth.addAuthStateDidChangeListener(handle_auth_state_changed)

    @auth_ui = FUIAuth.defaultAuthUI
    @auth_ui.delegate = self
    puts "Machine AuthUI: #{@auth_ui}".red
    provider_apple = FUIOAuth.appleAuthProvider
    puts "Machine provider: #{provider_apple}".red

    # https://firebaseopensource.com/projects/firebase/firebaseui-ios/auth/readme/
    providers = []
    providers << FUIGoogleAuth.alloc.init
    providers << FUIOAuth.appleAuthProvider
    providers << FUIEmailAuth.alloc.init
    # providers << FUIGameCenterAuth.alloc.init
    @auth_ui.providers = providers

    @auth_view_controller = @auth_ui.authViewController
    puts "Machine auth_view_controller: #{auth_view_controller}"

    @app_state_machine = StateMachine::Base.new start_state: :splash, verbose: DEBUGGING
    @app_state_machine.when :splash do |state|
      state.transition_to :main_menu,
                          after: 10,
                          on_notification: :app_splash_to_menu,
                          action: proc { transition_splash_to_main_menu }
    end
    @app_state_machine.when :main_menu do |state|
      state.transition_to :credits,
                          on: :app_main_menu_to_credits,
                          action: proc { transition_main_menu_to_credits }
      state.transition_to :settings,
                          on: :app_main_menu_to_settings,
                          action: proc { transition_main_menu_to_settings }
      state.transition_to :characters,
                          on: :app_main_menu_to_characters,
                          action: proc { transition_main_menu_to_characters }
      state.transition_to :how_to_play,
                          on: :app_main_menu_to_how_to_play,
                          action: proc { transition_main_menu_to_how_to_play }
      state.transition_to :game_options,
                          on: :app_main_menu_to_game_options,
                          action: proc { transition_main_menu_to_game_options }
      state.transition_to :game_join,
                          on: :app_main_menu_to_game_join,
                          action: proc { transition_main_menu_to_game_join }
    end
    @app_state_machine.when :credits do |state|
      state.transition_to :main_menu,
                          on: :dismiss_info_view,
                          action: proc { transition_credits_to_main_menu }
    end
    @app_state_machine.when :settings do |state|
      state.transition_to :main_menu,
                          on: :app_settings_to_main_menu,
                          action: proc { transition_settings_to_main_menu }
    end
    @app_state_machine.when :characters do |state|
      state.transition_to :main_menu,
                          on: :dismiss_info_view,
                          action: proc { transition_characters_to_main_menu }
    end
    @app_state_machine.when :how_to_play do |state|
      state.transition_to :main_menu,
                          on: :dismiss_info_view,
                          action: proc { transition_how_to_play_to_main_menu }
    end
    @app_state_machine.when :game_options do |state|
      state.transition_to :main_menu,
                          on: :app_game_options_to_main_menu,
                          action: proc { transition_game_options_to_main_menu }
      state.transition_to :character_select,
                          on: :app_game_options_to_character_select,
                          action: proc { transition_game_options_to_character_select }
    end
    @app_state_machine.when :game_join do |state|
      state.transition_to :main_menu,
                          on: :app_game_join_to_main_menu,
                          action: proc { transition_game_join_to_main_menu }
      state.transition_to :character_select,
                          on: :app_game_join_to_character_select,
                          action: proc { transition_game_join_to_character_select }
    end
    @app_state_machine.when :character_select do |state|
      state.transition_to :main_menu,
                          on: :app_character_select_to_main_menu,
                          action: proc { transition_character_select_to_main_menu }
      state.transition_to :waiting_room,
                          on: :app_character_select_to_waiting_room,
                          action: proc { transition_character_select_to_waiting_room }
    end
    @app_state_machine.when :waiting_room do |state|
      state.transition_to :main_menu,
                          on: :app_waiting_room_to_main_menu,
                          action: proc { transition_waiting_room_to_main_menu }
      state.transition_to :game,
                          on: :app_waiting_room_to_game,
                          action: proc { transition_waiting_room_to_game }
      state.transition_to :prep,
                          on: :app_waiting_room_to_prep,
                          action: proc { transition_waiting_room_to_prep }
    end
    @app_state_machine.when :prep do |state|
      state.transition_to :game,
                          on: :app_prep_to_game,
                          action: proc { transition_prep_to_game }
    end
    @app_state_machine.start!

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
                          action: proc { segue('ToMenu') }
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

    ####################
    # WAITING ROOM
    @fsm.when :waiting_room do |state|
      state.on_entry { mp 'Machine entering waiting_room!' }
      state.on_exit { mp 'Machine exiting waiting_room!' }
    end

    ####################
    # GAME PLAYING
    @fsm.when :game_playing do |state|
      state.on_entry { mp 'Machine entering game_playing!' }
      state.on_exit { mp 'Machine exiting game_playing!' }
    end

    # calling this from the application instead
    # @fsm.start!
  end
  # rubocop:enable Metrics

  #####################
  # SINGLETON
  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def transition_splash_to_main_menu
    mp __method__
  end

  def transition_main_menu_to_credits
    mp __method__

    segue('to_credits')
  end

  def transition_credits_to_main_menu
    mp __method__

    dismiss_modal
  end

  def transition_main_menu_to_settings
    mp __method__

    segue('to_settings')
  end

  def transition_settings_to_main_menu
    mp __method__

    dismiss_modal
  end

  def transition_main_menu_to_characters
    mp __method__

    segue('to_characters')
  end

  def transition_characters_to_main_menu
    mp __method__

    dismiss_modal
  end

  def transition_main_menu_to_how_to_play
    mp __method__
  end

  def transition_how_to_play_to_main_menu
    mp __method__

    dismiss_modal
  end

  def transition_main_menu_to_log_in
    mp __method__
  end

  def transition_log_in_to_main_menu
    mp __method__
  end

  def transition_main_menu_to_game_options
    mp __method__

    initialize_location_manager
    create_new_game
    @takaro_fbo.host = true

    segue('to_game_options')
  end

  def transition_game_options_to_main_menu
    mp __method__

    destroy_current_game
  end

  def transition_game_options_to_character_select
    mp __method__

    segue('to_character_select')
  end

  def transition_main_menu_to_game_join
    mp __method__

    initialize_location_manager

    segue('to_join_game')
  end

  def transition_game_join_to_main_menu
    mp __method__

    segue('to_main_menu')
  end

  def transition_game_join_to_character_select
    mp __method__

    segue('to_character_select')
  end

  def transition_character_select_to_main_menu
    mp __method__

    destroy_current_game
    segue('to_main_menu')
  end

  def transition_character_select_to_waiting_room
    mp __method__

    # initialize the local character
    @takaro_fbo.initialize_local_player(@local_character)

    # set the game state
    @takaro_fbo.game_state = 'waiting_room'
    segue('to_waiting_room')
  end

  def transition_waiting_room_to_main_menu
    mp __method__

    destroy_current_game
    segue('to_main_menu')
  end

  def transition_waiting_room_to_prep
    mp __method__

    game.game_state = 'prep'
  end

  def transition_prep_to_game
    mp __method__

    segue('to_game')
  end

  def transition_waiting_room_to_game
    mp __method__

    # game.game_state = 'prep'

    # game.set_initial_markers # this should be on the server
    segue('to_game')
  end

  def transition_game_to_main_menu
    mp __method__
  end

  def transition_game_to_game_over
    mp __method__
  end

  def transition_game_over_to_main_menu
    mp __method__
  end

  def state=(state)
    mp __method__
    mp "Setting state to #{state}"
    Bugsnag.leaveBreadcrumbWithMessage("Setting state to #{state}")

    @fsm.event(state)
  end

  def segue(name)
    mp __method__

    Bugsnag.leaveBreadcrumbWithMessage("Performing segue: #{name}")

    # Can't we just use the current view controller shortcut?
    @delegate.window.rootViewController.performSegueWithIdentifier(name, sender: self)
  end

  def game
    mp __method__ # this will be nonsense
    @takaro_fbo
  end

  def dismiss_modal
    @current_view.presentingViewController.dismissViewControllerAnimated(true, completion: nil)
  end

  def authUI(authUI, didSignInWithAuthDataResult: result, error: error)
    puts 'MACHINE DID_SIGN_IN'.blue if DEBUGGING
    puts 'insane'.red
    Bugsnag.notifyError(error)
  end

  def initialize_location_manager
    puts 'MACHINE: INITIALIZE_LOCATION_MANAGER'.blue if DEBUGGING
    @location_manager ||= CLLocationManager.alloc.init.tap do |lm|
      lm.requestWhenInUseAuthorization

      # constant needs to be capitalized because Ruby
      lm.desiredAccuracy = KCLLocationAccuracyBestForNavigation
      # lm.desiredAccuracy = KCLLocationAccuracyBest
      lm.distanceFilter = 2
      lm.startUpdatingLocation
      lm.delegate = self
    end
  end

  # https://github.com/HipByte/RubyMotionSamples/blob/a387842594fd0ac9d8560d2dc64eff4d87534093/ios/Locations/app/locations_controller.rb
  def locationManager(_manager, didUpdateToLocation: new_location, fromLocation: old_location)
    puts 'MACHINE: DIDUPDATETOLOCATION'.blue if DEBUGGING

    @horizontal_accuracy = new_location.horizontalAccuracy
    accurate = @horizontal_accuracy <= DESIRED_ACCURACY
    # Check for reasonable accuracy
    # https://stackoverflow.com/a/13502503
    puts "horizontalAccuracy: #{new_location.horizontalAccuracy}".focus

    Notification.center.post(
      'accuracy_change',
      { 'accurate' => accurate }
    )

    return unless accurate

    Notification.center.post(
      'UpdateLocation',
      { 'new_location' => new_location, 'old_location' => old_location }
    )
  end

  def locationManager(_manager, didFailWithError: error)
    puts "\n\nOOPS LOCATION MANAGER FAIL\n\n"
    Notification.center.post 'PlayerDisappear'
    # Bugsnag.notifyError(error)
  end

  def initialize_character_classes
      characters_ref = @db.referenceWithPath('characters')

  end

  def check_for_game(gamecode)
    mp __method__

    puts gamecode.red if DEBUGGING
    games_ref = @db.referenceWithPath('games')
    puts "Games ref: #{games_ref.URL}"
    this_query = games_ref.queryOrderedByChild('gamecode').queryEqualToValue(gamecode).queryLimitedToLast(1)
    # puts this_query.ref.URL
    # puts "_this_query: #{_this_query}"
    this_query.getDataWithCompletionBlock(
      lambda do |error, snapshot|
        Bugsnag.notifyError(error) unless error.nil?

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

  def create_new_game
    mp __method__

    Utilities::breadcrumb('create_new_game')

    begin
      @takaro_fbo = TakaroFbo.new(
        @db.referenceWithPath('games').childByAutoId,
        { 'gamecode' => generate_gamecode }
      )
    rescue Exception => e
      Bugsnag.notify(e)
    end
  end

  def generate_gamecode
    mp __method__

    result = rand(36**6).to_s(36)
    if result.length < 6
      result = generate_gamecode
    end

    result
  end

  def destroy_current_game
    mp __method__

    @takaro_fbo = nil
  end
end

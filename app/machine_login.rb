class MachineLogin
  attr_accessor :auth_state_machine,
                :auth,
                :auth_ui,
                :auth_view_controller,
                :user,
                :display_name

  DEBUGGING = true

  def initialize
    mp __method__

    @auth_state_machine = StateMachine::Base.new start_state: :initializing, verbose: DEBUGGING
    @auth_state_machine.when :initializing do |state|
      state.on_entry { initialize_firebase_auth }
      state.transition_to :ready,
                          on: :auth_finished_initializing,
    end
    @auth_state_machine.when :ready do |state|
      # state.transition_to :menu,
      #                     after: 10,
      #                     on_notification: :app_splash_to_menu,
      #                     action: proc { transition_splash_to_main_menu }
    end

    @auth_state_machine.start!
  end

  def initialize_firebase_auth
    mp __method__

#     begin
#       @user = nil
#       @auth = FIRAuth.authWithApp(Machine.instance.db_app)
#
#       puts "User: #{@auth.currentUser}".red
#       FIRAuth.auth.addAuthStateDidChangeListener(
#         lambda do | a, u |
#           mp a
#           mp u
#         end.weak!
#       )
#
#       @auth_ui = FUIAuth.defaultAuthUI
#       @auth_ui.delegate = self
#
#       # https://firebaseopensource.com/projects/firebase/firebaseui-ios/auth/readme/
#       providers = []
#       providers << FUIGoogleAuth.alloc.init
#       providers << FUIOAuth.appleAuthProvider
#       providers << FUIEmailAuth.alloc.init
#       # providers << FUIGameCenterAuth.alloc.init
#       @auth_ui.providers = providers
#
#       @auth_view_controller = @auth_ui.authViewController
#       puts "Machine auth_view_controller: #{auth_view_controller}"
#     rescue Exception => e
#       mp e
#     end
  end

  def auth_state_changed
    mp __method__

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
end

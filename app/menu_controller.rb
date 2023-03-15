class MenuController < MachineViewController
  DEBUGGING = true

  outlet :button_login, UIButton
  outlet :button_logout, UIButton
  outlet :button_settings, UIButton
  outlet :button_characters, UIButton
  outlet :button_game_new, UIButton
  outlet :button_game_join, UIButton

  def viewDidLoad
    super
    puts "MENUCONTROLLER VIEWDIDLOAD".blue if DEBUGGING

    # # better way to check using GID?
    # if Machine.instance.google_user
    #   button_login.hidden = true
    #   button_logout.hidden = false
    #   button_game_new.enabled = true
    #   button_game_join.enabled = true
    # else
    #   button_login.hidden = false
    #   button_logout.hidden = true
    #   button_game_new.enabled = false
    #   button_game_join.enabled = false
    # end

    Notification.center.observe 'UserLogIn' do |notification|
      mp 'menu_controller UserLogIn'
      button_login.hidden = true
      button_logout.hidden = false
      button_game_new.enabled = true
      button_game_join.enabled = true
    end
    Notification.center.observe 'UserLogOut' do |notification|
      mp 'menu_controller UserLogOut'
      button_login.hidden = false
      button_logout.hidden = true
      button_game_new.enabled = false
      button_game_join.enabled = false
    end
  end

  def viewWillAppear(_animated)
    if Machine.instance.firebase_user
      button_login.hidden = true
      button_logout.hidden = false
      button_game_new.enabled = true
      button_game_join.enabled = true
    else
      button_login.hidden = false
      button_logout.hidden = true
      button_game_new.enabled = false
      button_game_join.enabled = false
    end
  end

  def controlTouched(sender)
    puts "touched".pink
  end

  def action_login(sender)
    puts "MENUCONTROLLER ACTION_LOGIN".blue if DEBUGGING

    # this doesn't seem to work any more 4/6/22
    # Machine.instance.state(:log_in)

    # # Stuff for FirebaseAuthUI
    # # Never got this to work
    # presentViewController(Machine.instance.auth_view_controller, animated: true, completion: nil)

    # Old google-only way
    config = GIDConfiguration.alloc.initWithClientID(FIRApp.defaultApp.options.clientID)
    puts "config: #{config.clientID}"

    # This signs in anew every time.
    # It would be good to check if they're already logged in.
    GIDSignIn.sharedInstance.signInWithConfiguration(
      config,
      presentingViewController: self,
      callback: lambda do |user, error|
        puts "LOGINCONTROLLER GIDSIGNIN".blue if DEBUGGING
        unless error.nil?
          puts error.localizedDescription
          puts error.userInfo
          return
        end
        puts "User: #{user.userID}".red if DEBUGGING
        authentication = user.authentication
        credential = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken,
                             accessToken: authentication.accessToken)

        Dispatch::Queue.new("turf-test-db").async do
          FIRAuth.auth.signInWithCredential(credential, completion: lambda do |authResult, error|
            puts user.profile.name
            Machine.instance.google_user = user
            button_login.hidden = true
            button_logout.hidden = false
            button_game_new.enabled = true
            button_game_join.enabled = true
            # dismiss_modal
          end)
        end
      end
    )
  end

  def action_logout(sender)
    puts "MENUCONTROLLER ACTION_LOGOUT".blue if DEBUGGING
    GIDSignIn.sharedInstance.signOut
    Machine.instance.google_user = nil
    Machine.instance.firebase_user = nil
    button_login.hidden = false
    button_logout.hidden = true
    button_game_new.enabled = false
    button_game_join.enabled = false
  end

  def action_test(sender)
    presentViewController(Machine.instance.auth_view_controller, animated: true, completion: nil)
  end

  def action_settings(sender)
    # TODO
  end

  def action_characters(sender)
    # TODO
  end

  def action_game_new(sender)
    puts "MENUCONTROLLER ACTION_GAME_NEW".blue if DEBUGGING
    Notification.center.post('app_main_menu_to_options')
  end

  def action_game_join(sender)
    puts "MENUCONTROLLER ACTION_GAME_JOIN".blue if DEBUGGING
  end

  def login
    mp 'menu_controller login'
    button_login.hidden = true
    button_logout.hidden = false
    button_game_new.enabled = true
    button_game_join.enabled = true
  end

  def logout
    mp 'menu_controller logout'
    button_login.hidden = false
    button_logout.hidden = true
    button_game_new.enabled = false
    button_game_join.enabled = false
  end

  def action_dismiss_login(segue)
    mp 'menu_controller action_dismiss_login'
  end
end

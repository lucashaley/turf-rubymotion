class MenuController < MachineViewController
  DEBUGGING = true

  outlet :button_login, UIButton
  outlet :button_settings, UIButton
  outlet :button_characters, UIButton
  outlet :button_game_new, UIButton
  outlet :button_game_join, UIButton

  def viewDidLoad
    super
    puts "MENUCONTROLLER VIEWDIDLOAD".blue if DEBUGGING
    if Machine.instance.user
      puts Machine.instance.user.email
      button_login.setTitle("Logout", forState: UIControlStateNormal)
    else
      button_login.setTitle("Login", forState: UIControlStateNormal)
    end
  end

  def controlTouched(sender)
    puts "touched".pink
  end

  def action_login(sender)
    puts "MENUCONTROLLER ACTION_LOGIN".blue if DEBUGGING
    Machine.instance.set_state(:log_in)

    # # Stuff for FirebaseAuthUI
    # # Never got this to work
    # presentViewController(Machine.instance.auth_view_controller, animated: true, completion: nil)

    # Old google-only way
    config = GIDConfiguration.alloc.initWithClientID(FIRApp.defaultApp.options.clientID)
    puts "config: #{config.clientID}"

    # This signs in anew every time.
    # It would be good to check if they're already logged in.
    GIDSignIn.sharedInstance.signInWithConfiguration(config,
      presentingViewController: self,
      callback: lambda do |user, error|
        puts "LOGINCONTROLLER GIDSIGNIN".blue if DEBUGGING
        unless error.nil?
          puts error.localizedDescription
          puts error.userInfo
        end
        puts "User: #{user.userID}".red if DEBUGGING
        authentication = user.authentication
        credential = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken,
                             accessToken: authentication.accessToken)

        Dispatch::Queue.new("turf-test-db").async do
          FIRAuth.auth.signInWithCredential(credential, completion: lambda do |authResult, error|
            puts user.profile.name
            Machine.instance.user = user
            # dismiss_modal
          end)
        end
      end
    )
  end

  # # Stuff for FirebaseAuthUI
  # # Never got this to work
  # def authUI(authUI, didSignInWithAuthDataResult: result, error: error)
  #   puts "MENUCONTROLLER DID_SIGN_IN".blue if DEBUGGING
  #   puts "insane".red
  # end

  def action_settings(sender)
    # TODO
  end

  def action_characters(sender)
    # TODO
  end

  def action_game_new(sender)
    puts "MENUCONTROLLER ACTION_GAME_NEW".blue if DEBUGGING
  end

  def action_game_join(sender)
    puts "MENUCONTROLLER ACTION_GAME_JOIN".blue if DEBUGGING
  end
end

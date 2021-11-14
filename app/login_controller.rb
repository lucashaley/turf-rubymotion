class LoginController < UIViewController
  # https://code.tutsplus.com/tutorials/lets-write-a-rubymotion-app-part-1--cms-20612
  extend IB

  DEBUGGING = true

  # @handleSignedIn = Proc.new do | user, error |
  #   puts 'handleSignedIn'
  #   unless error.nil?
  #     puts error.localizedDescription
  #     puts error.userInfo
  #   end
  #   puts 'User: ' + user.userID
  #   Machine.instance.user = user
  # end

  def viewDidAppear(animated)
    super

    puts "viewDidAppear"

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
                    dismiss_modal
                  end)
                end
              end
    )

    # performSegueWithIdentifier("LoginToMenu", sender: nil)
  end

  def dismiss_modal
    self.presentingViewController.dismissViewControllerAnimated(true, completion: nil)
  end
end

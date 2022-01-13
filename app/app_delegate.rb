class AppDelegate
  attr_accessor :window

  def application(application, didFinishLaunchingWithOptions: launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    storyboard = UIStoryboard.storyboardWithName("main", bundle: nil)
    @window.rootViewController = storyboard.instantiateInitialViewController

    @window.makeKeyAndVisible

    # Testing JavaScriptCore
    puts "Testing JavaScriptCore"
    js_context = JSContext.alloc.init
    puts js_context
    giga_value = js_context.evaluateScript("Math.pow(2,30)")
    puts giga_value.toNumber

    # Start the StateMachine
    Machine.instance.fsm.start!

    true
  end

  # # Stuff for FirebaseAuthUI
  # def application(application, openURL: url, options: options)
  #   puts 'APPDELEGATE application:openURL'.blue
  #   return GIDSignIn.sharedInstance.handleUrl url
  # end
  #
  # def authUI(authUI, didSignInWithAuthDataResult: result, error: error)
  #   puts 'APPDELEGATE authUI:didSignIn'.blue
  # end
end

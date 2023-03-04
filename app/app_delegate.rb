class AppDelegate
  attr_accessor :window

  def application(application, didFinishLaunchingWithOptions: launchOptions)
    puts "\n" * 16
    puts 'STARTING APPLICATION'
    puts "\n" * 16
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    storyboard = UIStoryboard.storyboardWithName("main", bundle: nil)
    @window.rootViewController = storyboard.instantiateInitialViewController

    @window.makeKeyAndVisible

    # Trying Logger
    # $logger = Motion::Lager.new(level: 'debug') # default

    # Trying BugSnag
    Bugsnag.start
    # Bugsnag.notifyError(NSError.errorWithDomain('com.animatology'), code:408, userInfo:nil)

    # Testing JavaScriptCore
#     puts "Testing JavaScriptCore"
#     js_context = JSContext.alloc.init
#     puts js_context
#     # giga_value = js_context.evaluateScript("Math.pow(2,30)")
#     # puts giga_value.toNumber
#     js_file_path = NSBundle.mainBundle.pathForResource("d3-delaunay", ofType:"js")
#     js_url = NSBundle.mainBundle.URLForResource("d3-delaunay", withExtension:"js")
#     puts js_url.absoluteURL
#     error_ptr = Pointer.new(:object)
#     js_script = NSString.alloc.initWithContentsOfFile(js_file_path, encoding:NSUTF8StringEncoding, error:error_ptr)
#
#     js_context.evaluateScript(js_script, withSourceURL: js_url)
#     puts js_context["Delaunay"].constructWithArguments([[0, 0], [0, 1], [1, 0], [1, 1]])

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

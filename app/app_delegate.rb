class AppDelegate
  attr_accessor :window

  def application(application, didFinishLaunchingWithOptions: launchOptions)
    debug_start_app
    initialize_bugsnag
    
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    storyboard = UIStoryboard.storyboardWithName("main", bundle: nil)
    @window.rootViewController = storyboard.instantiateInitialViewController

    @window.makeKeyAndVisible

    # Start the StateMachine
    Machine.instance.fsm.start!

    true
  end
  
  def debug_start_app
    # puts "\n" * 16
    # puts 'STARTING APPLICATION'
    # puts "\n" * 16
    
    mp "\n" * 8
    mp 'Starting application'
    mp "\n" * 8
  end
  
  def initialize_bugsnag
    mp __method__
    begin
      Bugsnag.start
      Bugsnag.leaveBreadcrumbWithMessage('Bugsnag started.')
    rescue Exception => exception
      mp 'something went wrong with Bugsnag'
      mp exception.reason
      mp exception.callStackSymbols
    end
  end
end

class AppDelegate
  attr_accessor :window

  def application(application, didFinishLaunchingWithOptions: launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    storyboard = UIStoryboard.storyboardWithName("main", bundle: nil)
    @window.rootViewController = storyboard.instantiateInitialViewController

    @window.makeKeyAndVisible

    # Start the StateMachine
    Machine.instance.fsm.start!

    true
  end
end

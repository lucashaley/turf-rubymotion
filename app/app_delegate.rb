class AppDelegate
  attr_accessor :window

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    storyboard = UIStoryboard.storyboardWithName("main", bundle: nil)
    @window.rootViewController = storyboard.instantiateInitialViewController

    @window.makeKeyAndVisible

    # Start the StateMachine
    Machine.instance.fsm.start!

    # @g = Dispatch::Group.new("pants")
    # @v = Vector::Vector[1,3,6,10]
    # @v.barf
    puts Math::PI

    true
  end
end

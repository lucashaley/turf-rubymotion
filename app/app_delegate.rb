class AppDelegate
  attr_accessor :window

  def to_menu
    puts ("to_menu")
    Machine.instance.fsm.event(:splashToMenu)
  end

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    storyboard = UIStoryboard.storyboardWithName("main", bundle: nil)
    @window.rootViewController = storyboard.instantiateInitialViewController

    @window.makeKeyAndVisible

    Machine.instance.fsm.start!

    # FIRApp.configure
    # puts FIRApp
    # app = FIRApp.defaultApp()
    # puts app.name

    # this needs somewhere to go
    # auth = FIRAuth.authWithApp(app)
    # puts auth.currentUser()

    @user
    @db
    @db_ref

    # this was so useful
    # https://www.rubyguides.com/2016/02/ruby-procs-and-lambdas/
    # also
    # http://www.zenruby.info/2016/05/procs-and-lambdas-closures-in-ruby.html
    handleAuthStateChanged = Proc.new do | auth, b |
      # puts auth
      # puts auth.inspect
    end

    handleAuthDataResult = Proc.new do | authResult, error |
      unless error.nil?
        puts error.localizedDescription
        puts error.userInfo
      end
      # puts authResult.user
      @user = authResult.user

      # remember that with objective-c, boolean proprties must have the ?
      puts @user.anonymous?
    end



    FIRAuth.auth.addAuthStateDidChangeListener(handleAuthStateChanged)
    # FIRAuth.auth.createUserWithEmail("lucashaley@yahoo.com", "bembitos", handleAuthDataResult)
    # auth.signInAnonymouslyWithCompletion(handleAuthDataResult)
    # @q = Dispatch::Queue.new("magic")
    # @q.suspend!
    # @q.sync do
    #   auth.signInAnonymouslyWithCompletion(handleAuthDataResult)
    # end
    # @q.sync do
    #   @db = FIRDatabase.databaseForApp(app)
    #   @db_ref = @db.reference
    # end
    # @q.sync do
    #   @db_ref.child(@user).setValue("test")
    # end
    # @q.resume!
    # auth.createUserWithEmail("lucashaley@yahoo.com", "bembitos", handleAuthDataResult)

    # @db = FIRDatabase.databaseForApp(app)
    # @db_ref = @db.reference
    #
    # @db_ref.child("magic").setValue("pants")
    # @db_ref.child(@user).setValue("test")


    @g = Dispatch::Group.new("pants")


    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    # @window.rootViewController = navigationController
    # @window.rootViewController = LoginViewController.alloc.init
    # @window.rootViewController.wantsFullScreenLayout = true


    storyboard = UIStoryboard.storyboardWithName("main", bundle: nil)
    @window.rootViewController = storyboard.instantiateInitialViewController
    @window.makeKeyAndVisible

    true
  end
end

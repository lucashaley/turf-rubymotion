class AppDelegate
  $splash_timeout = 10 # splash timeout in seconds
  $stateMachine = StateMachine::Base.new start_state: :splash, verbose: true
  $stateMachine.when :splash do |state|
    state.on_entry { puts "splash enter" }
    state.on_exit { puts "splash exit" }
    state.transition_to :testing,
      on: :splashToMenu,
      action: @timeout_splash
  end
  $stateMachine.when :testing do |state|
    state.on_entry { puts "testing entry" }
    state.on_exit { puts "testing exit" }
  end

  def to_menu
    puts ("to_menu")
    $stateMachine.event(:splashToMenu)
  end

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    # rootViewController = UIViewController.alloc.init
    # rootViewController.title = 'Test_RubyMotionFirebase_01'
    # rootViewController.view.backgroundColor = UIColor.whiteColor
    #
    # navigationController = UINavigationController.alloc.initWithRootViewController(rootViewController)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    # @window.rootViewController = navigationController
    # @window.rootViewController = LoginViewController.alloc.init
    # @window.rootViewController.wantsFullScreenLayout = true


    storyboard = UIStoryboard.storyboardWithName("main", bundle: nil)
    @window.rootViewController = storyboard.instantiateInitialViewController

    # @window.rootViewController = SplashController.alloc.init
    @window.makeKeyAndVisible

    # segueTemplates = @window.rootViewController.visibleViewController.valueForKey("storyboardSegueTemplates")
    # sel = NSSelectorFromString("storyboardSegueTemplates")
    # segueTemplates = @window.rootViewController.performSelector(sel)
    # puts 'segueTemplates'
    # puts segueTemplates

    @load_splash = Proc.new {
      puts "loading splash yoooo"
      # segue = UIStoryboardSegue.initWithIdentifier("splashscreen", source: splash_controller, destination: login_controller)
      @window.rootViewController.performSegueWithIdentifier("TestSegue", sender: self)
    }

    @timeout_splash = Proc.new {
      puts "timeout splash"
      @window.rootViewController.performSegueWithIdentifier("ToMenu", sender: self)
    }

    # https://github.com/opyh/motion-state-machine
    fsm = StateMachine::Base.new start_state: :splash, verbose: true
    fsm.when :awake do |state|

      state.on_entry { puts "I'm awake, started and alive!" }
      state.on_exit { puts "Phew. That was enough work." }

      # state.transition_to :sleeping,
      #   on:      :finished_hard_work,
      #   if:      proc { #check for validity here
      #     true
      #    },
      #   action:  proc { puts "Will go to sleep now." }

      state.transition_to :logging_in,
        on: :ready_to_log_in,
        if: proc { true },
        action: proc { puts "logging in…" }

      state.die on: :too_hard_work
    end

    fsm.when :splash do |state|
      state.on_entry { puts "starting splash" }
      state.on_exit { puts "ending splash" }

      state.transition_to :menu,
        after: $splash_timeout,
        on: :splashToMenu,
        # on: :ready_for_splash,
        action: @timeout_splash
    end

    fsm.when :menu do |state|
      state.on_entry {
        puts "starting menu"
      }
      state.on_exit {
        puts "ending menu"
      }
    end

    fsm.when :logging_in do |state|
      state.on_entry {
        puts "starting logging_in!"
      }
      state.on_exit {
        puts "ending logging_in!"
      }
    end

    # fsm.start!

    Machine.instance.name = "test"
    puts Machine.instance.name
    puts Machine.instance.fsm
    puts Machine.instance.delegate

    # fsm.event(:ready_for_splash)

    FIRApp.configure
    puts FIRApp
    app = FIRApp.defaultApp()
    puts app.name
    auth = FIRAuth.authWithApp(app)

    puts auth.currentUser()

    @user
    @db
    @db_ref

    # this was so useful
    # https://www.rubyguides.com/2016/02/ruby-procs-and-lambdas/
    # also
    # http://www.zenruby.info/2016/05/procs-and-lambdas-closures-in-ruby.html
    handleAuthStateChanged = Proc.new do | auth, b |
      puts auth
      puts auth.inspect
    end

    handleAuthDataResult = Proc.new do | authResult, error |
      unless error.nil?
        puts error.localizedDescription
        puts error.userInfo
      end
      puts authResult.user
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

    @db = FIRDatabase.databaseForApp(app)
    @db_ref = @db.reference

    @db_ref.child("magic").setValue("pants")
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

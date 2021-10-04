class Machine
  attr_accessor :name,
                :fsm,
                :delegate,
                :rootview,
                :db_app,
                :user,
                :player,
                :game

  def initialize
    @delegate = UIApplication.sharedApplication.delegate
    @rootview = UIApplication.sharedApplication.delegate.window.rootViewController
    @game = Game.new

    ####################
    # FIREBASE
    FIRApp.configure
    @db_app = FIRApp.defaultApp()
    @db = FIRDatabase.databaseForApp(@db_app)
    @db_ref = @db.reference

    #####################
    # AUTHENTICATION
    # this was so useful
    # https://www.rubyguides.com/2016/02/ruby-procs-and-lambdas/
    # also
    # http://www.zenruby.info/2016/05/procs-and-lambdas-closures-in-ruby.html
    handleAuthStateChanged = Proc.new do | auth, b |
      puts "handleAuthStateChanged"
      # puts auth
      # puts auth.inspect
    end

    # Not sure if this is even used any more
    # handleAuthDataResult = Proc.new do | authResult, error |
    #   unless error.nil?
    #     puts error.localizedDescription
    #     puts error.userInfo
    #   end
    #   # puts authResult.user
    #   @user = authResult.user
    #
    #   # remember that with objective-c, boolean proprties must have the ?
    #   puts @user.anonymous?
    # end

    ####################
    # FIREBASE AUTH
    @user = nil
    @auth = FIRAuth.authWithApp(@db_app)
    FIRAuth.auth.addAuthStateDidChangeListener(handleAuthStateChanged)

    ####################
    # STATEMACHINE
    @fsm = StateMachine::Base.new start_state: :splash, verbose: true

    ####################
    # SPLASH SCREEN
    @fsm.when :splash do |state|
      state.on_entry { puts "Machine start splash" }
      state.on_exit { puts "Machine end splash" }

      state.transition_to :menu,
        after: 10,
        on: :splashToMenu,
        # on: :ready_for_splash,
        action: Proc.new { segue("ToMenu") }
        # action: Proc.new { UIApplication.sharedApplication.delegate.window.rootViewController.performSegueWithIdentifier("ToMenu", sender: self) }
    end

    ####################
    # MENU SCREEN
    @fsm.when :menu do |state|
      state.on_entry { puts "Machine starting menu" }
      state.on_exit { puts "Machine ending menu" }

      state.transition_to :logging_in,
        on: :log_in
    end

    ####################
    # LOGGING IN MODAL
    @fsm.when :logging_in do |state|
      state.on_entry { puts "Machine starting logging_in!" }
      state.on_exit { puts "Machine ending logging_in!" }
    end

    # calling this from the application instead
    # @fsm.start!
  end

  #####################
  # SINGLETON
  def self.instance
    @instance ||= self.new
  end

  def set_state(state)
    puts ("set_state")
    @fsm.event(state)
  end

  def segue (name)
    @delegate.window.rootViewController.performSegueWithIdentifier(name, sender: self)

    # this doesn't work!
    # @rootview.performSegueWithIdentifier(name, sender: self)
  end

  def generate_new_id
    puts "Machine generate_new_id"
    # update the UI with the gamecode
    # https://gist.github.com/mbajur/2aba832a6df3fc31fe7a82d3109cb626
    new_id = rand(36**6).to_s(36)

    # check if it exists already
    # puts @db_ref.child("games")
  end

  def set_player(player)
    puts "set_player: #{player}"
    @player = player
  end
end

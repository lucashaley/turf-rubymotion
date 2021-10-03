class Machine
  attr_accessor :name,
                :fsm,
                :delegate,
                :rootview,
                :db_app,
                :user

  def initialize
    @delegate = UIApplication.sharedApplication.delegate
    @rootview = UIApplication.sharedApplication.delegate.window.rootViewController

    # Firebase
    FIRApp.configure
    # puts FIRApp
    @db_app = FIRApp.defaultApp()
    # puts @db_app.name

    @db = FIRDatabase.databaseForApp(@db_app)
    @db_ref = @db.reference

    @db_ref.child("smegma").setValue("taste")

    ####################
    # FIREBASE AUTH
    @user = nil
    @auth = FIRAuth.authWithApp(@db_app)



    # StateMachine
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
end

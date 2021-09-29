class Machine
  attr_accessor :name, :fsm, :delegate

  def initialize
    @delegate = UIApplication.sharedApplication.delegate
    @fsm = StateMachine::Base.new start_state: :splash, verbose: true

    @fsm.when :splash do |state|
      state.on_entry { puts "Machine start splash" }
      state.on_exit { puts "Machine end splash" }

      state.transition_to :menu,
        after: $splash_timeout,
        on: :splashToMenu,
        # on: :ready_for_splash,
        action: @timeout_splash
    end

    @fsm.when :menu do |state|
      state.on_entry {
        puts "Machine starting menu"
      }
      state.on_exit {
        puts "Machine ending menu"
      }
    end

    @fsm.when :logging_in do |state|
      state.on_entry {
        puts "Machine starting logging_in!"
      }
      state.on_exit {
        puts "Machine ending logging_in!"
      }
    end

    @fsm.start!
  end
  def self.instance
    @instance ||= self.new
  end
  # def name(value)
  #   @name = value
  # end
  # def name
  #   @name
  # end

  @load_splash = Proc.new {
    puts "Machine loading splash yoooo"
    # segue = UIStoryboardSegue.initWithIdentifier("splashscreen", source: splash_controller, destination: login_controller)
    @delegate.rootViewController.performSegueWithIdentifier("TestSegue", sender: self)
  }

  @timeout_splash = Proc.new {
    puts "Machine timeout splash"
    @delegate.rootViewController.performSegueWithIdentifier("ToMenu", sender: self)
  }
end

class GameCountdownController < MachineViewController
  def viewDidLoad
    super

    machine = StateMachine::Base.new start_state: :waiting, verbose: DEBUGGING
    machine.when :waiting do |state|
      state.on_entry { puts 'Countdown state waiting'.pink }
      state.transition_to :starting,
                          after: 5
    end
    machine.when :starting do |state|
      state.on_entry do
        puts 'STARTING'.focus
        performSegueWithIdentifier('ToGame', sender: self)
      end
    end
    machine.start!
  end
end

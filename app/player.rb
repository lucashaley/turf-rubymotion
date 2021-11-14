class Player
  attr_reader :machine
  attr_accessor :location

  DEBUGGING = true

  def initialize
    puts "PLAYER INITIALIZE".green if DEBUGGING
    @machine = StateMachine::Base.new start_state: :inactive, verbose: true

    @machine.when :inactive do |state|
      state.on_entry { puts "Player inactive enter" }
      state.transition_to :active,
        on: :activate
    end
    @machine.when :active do |state|
      state.on_entry { puts "Player active enter" }
      state.transition_to :inactive,
        on: :deactivate
      state.transition_to :out_bounds,
        on: :exit_bounds,
        action: proc { App.notification_center.post "BoundaryExit" }
    end
    @machine.when :out_bounds do |state|
      state.on_entry { puts "Player out_bounds enter" }
      state.transition_to :active,
        on: :enter_bounds,
        action: proc { App.notification_center.post "BoundaryEnter" }
    end

    @machine.start!
    @machine.event(:activate)
  end
end

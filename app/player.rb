class Player
  attr_reader :machine
  attr_accessor :location

  def initialize
    @machine = StateMachine::Base.new start_state: :inactive, verbose: true

    @machine.when :inactive do |state|
      state.on_entry { puts "Player inactive enter" }
      state.on_exit { puts "Player inactive exit" }
    end

    @machine.start!
  end
end

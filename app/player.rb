class Player
  attr_accessor :machine,
                :location,
                :uuid,
                :user_id,
                :display_name,
                :team_uuid

  DEBUGGING = true

  def initialize(args = {})
    puts "PLAYER INITIALIZE".green if DEBUGGING
    puts "Player args: #{args}".red if DEBUGGING

    @uuid = NSUUID.UUID
    @user_id = args[:user_id] || "ABC123"
    @display_name = args[:given_name] || "Hemi"

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

  def to_hash
    output = {user_id: @user_id, display_name: @display_name}

    return output
  end
end

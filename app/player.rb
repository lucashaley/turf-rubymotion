class Player < FirebaseObject
  attr_accessor :machine,
                :location,
                :uuid, # remove this? in the super now?
                :user_id,
                :display_name,
                :team_uuid,
                :role,
                :refresh,
                :pouwhenua_count

  DEBUGGING = true
  FIREBASE_CLASSPATH = "players"

  def initialize(args = {})
    puts args
    new_ref = args[:ref].child(FIREBASE_CLASSPATH)
    super(new_ref).tap do |p|
      puts "PLAYER INITIALIZE".green if DEBUGGING
      puts "Player args: #{args}".red if DEBUGGING

      p.user_id = args[:user_id] || "ABC123"
      p.display_name = args[:given_name] || "Hemi"
      p.location = args[:location] || CLLocationCoordinate2DMake(37.33189332651307, -122.03128724123847)

      p.machine = StateMachine::Base.new start_state: :inactive, verbose: true

      p.machine.when :inactive do |state|
        state.on_entry { puts "Player inactive enter" }
        state.transition_to :active,
          on: :activate
      end
      p.machine.when :active do |state|
        state.on_entry { puts "Player active enter" }
        state.transition_to :inactive,
          on: :deactivate
        state.transition_to :out_bounds,
          on: :exit_bounds,
          action: proc { App.notification_center.post "BoundaryExit" }
      end
      p.machine.when :out_bounds do |state|
        state.on_entry { puts "Player out_bounds enter" }
        state.transition_to :active,
          on: :enter_bounds,
          action: proc { App.notification_center.post "BoundaryEnter" }
      end

      p.machine.start!
      p.machine.event(:activate)

      p.variables_to_save = ["location",
                             "user_id",
                             "display_name",
                             "role",
                             "refresh",
                             "pouwhenua_count"]
      p.update_all
    end
  end

  def update_location(in_location)
    @location = in_location
    update("location")
  end

  def to_hash
    # output = {user_id: @user_id, display_name: @display_name, location: @location}
    h = {}
    h[:user_id] = @user_id
    h[:display_name] = @display_name
    # TODO sort out whether we're using symbols or strings
    h[:location] = {"latitude" => @location.latitude, "longitude" => @location.longitude}
    h
  end

  def to_s
    s = super.to_s
    s += "\tuser_id: #{@user_id}\n"
    s += "\tdisplay_name: #{@display_name}\n"
    s += "\trole: #{@role}"
    s += "\trefresh: #{@refresh}"
    s += "\tpouwhenua_count: #{@pouwhenua_count}"
    s
  end
end

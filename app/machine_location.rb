class MachineLocation
  attr_accessor :location_state_machine,
                :location_manager,
                :current_location,
                :horizontal_accuracy

  DEBUGGING = true
  DESIRED_ACCURACY = 30

  def initialize
    mp __method__

    @location_state_machine = StateMachine::Base.new start_state: :initializing, verbose: DEBUGGING
    @location_state_machine.when :initializing do |state|
      state.on_entry { initialize_location_manager }
      state.transition_to :ready,
                          on: :auth_finished_initializing,
    end
    @location_state_machine.when :ready do |state|
      # state.transition_to :menu,
      #                     after: 10,
      #                     on_notification: :app_splash_to_menu,
      #                     action: proc { transition_splash_to_main_menu }
    end
    @location_state_machine.when :updating do |state|

    end
    @location_state_machine.when :lost do |state|

    end
    @location_state_machine.when :out_of_bounds do |state|

    end

    @location_state_machine.start!
  end

  def initialize_location_manager
    mp __method__

    @location_manager ||= CLLocationManager.alloc.init.tap do |lm|
      lm.requestWhenInUseAuthorization

      # constant needs to be capitalized because Ruby
      lm.desiredAccuracy = KCLLocationAccuracyBestForNavigation
      # lm.desiredAccuracy = KCLLocationAccuracyBest
      lm.distanceFilter = 2
      lm.startUpdatingLocation
      lm.delegate = self
    end
  end

  def location=( new_location, old_location )
    mp __method__

    accurate = @horizontal_accuracy <= DESIRED_ACCURACY
    # Check for reasonable accuracy
    # https://stackoverflow.com/a/13502503
    puts "horizontalAccuracy: #{new_location.horizontalAccuracy}".focus

    @current_location = new_location unless @current_location

    Notification.center.post(
      'accuracy_change',
      { 'accurate' => accurate }
    )

    return unless accurate

    Notification.center.post(
      'UpdateLocation',
      { 'new_location' => new_location, 'old_location' => old_location }
    )
  end
end

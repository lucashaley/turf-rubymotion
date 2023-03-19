class MachineViewController < UIViewController
  extend IB
  extend Debugging

  DEBUGGING = false

  def viewDidLoad
		puts "MachineViewController viewDidLoad".red
    Machine.instance.current_view = self
  end

  def machine
    Machine.instance
  end

  def app_machine
    Machine.instance.app_state_machine
  end

  def login_machine
    Machine.instance.login_machine
  end

  def location_machine
    Machine.instance.location_machine
  end

  def current_game
    machine.takaro_fbo
  end
end

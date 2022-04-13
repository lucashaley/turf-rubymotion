class MachineViewController < UIViewController
  extend IB
  extend Debugging
  
  DEBUGGING = false
  
  def viewDidLoad
		puts "MachineViewController viewDidLoad".red
    Machine.instance.current_view = self
  end
end
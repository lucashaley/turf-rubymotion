class MachineViewController < UIViewController
  extend IB
  extend Debugging
  
  def viewDidLoad
		puts "MachineViewController viewDidLoad".red
    Machine.instance.current_view = self
  end
end
class SettingsController < MachineViewController
  def viewDidLoad
    super
  end
  
  def dismiss_modal
    # https://stackoverflow.com/questions/21593770/ios-unwind-back-in-a-chain-of-modal-segues
    presentingViewController.dismissViewControllerAnimated(true, completion: nil)
  end
end

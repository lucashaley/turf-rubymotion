class SettingsController < UIViewController
  # https://code.tutsplus.com/tutorials/lets-write-a-rubymotion-app-part-1--cms-20612
  extend IB

  # ib_action :dismiss_modal

  def dismiss_modal
    # https://stackoverflow.com/questions/21593770/ios-unwind-back-in-a-chain-of-modal-segues
    self.presentingViewController.dismissViewControllerAnimated(true, completion:nil)
  end
end

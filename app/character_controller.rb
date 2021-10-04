class CharacterController < UIViewController
  # https://code.tutsplus.com/tutorials/lets-write-a-rubymotion-app-part-1--cms-20612
  extend IB

  outlet :scout_button, UIButton

  def select_scout
    Machine.instance.set_player("scout")
    dismiss_modal
  end

  def dismiss_modal
    self.presentingViewController.dismissViewControllerAnimated(true, completion:nil)
  end
end

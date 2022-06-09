class InfoViewController < UIViewController
  extend IB
  outlet :button_close, UIButton

  def close(sender)
    presentingViewController.dismissViewControllerAnimated(true, completion: nil)
  end
end
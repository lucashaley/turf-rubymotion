class JoinController < UIViewController
  # https://code.tutsplus.com/tutorials/lets-write-a-rubymotion-app-part-1--cms-20612
  extend IB

  # outlet :mapview, MKMapView
  outlet :gamecode, UILabel
  outlet :character_view, CharacterController
  outlet :cancel_button, UIButton

  def viewDidLoad
    # Do some stuff in here
  end

  def cancel_new_game
    puts "NewController: cancel_new_game"

    # self.presentingViewController.dismissViewControllerAnimated(true, completion:nil)
  end

  def dismiss_new
    Machine.instance.segue("ToMenu")
  end
end

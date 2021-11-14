class NewController < UIViewController
  # https://code.tutsplus.com/tutorials/lets-write-a-rubymotion-app-part-1--cms-20612
  extend IB

  # outlet :mapview, MKMapView
  outlet :gamecode, UILabel
  outlet :character_view, CharacterController
  outlet :cancel_button, UIButton

  def viewDidLoad
    puts "NEWCONTROLLER: VIEWDIDLOAD".light_blue
    Machine.instance.current_view = self

    # get the current player's location
    Machine.instance.initialize_location_manager

    # create a new game in Firebase and retrieve its ID
    Machine.instance.create_new_game
    puts "New game uuID: #{Machine.instance.game.uuID.UUIDString}"

    # set player in db

    Machine.instance.segue("ToCharacter")
  end

  def cancel_new_game
    puts "NewController: cancel_new_game"

    # self.presentingViewController.dismissViewControllerAnimated(true, completion:nil)
  end

  # https://stackoverflow.com/questions/16668436/how-to-send-in-app-sms-using-rubymotion
  def compose_sms
    puts "compose_sms"
    MFMessageComposeViewController.alloc.init.tap do |sms|
      sms.messageComposeDelegate = self
      sms.recipients = ["+6420410908922", "+15037361234"]
      sms.body = "You've been invited to a game of Turf. The game code is #{@new_id}. Open your Turf app on your device and select 'Join Game'."
      presentModalViewController(sms, animated: true)
    end if MFMessageComposeViewController.canSendText
  end

  def messageComposeViewController(controller, didFinishWithResult: result)
    puts "didFinishWithResult"
    NSLog("SMS Result: #{result}")
    controller.dismissModalViewControllerAnimated(true)
  end

  def dismiss_new
    Machine.instance.segue("ToMenu")
  end
end

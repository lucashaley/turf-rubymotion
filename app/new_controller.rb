class NewController < UIViewController
  # https://code.tutsplus.com/tutorials/lets-write-a-rubymotion-app-part-1--cms-20612
  extend IB

  # outlet :mapview, MKMapView
  outlet :gamecode, UILabel

  def viewDidLoad
    # mapview.setCenterCoordinate(CLLocationCoordinate2D.new(50, 50), animated:true)

    # create a new game in Firebase and retrieve its ID
    @new_id = Machine.instance.generate_new_id
    gamecode.text = @new_id
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
      self.presentModalViewController(sms, animated:true)
    end if MFMessageComposeViewController.canSendText
  end

  def messageComposeViewController(controller, didFinishWithResult:result)
    puts "didFinishWithResult"
    NSLog("SMS Result: #{result}")
    controller.dismissModalViewControllerAnimated(true)
  end
end

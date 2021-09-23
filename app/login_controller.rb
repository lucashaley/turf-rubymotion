class LoginController < UIViewController
  # https://code.tutsplus.com/tutorials/lets-write-a-rubymotion-app-part-1--cms-20612
  extend IB

  outlet :title, UILabel
  outlet :login_button, UIButton

  def viewDidLoad
    super

    puts "viewDidLoad"

    # auth = FIRAuth.authWithApp(app)
    #
    # puts auth.currentUser()

    self.performSegueWithIdentifier("LoginToMenu", sender: self)
  end

  def controlTouched(sender)
    puts "touched"
  end
end

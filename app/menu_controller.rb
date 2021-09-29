class MenuController < UIViewController
  # https://code.tutsplus.com/tutorials/lets-write-a-rubymotion-app-part-1--cms-20612
  extend IB

  outlet :title, UILabel
  outlet :login_button, UIButton

  def controlTouched(sender)
    puts "touched"
  end
end

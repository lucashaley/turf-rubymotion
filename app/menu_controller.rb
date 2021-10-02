class MenuController < UIViewController
  # https://code.tutsplus.com/tutorials/lets-write-a-rubymotion-app-part-1--cms-20612
  extend IB

  # outlet :title, UILabel
  # outlet :login_button, UIButton

  outlet :button_login, UIButton
  outlet :button_settings, UIButton
  outlet :button_characters, UIButton
  outlet :button_game_new, UIButton
  outlet :button_game_join, UIButton

  def controlTouched(sender)
    puts "touched"
  end

  def action_login(sender)
    puts ("action_login")
    Machine.instance.set_state(:log_in)
  end

  def action_settings(sender)

  end

  def action_characters(sender)

  end

  def action_game_new(sender)

  end

  def action_game_join(sender)

  end
end

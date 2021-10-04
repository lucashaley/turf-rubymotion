class MenuController < UIViewController
  extend IB

  outlet :button_login, UIButton
  outlet :button_settings, UIButton
  outlet :button_characters, UIButton
  outlet :button_game_new, UIButton
  outlet :button_game_join, UIButton

  def viewDidLoad
    if Machine.instance.user
      button_login.setTitle("Logout", forState:UIControlStateNormal)
    else
      button_login.setTitle("Login", forState:UIControlStateNormal)
    end
  end

  def controlTouched(sender)
    puts "touched"
  end

  def action_login(sender)
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
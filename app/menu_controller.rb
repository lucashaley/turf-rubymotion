class MenuController < UIViewController
  extend IB

  DEBUGGING = true

  outlet :button_login, UIButton
  outlet :button_settings, UIButton
  outlet :button_characters, UIButton
  outlet :button_game_new, UIButton
  outlet :button_game_join, UIButton

  def viewDidLoad
    puts "MENUCONTROLLER VIEWDIDLOAD".blue if DEBUGGING
    if Machine.instance.user
      button_login.setTitle("Logout", forState: UIControlStateNormal)
    else
      button_login.setTitle("Login", forState: UIControlStateNormal)
    end
  end

  def controlTouched(sender)
    puts "touched"
  end

  def action_login(sender)
    puts "MENUCONTROLLER ACTION_LOGIN".blue if DEBUGGING
    Machine.instance.set_state(:log_in)
  end

  def action_settings(sender)
    # TODO
  end

  def action_characters(sender)
    # TODO
  end

  def action_game_new(sender)
    puts "MENUCONTROLLER ACTION_GAME_NEW".blue if DEBUGGING
  end

  def action_game_join(sender)
    puts "MENUCONTROLLER ACTION_GAME_JOIN".blue if DEBUGGING
  end
end

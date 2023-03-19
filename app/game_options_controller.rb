class GameOptionsController < MachineViewController
  def select_duration(sender)
    mp __method__

    # TODO: this should probably just be set on continue
    case sender.selectedSegmentIndex
    when 0
      current_game.duration = 5
    when 1
      current_game.duration = 10
    when 2
      current_game.duration = 20
    end
  end

  def action_continue
    mp __method__

    app_machine.event(:app_game_options_to_character_select)
  end

  def action_cancel
    mp __method__

    app_machine.event(:app_game_options_to_main_menu)
  end
end

class SelectCharacterController < MachineViewController
  DEBUGGING = true

  def viewDidLoad
    puts 'SELECTCHARACTERCONTROLLER VIEWDIDLOAD'.blue if DEBUGGING
    @player_classes = {
      'scout' => {
        'deploy_time' => 4,
        # 'lifespan_ms' => 0.5.minutes * 1000,
        'lifespan' => 1.minutes,
        'pouwhenua_start' => 4,
        'title' => 'Scout',
        'can_see_into_enemy_turf' => false,
        'is_invisible_in_enemy_turf' => false,
        'can_place_in_enemy_turf' => true
      },
      'tank' => {
        'deploy_time' => 6,
        'lifespan' => 2.minutes,
        'pouwhenua_start' => 2,
        'title' => 'Tank',
        'can_see_into_enemy_turf' => false,
        'is_invisible_in_enemy_turf' => false,
        'can_place_in_enemy_turf' => true
      },
      'commander' => {
        'deploy_time' => 5,
        'lifespan' => 1.minutes,
        'pouwhenua_start' => 3,
        'title' => 'Commander',
        'can_see_into_enemy_turf' => true,
        'is_invisible_in_enemy_turf' => false,
        'can_place_in_enemy_turf' => true
      },
      'ghost' => {
        'deploy_time' => 5,
        'lifespan' => 1.minutes,
        'pouwhenua_start' => 2,
        'title' => 'Ghost',
        'can_see_into_enemy_turf' => true,
        'is_invisible_in_enemy_turf' => true,
        'can_place_in_enemy_turf' => false
      }
    }
    @player_classes.each_with_index do |pc, index|
      create_character_button(pc[0], index)
    end

    # with the new new/join system, we have the gamecode
    # puts "Takaro gamecode: #{Machine.instance.takaro_fbo.gamecode}".red

    # Notification.center.post("game_state_character_selection_notification", nil)
  end

  def create_character_button(title, index)
    button = UIButton.buttonWithType(UIButtonTypeSystem)
    button.setTitle(title, forState: UIControlStateNormal)
    button.titleLabel.font = UIFont.systemFontOfSize(30, weight: UIFontWeightSemibold)
    # button.setTitleColor(color, forState:UIControlStateNormal)
    button.sizeToFit
    button.frame = CGRectMake(
      view.center.x - (button.frame.size.width / 2), (index * button.frame.size.height + 20) + 180,
      200, button.frame.size.height
    )
    button.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin
    button.addTarget(self,
                     action: 'select_player_class:',
                     forControlEvents: UIControlEventTouchUpInside)

    # This is a weird hack to pass the class to the action
    button.tag = index
    view.addSubview(button)
  end

  def select_player_class(sender)
    mp __method__
    # puts 'CHARACTERCONTROLLER SELECT_PLAYER_CLASS'.blue if DEBUGGING

    # character = @player_classes.values[sender.tag]
    # puts "Class selected: #{character}".focus

    # directly make a local variable on the Controller, for Join Controller
    machine.local_character = @player_classes.values[sender.tag]
    # Machine.instance.takaro_fbo.local_kaitakaro.character = character

    # post notification for New Controller
    # Not doing this any more, favoring Machine.local_character and initialize_local_character
    # Notification.center.post('SelectCharacter', character)

    # Machine.instance.segue('ToGame')
    # Machine.instance.segue('ToWaitingRoom')
    # performSegueWithIdentifier('ToWaitingRoom', sender: self)
    app_machine.event(:app_character_select_to_waiting_room)
  end
end

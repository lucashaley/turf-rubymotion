class SelectCharacterController < MachineViewController
  DEBUGGING = true

  def viewDidLoad
    puts 'SELECTCHARACTERCONTROLLER VIEWDIDLOAD'.blue if DEBUGGING
    @player_classes = {
      'scout' => {
        'deploy_time' => 4,
        # 'lifespan_ms' => 0.5.minutes * 1000,
        'lifespan_ms' => 8 * 1000,
        'pouwhenua_start' => 8,
        'title' => 'Scout',
        'can_see_into_enemy_turf' => false,
        'is_invisible_in_enemy_turf' => false,
        'can_place_in_enemy_turf' => true
      },
      'tank' => {
        'deploy_time' => 6,
        'lifespan_ms' => 2.minutes * 1000,
        'pouwhenua_start' => 3,
        'title' => 'Tank',
        'can_see_into_enemy_turf' => false,
        'is_invisible_in_enemy_turf' => false,
        'can_place_in_enemy_turf' => true
      },
      'commander' => {
        'deploy_time' => 5,
        'lifespan_ms' => 1.minutes * 1000,
        'pouwhenua_start' => 4,
        'title' => 'Commander',
        'can_see_into_enemy_turf' => true,
        'is_invisible_in_enemy_turf' => false,
        'can_place_in_enemy_turf' => true
      },
      'ghost' => {
        'deploy_time' => 5,
        'lifespan_ms' => 1.minutes * 1000,
        'pouwhenua_start' => 4,
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
    puts "Takaro gamecode: #{Machine.instance.takaro_fbo.gamecode}".red
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
    puts 'CHARACTERCONTROLLER SELECT_PLAYER_CLASS'.blue if DEBUGGING

    character = @player_classes.values[sender.tag]
    puts "Class selected: #{character}".focus

    # directly make a local variable on the Controller, for Join Controller
    Machine.instance.local_character = character
    # Machine.instance.takaro_fbo.local_kaitakaro.character = character

    # post notification for New Controller
    App.notification_center.post('SelectCharacter', character)

    # Machine.instance.segue('ToGame')
    # Machine.instance.segue('ToWaitingRoom')
    performSegueWithIdentifier('ToWaitingRoom', sender: self)
  end
end

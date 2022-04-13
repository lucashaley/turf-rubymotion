class SelectCharacterController < MachineViewController
  DEBUGGING = true

  def viewDidLoad
    puts 'SELECTCHARACTERCONTROLLER VIEWDIDLOAD'.blue if DEBUGGING
    @player_classes = {
      'scout' => {
        'deploy_time' => 4,
        'lifespan_ms' => 2 * 60 * 1000,
        'pouwhenua_start' => 8,
        'title' => 'Scout'
      },
      'tank' => {
        'deploy_time' => 6,
        'lifespan_ms' => 8 * 60 * 1000,
        'pouwhenua_start' => 3,
        'title' => 'Tank'
      },
      'commander' => {
        'deploy_time' => 8,
        'lifespan_ms' => 5 * 60 * 1000,
        'pouwhenua_start' => 4,
        'title' => 'Commander'
      }
    }
    @player_classes.each_with_index do |pc, index|
#       # button_width = 200
#       button = UIButton.buttonWithType(UIButtonTypeSystem)
#       button.setTitle(pc[0], forState: UIControlStateNormal)
#       button.titleLabel.font = UIFont.systemFontOfSize(30, weight: UIFontWeightSemibold)
#       # button.setTitleColor(color, forState:UIControlStateNormal)
#       button.sizeToFit
#       button.frame = CGRectMake(
#         self.view.center.x - (button.frame.size.width / 2), (index * button.frame.size.height + 20) + 180,
#         200, button.frame.size.height
#       )
#       button.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin
#       button.addTarget(self,
#                        action: 'select_player_class:',
#                        forControlEvents: UIControlEventTouchUpInside)
# 
#       # This is a weird hack to pass the class to the action
#       button.tag = index
#       self.view.addSubview(button)
      create_character_button(pc[0], index)
    end

    # with the new new/join system, we have the gamecode
    # puts "Machine gamecode: #{Machine.instance.gamecode}".red
    puts "Takaro gamecode: #{Machine.instance.takaro_fbo.gamecode}".red

    # and need to set up the takaro
    # move this to the character selection?
  #   Machine.instance.db.referenceWithPath('games')
  #   .queryOrderedByChild('gamecode')
  #   .queryEqualToValue(Machine.instance.gamecode)
  #   .queryLimitedToLast(1)
  #   .getDataWithCompletionBlock(
  #     lambda do |_error, snapshot|
  #       # create the takaro
  #       puts "snapshot: #{snapshot.value}".focus
  #       Machine.instance.takaro = Takaro.new(snapshot.children.nextObject.key)
  #     end
  #   )
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
    Machine.instance.takaro_fbo.local_kaitakaro.character = character

    # post notification for New Controller
    App.notification_center.post('SelectCharacter', character)

    Machine.instance.segue('ToGame')
  end
end
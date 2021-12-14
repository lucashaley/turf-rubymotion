class PlayerCell < UITableViewCell
  extend IB

  outlet :player_name, UILabel

  def initWithStyle(style, reuseIdentifier: identifier)
    puts "#{__method__}".light_blue
    super.tap do |c|
      size = contentView.frame.size
      player_name = UILabel.alloc.initWithFrame(CGRectMake(8.0, 8.0, size.width - 16.0, size.height - 16.0))
      puts player_name
      contentView.addSubview(player_name)
    end
  end

  def viewDidLoad
    puts "PLAYER_CELL VIEWDIDLOAD".blue
    super.tap do |c|
      c.player_name.setText("Pants")
    end
  end
end

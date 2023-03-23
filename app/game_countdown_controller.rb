class GameCountdownController < MachineViewController
  def viewDidLoad
    super

    mp 'Countdown setting local player status'
    Utilities::breadcrumb('Countdown setting local player status')
    current_game.local_player_status = 'ready'

    # @location_update_observer = Notification.center.observe 'CountdownSegueToGame' do |data|
    #   mp 'LETS GOOOOOOOOOOOOOOOO!!!'
    #   # Notification.center.post('game_state_playing_notification', nil)
    #   # performSegueWithIdentifier('ToGame', sender: self)
    # end
  end
end

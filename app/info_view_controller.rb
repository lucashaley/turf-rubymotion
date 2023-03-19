class InfoViewController < MachineViewController
  extend IB
  outlet :button_close, UIButton

  def close(sender)
    app_machine.event(:dismiss_info_view)
  end
end

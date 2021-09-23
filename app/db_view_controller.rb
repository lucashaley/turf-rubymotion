class DbViewController < UIViewController
  def loadView
    self.view = DbView.alloc.init
  end
end

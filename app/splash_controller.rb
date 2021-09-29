class SplashController < UIViewController
  # https://code.tutsplus.com/tutorials/lets-write-a-rubymotion-app-part-1--cms-20612
  extend IB

  def viewDidLoad
    puts ("SplashController: viewDidLoad")
    self.view.addGestureRecognizer(
      UITapGestureRecognizer.alloc.initWithTarget(self, action: "handleSingleTap:")
    )
  end

  def handleSingleTap(recognizer)
    puts ("SplashController: handleSingleTap")
    UIApplication.sharedApplication.delegate.to_menu
  end
end

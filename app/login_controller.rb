class LoginController < MachineViewController
  # outlet :result, UILabel
  outlet :button_apple, UIButton
  outlet :button_google, UIButton

  # ib_action :unwind_to_main_menu
  ib_action :unwind_to_main_menu, UIStoryboardSegue

  DEBUGGING = true

  def viewDidLoad
    # This is GIDSignIn version
    # create notifications
    Notification.center.observe 'ASAuthorizationAppleIDProviderCredentialRevokedNotification' do |_notification|
      $logger.warn 'SignInWithAppleStateChanged'
    end
  end

  def handle_apple_authorization(sender)
    $logger.info 'handle_apple_authorization'
    # @result.text = 'handle_apple_authorization'
    @nonce = generate_nonce
    # @result.text = @nonce

    appleID_provider = ASAuthorizationAppleIDProvider.alloc.init
    $logger.info appleID_provider

    request = appleID_provider.createRequest
    request.nonce = @nonce.SHA256

    request.requestedScopes = [ASAuthorizationScopeFullName, ASAuthorizationScopeEmail]
    $logger.info request

    # the argument needs to be an array
    auth_controller = ASAuthorizationController.alloc.initWithAuthorizationRequests([request])
    $logger.info auth_controller
    auth_controller.delegate = self
    auth_controller.presentationContextProvider = self
    $logger.info auth_controller

    # @result.text = 'perform'
    auth_controller.performRequests
  end

  # ASAuthorizationControllerDelegate
  # - (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization;
  def authorizationController(auth_controller, didCompleteWithAuthorization: authorization)
    if authorization.nil?
      # @result.text = 'NO AUTHORIZATION'
      return
    end

    $logger.info 'didCompleteWithAuthorization'
    # @result.text = 'didCompleteWithAuthorization'

#     $logger.info authorization
#     $logger.info authorization.credential

    @result.text = @nonce
    # @result.text = authorization.credential.authorizationCode.to_s
    # id_token = NSString.alloc.initWithData(authorization.credential, encoding: NSUTF8StringEncoding)

    credential = FIROAuthProvider.credentialWithProviderID(
      'apple.com',
      IDToken: authorization.credential.identityToken.to_s,
      rawNonce: @nonce
    )

    # @result.text = credential.to_s

    # @result.text = 'Finished authorization'

    complete_authorization(credential)
  end

  # - (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error;
  def authorizationController(auth_controller, didCompleteWithError: error)
    $logger.info 'didCompleteWithError'
    # @result.text = 'didCompleteWithError'
  end

  # ASAuthorizationControllerPresentationContextProviding
  # - (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller;
  def presentationAnchorForAuthorizationController(controller)
    $logger.info 'presentationAnchorForAuthorizationController'
    view.window
  end

  def handle_google_authorization(sender)
    $logger.info 'handle_google_authorization'

    gid_config = GIDConfiguration.alloc.initWithClientID(FIRApp.defaultApp.options.clientID)

    GIDSignIn.sharedInstance.signInWithConfiguration(
      gid_config,
      presentingViewController: self,
      callback: method(:complete_google_authorization)
    )
  end

  def complete_google_authorization(user, error)
    $logger.info 'complete_google_authorization'

    unless error.nil?
      $logger.error error.localizedDescription
      $logger.error error.userInfo
      return
    end

    authentication = user.authentication
    credential = FIRGoogleAuthProvider.credentialWithIDToken(
      authentication.idToken,
      accessToken: authentication.accessToken
    )

    complete_authorization(credential)
  end

  def complete_authorization(credential)
    $logger.info 'complete_authorization'
    # @result.text = credential.provider

    Dispatch::Queue.new("turf-test-db").async do
      FIRAuth.auth.signInWithCredential(credential, completion: lambda do |auth_result, error|
        unless error.nil?
          @result.text = error.localizedDescription
          return
        end
        # @result.text = auth_result.user.providerData[0].displayName if error.nil?
        if auth_result.nil?
          # @result.text = 'no result!'
          return
        end
        if auth_result.credential.nil?
          # @result.text = 'no credential!'
          return
        end

        Machine.instance.firebase_user = auth_result.user
        Machine.instance.firebase_displayname = auth_result.user.providerData[0].displayName
        Machine.instance.firebase_email = auth_result.user.providerData[0].email

        mp 'ready to unwind'
        Machine.instance.current_view.login
        # self.performSegueWithIdentifier('UnwindToMainMenu', sender: self)
        presentingViewController.dismissViewControllerAnimated(true, completion: nil)
      end)
    end
  end

  def generate_nonce
    rand(10**30).to_s.rjust(30, '0')
  end

  def unwind_to_main_menu(sender)
    mp 'login_controller unwind_to_main_menu'
    source_view_controller = sender.sourceViewController
  end
end

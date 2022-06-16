class LoginController < MachineViewController
  # outlet :result, UILabel
  outlet :button_apple, UIButton
  outlet :button_google, UIButton

  # this gives ib an action in the Exit
  ib_action :unwind_to_main_menu, UIStoryboardSegue

  DEBUGGING = true

  def viewDidLoad
    # This is GIDSignIn version
    # create notifications
    Notification.center.observe 'ASAuthorizationAppleIDProviderCredentialRevokedNotification' do |_notification|
      $logger.warn 'SignInWithAppleStateChanged'
    end
  end

  # this is an action attached to a button in IB
  # the UIButton class is replaced with ASAuthorizationAppleIDButton
  # make sure your Rake file has:
  # app.frameworks += ['AuthenticationServices']
  # and
  #   app.entitlements['com.apple.developer.applesignin'] = ['Default']
  def handle_apple_authorization(sender)
    $logger.info 'handle_apple_authorization'

    # the 'nonce' is a random string that is used to confirm the authentication
    # for Firebase logins using Apple
    @nonce = generate_nonce

    appleID_provider = ASAuthorizationAppleIDProvider.alloc.init
    $logger.info appleID_provider

    # Create the request, and encode the nonce
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

    # start the process
    auth_controller.performRequests
  end

  # ASAuthorizationControllerDelegate
  # - (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization;
  def authorizationController(auth_controller, didCompleteWithAuthorization: authorization)
    if authorization.nil?
      # probably more graceful things should happen here
      return
    end

    $logger.info 'didCompleteWithAuthorization'

    # create a firebase credential for the apple auth
    credential = FIROAuthProvider.credentialWithProviderID(
      'apple.com',
      IDToken: authorization.credential.identityToken.to_s,
      rawNonce: @nonce
    )

    complete_authorization(credential)
  end

  # - (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error;
  def authorizationController(auth_controller, didCompleteWithError: error)
    $logger.info 'didCompleteWithError'
    # again, something useful should happen here
  end

  # ASAuthorizationControllerPresentationContextProviding
  # - (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller;
  def presentationAnchorForAuthorizationController(controller)
    $logger.info 'presentationAnchorForAuthorizationController'
    view.window
  end

  # this is an action attached to a button in IB
  def handle_google_authorization(sender)
    $logger.info 'handle_google_authorization'

    # get the config from the current Firebase app
    gid_config = GIDConfiguration.alloc.initWithClientID(FIRApp.defaultApp.options.clientID)

    # show the sign in
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

    # create a firebase credential
    # this is more straightforward, because Firebase is Google
    authentication = user.authentication
    credential = FIRGoogleAuthProvider.credentialWithIDToken(
      authentication.idToken,
      accessToken: authentication.accessToken
    )

    complete_authorization(credential)
  end

  def complete_authorization(credential)
    # from either Apple or Google, we get a firebase credential
    $logger.info 'complete_authorization'

    # async call to sign into Firebase using the credential
    Dispatch::Queue.new("turf-test-db").async do
      FIRAuth.auth.signInWithCredential(credential, completion: lambda do |auth_result, error|
        unless error.nil?
          $logger.error error.localizedDescription
          return
        end

        if auth_result.nil?
          $logger.error 'no auth_result!'
          return
        end
        if auth_result.credential.nil?
          $logger.error 'no auth_result.credentail!'
          return
        end

        # here I'm setting the internal info particular for my app
        # note that the providerData is an array, even if it's just 1 long
        Machine.instance.firebase_user = auth_result.user
        Machine.instance.firebase_displayname = auth_result.user.providerData[0].displayName
        Machine.instance.firebase_email = auth_result.user.providerData[0].email

        # and return to the main menu, with the new login in place
        Machine.instance.current_view.login
        presentingViewController.dismissViewControllerAnimated(true, completion: nil)
      end)
    end
  end

  def generate_nonce
    rand(10**30).to_s.rjust(30, '0')
  end

  # unused, never got it to work
  def unwind_to_main_menu(sender)
    mp 'login_controller unwind_to_main_menu'
    source_view_controller = sender.sourceViewController
  end
end

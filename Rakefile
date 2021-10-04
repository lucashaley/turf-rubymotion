# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
$:.unshift("~/.rubymotion/rubymotion-templates")

# ===========================================================================================
# 1. Be sure to read `readme.md`.
# ===========================================================================================

require 'motion/project/template/ios'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

# https://github.com/rubymotion-community/BubbleWrap
require 'bubble-wrap'
# https://github.com/rubymotion-community/ib
require 'ib'

# Uncomment the following line to add an icon generate capacity to your build
#task 'build:icons' => 'resources/app-icon.icon_asset'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  define_icon_defaults!(app)

  # ===========================================================================================
  # 2. Set your app name (this is what will show up under the icon when your app is installed).
  # ===========================================================================================
  app.name = 'turf-rubymotion'

  # version for your app
  app.version = '0.1'

  # ===========================================================================================
  # 3. Set your deployment target (it's recommended that you at least target 10.0 and above).
  #    If you're using RubyMotion Starter Edition. You cannot set this value (the latest
  #    version of iOS will be used).
  # ===========================================================================================
  # app.deployment_target = '10.0'

  # ===========================================================================================
  # 4. Set the architectures for which to build.
  # ===========================================================================================
  app.archs['iPhoneOS'] = ['arm64']

  # ===========================================================================================
  # 5. Your app identifier is needed to deploy to an actual device. You do not need to set this
  #    if you are using the simulator. You can create an app identifier at:
  #    https://developer.apple.com/account/ios/identifier/bundle. You must enroll into Apple's
  #    Developer program to get access to this screen (there is an annual fee of $99).
  # ===========================================================================================

  # this is set for keychain shit
  # info is from dev console identifier
  app.identifier = 'com.animatology.test-rubymotionfirebase-01'
  app.seed_id = '3DZ7KWNU9A'

  # ===========================================================================================
  # 6. If you need to reference any additional iOS libraries, use the config array below.
  #    Default libraries: UIKit, Foundation, CoreGraphics, CoreFoundation, CFNetwork, CoreAudio
  # ===========================================================================================
  # app.frameworks << "StoreKit"

  # reasonable defaults
  app.device_family = [:iphone, :ipad]
  app.interface_orientations = [:portrait]
  app.info_plist['UIRequiresFullScreen'] = true
  app.info_plist['ITSAppUsesNonExemptEncryption'] = false

  app.frameworks += ['CoreLocation','MessageUI']

  # ===========================================================================================
  # 7. To deploy to an actual device, you will need to create a developer certificate at:
  #    https://developer.apple.com/account/ios/certificate/development
  #    The name of the certificate will be accessible via Keychain Access. Set the value you
  #    see there below.
  # ===========================================================================================
  app.codesign_certificate = MotionProvisioning.certificate(platform: :ios,
                               type: :development,
                               free: false)

  # ===========================================================================================
  # 8. To deploy to an actual device, you will need to create a provisioning profile. First:
  #    register your device at:
  #    https://developer.apple.com/account/ios/device/
  #
  #    Then create a development provisioning profile at:
  #    https://developer.apple.com/account/ios/profile/limited
  #
  #    Download the profile and set the path to the download location below.
  # ===========================================================================================
  app.provisioning_profile = MotionProvisioning.profile(bundle_identifier: "com.animatology.test-rubymotionfirebase-01",
                           app_name: "Test RubyMotion Firebase",
                           platform: :ios,
                           type: :development,
                           free: false)

  # ===========================================================================================
  # 9. Similar to Step 8. Production, create a production certificate at:
  #    https://developer.apple.com/account/ios/certificate/distribution.
  #    These values will need to be set to before you can deploy to the App Store. Compile
  #    using `rake clean archive:distribution` and upload the .ipa under ./build using
  #    Application Loader.
  # ===========================================================================================
  # app.codesign_certificate = ''
  # app.provisioning_profile = ''

  # ===========================================================================================
  # 10. If you want to create a beta build. Uncomment the line below and set your profile to
  #     point to your production provisions (Step 9).
  # ===========================================================================================
  # app.entitlements['beta-reports-active'] = true

  # we need to set this for keychain shit
  # http://www.rubymotion.com/developers/guides/manuals/cocoa/project-management/
  app.entitlements['keychain-access-groups'] = [
    app.seed_id + '.' + app.identifier
  ]

  # Description for the Location service allow dialog
  app.info_plist['NSLocationAlwaysUsageDescription'] = 'Description'
  app.info_plist['NSLocationWhenInUseUsageDescription'] = 'Description'

  # https://azukidigital.com/blog/2014/rubymotion-and-google-ios-sdk/
  app.info_plist['CFBundleURLTypes'] = [{
    # s'CFBundleURLName' => 'com.companyname.appname',
    'CFBundleURLSchemes' => ['com.googleusercontent.apps.858979761808-s8em2ueobqgnhi6905jcrifshedb4r61']
  }]
  # https://github.com/amirrajan/rubymotion-applied/issues/127
  app.info_plist['FirebaseAppDelegateProxyEnabled'] = false

  app.pods do
    source 'https://cdn.cocoapods.org/'
    # The Swift pod `FacebookCore` depends upon `FBSDKCoreKit`, which does not define modules.
    # To opt into those targets generating module maps (which is necessary to import them from
    # Swift when building as static libraries), you may set `use_modular_headers!` globally
    # in your Podfile, or specify `:modular_headers => true` for particular dependencies.
    # pod 'FBSDKCoreKit', '~> 11.2.0', :modular_headers => true
    # pod 'FBSDKLoginKit', '~> 11.2.0', :modular_headers => true
    # pod 'FBSDKShareKit', '~> 11.2.0', :modular_headers => true
    # pod 'FacebookCore', :modular_headers => true
    # pod 'FacebookLogin', :modular_headers => true
    # pod 'FacebookShare', :modular_headers => true

    pod 'Firebase', '~> 8.7.0'
    pod 'Firebase/Auth', '~> 8.7.0'
    pod 'Firebase/Database'
    pod 'GoogleSignIn'
    # pod 'FirebaseUI', '~> 12.0.2'
    # pod 'FirebaseUI/Auth'
    # pod 'FirebaseUI/Google'
    # # pod 'FirebaseUI/Twitter'
    # pod 'FirebaseUI/OAuth' # Used for Sign in with Apple, Twitter, etc
    # pod 'FirebaseUI/Phone'
  end
end

def define_icon_defaults!(app)
  # This is required as of iOS 11.0 (you must use asset catalogs to
  # define icons or your app will be rejected. More information in
  # located in the readme.

  app.info_plist['CFBundleIcons'] = {
    'CFBundlePrimaryIcon' => {
      'CFBundleIconName' => 'AppIcon',
      'CFBundleIconFiles' => ['AppIcon60x60']
    }
  }

  app.info_plist['CFBundleIcons~ipad'] = {
    'CFBundlePrimaryIcon' => {
      'CFBundleIconName' => 'AppIcon',
      'CFBundleIconFiles' => ['AppIcon60x60', 'AppIcon76x76']
    }
  }
end
# -*- coding: utf-8 -*-
$:.unshift('/Library/RubyMotion/lib')
$:.unshift('~/.rubymotion/rubymotion-templates')

# ===========================================================================================
# 1. Be sure to read `readme.md`.
# ===========================================================================================

require 'motion/project/template/ios'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
  puts 'LOAD ERROR'
end

# https://github.com/rubymotion-community/BubbleWrap
# require 'bubble-wrap'
# https://github.com/rubymotion-community/ib
require 'ib'
# https://github.com/clayallsopp/geomotion
# require 'geomotion'

# Uncomment the following line to add an icon generate capacity to your build
task 'build:icons' => 'resources/app-icon.icon_asset'

# rubocop:disable Metrics/BlockLength
Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  define_icon_defaults!(app)

  # ===========================================================================================
  # 2. Set your app name (this is what will show up under the icon when your app is installed).
  # ===========================================================================================
  app.name = 'Turf'

  # version for your app
  app.version = '0.1.11'

  # ===========================================================================================
  # 3. Set your deployment target (it's recommended that you at least target 10.0 and above).
  #    If you're using RubyMotion Starter Edition. You cannot set this value (the latest
  #    version of iOS will be used).
  # ===========================================================================================
  app.deployment_target = '14.5'

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
  app.identifier = 'com.animatology.turf'
  app.seed_id = '3DZ7KWNU9A'

  # ===========================================================================================
  # 6. If you need to reference any additional iOS libraries, use the config array below.
  #    Default libraries: UIKit, Foundation, CoreGraphics, CoreFoundation, CFNetwork, CoreAudio
  # ===========================================================================================
  # app.frameworks << 'StoreKit'

  # reasonable defaults
  app.device_family = [:iphone]
  app.interface_orientations = [:portrait]
  app.info_plist['UIRequiresFullScreen'] = true
  app.info_plist['ITSAppUsesNonExemptEncryption'] = false

  app.info_plist['UIRequiredDeviceCapabilities'] = ['arm64']

  # app.frameworks += ['CoreLocation', 'MessageUI', 'MapKit', 'AudioToolbox', 'JavaScriptCore', 'FirebaseAnalytics']
  app.frameworks += ['CoreLocation', 'MessageUI', 'MapKit', 'AudioToolbox', 'JavaScriptCore', 'AuthenticationServices']

  # This is a force, as for some reason the pods weren't including the resources
  app.resources_dirs += ['vendor/Pods/FirebaseAuthUI/FirebaseAuthUI/Sources/Resources/']
  app.resources_dirs += ['vendor/Pods/FirebaseOAuthUI/FirebaseOAuthUI/Sources/Resources/']
  app.resources_dirs += ['vendor/Pods/FirebaseEmailAuthUI/FirebaseEmailAuthUI/Sources/Resrouces/']
  app.resources_dirs += ['vendor/Pods/GoogleSignIn/GoogleSignIn/Sources/Resrouces/']
  # app.resources_dirs += ['vendor/Pods/FirebaseAnalytics/']

  # app.vendor_project('vendor/objcvoronoi-master', :xcode,
  #     :headers_dir => 'objcvoronoi')
  # app.frameworks << 'Cocoa'

  # app.vendor_project('vendor/Pods/FirebaseUI', :static, ib: true)
  # app.vendor_project('vendor/Pods/AppAuth', :static, :headers_dir => 'Source/', ib: true)
  # app.vendor_project('vendor/Pods/GoogleSignIn', :static, ib: true)

  # ===========================================================================================
  # 7. To deploy to an actual device, you will need to create a developer certificate at:
  #    https://developer.apple.com/account/ios/certificate/development
  #    The name of the certificate will be accessible via Keychain Access. Set the value you
  #    see there below.
  # ===========================================================================================

#    app.development do
#     app.codesign_certificate = MotionProvisioning.certificate(
#       type: :development,
#       platform: :ios)
# 
#     app.provisioning_profile = MotionProvisioning.profile(
#       bundle_identifier: app.identifier,
#       app_name: app.name,
#       platform: :ios,
#       type: :development)
#   end
# 
#   app.release do
#     app.codesign_certificate = MotionProvisioning.certificate(
#       type: :distribution,
#       platform: :ios)
# 
#     app.provisioning_profile = MotionProvisioning.profile(
#       bundle_identifier: app.identifier,
#       app_name: app.name,
#       platform: :ios,
#       type: :distribution)
#   end


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

  # ===========================================================================================
  # 9. Similar to Step 8. Production, create a production certificate at:
  #    https://developer.apple.com/account/ios/certificate/distribution.
  #    These values will need to be set to before you can deploy to the App Store. Compile
  #    using `rake clean archive:distribution` and upload the .ipa under ./build using
  #    Application Loader.
  # ===========================================================================================
  # app.development do
  #   app.codesign_certificate = 
  #   app.provisioning_profile = 
  # end

  # this works
  app.release do
    app.codesign_certificate = "Apple Distribution: Lucas Haley (3DZ7KWNU9A)"
    app.provisioning_profile = 'provisioning/TurfDistribution.mobileprovision'
  end
  app.development do
    app.codesign_certificate = "Apple Development: Lucas Haley (RU52PCAUBM)"
    app.provisioning_profile = 'provisioning/TurfDevelopment.mobileprovision'
  end

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
  # https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_applesignin?language=objc
  app.entitlements['com.apple.developer.applesignin'] = [
    'Default'
  ]

  # Description for the Location service allow dialog
  app.info_plist['NSLocationAlwaysUsageDescription'] = 'Description'
  app.info_plist['NSLocationWhenInUseUsageDescription'] = 'Description'

  # https://azukidigital.com/blog/2014/rubymotion-and-google-ios-sdk/
  # https://firebase.google.com/docs/auth/ios/google-signin#2_implement_google_sign-in
  app.info_plist['CFBundleURLTypes'] = [{
    # 'CFBundleURLName' => 'com.companyname.appname',
    'CFBundleURLSchemes' => ['com.googleusercontent.apps.858979761808-s8em2ueobqgnhi6905jcrifshedb4r61']
  },{
    # 'CFBundleURLName' => 'com.companyname.appname',
    'CFBundleURLSchemes' => ['com.googleusercontent.apps.858979761808-1p3ni6tdgns4sge5tckefc583ud5o20m']
  }]
  # https://github.com/amirrajan/rubymotion-applied/issues/127
  app.info_plist['FirebaseAppDelegateProxyEnabled'] = false
  
  app.info_plist['bugsnag'] = [{
    'apiKey' => ['3cab9a5e6b16897ab5e965083c5b4fd7']
  }]

  app.pods do
    # use_frameworks!
    source 'https://cdn.cocoapods.org/'
    pod 'Firebase', '~> 8.10.0' # '~> 8.7.0'
    pod 'Firebase/Auth', '~> 8.10.0'
    pod 'Firebase/Database'
    # pod 'FirebaseAnalytics'
    pod 'GoogleSignIn'
    # pod 'FirebaseUI', '~> 12.0.2'
    pod 'FirebaseUI/Auth', '~> 12.0.2'
    pod 'FirebaseUI/Google'
    # # pod 'FirebaseUI/Twitter'
    pod 'FirebaseUI/OAuth' # Used for Sign in with Apple, Twitter, etc
    pod 'FirebaseUI/Email'
    # pod 'FirebaseUI/Database'
    # pod 'FirebaseUI/Phone'

    # https://github.com/DevRhys/iosvoronoi
    pod 'iosvoronoi'

    # https://github.com/mapbox/MapboxStatic.swift
    # pod 'MapboxStatic.swift', '~> 0.12'

    pod 'NSHash'
    
    # https://app.bugsnag.com
    pod 'Bugsnag'
  end
end
# rubocop:enable Metrics/BlockLength

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

# IB::RakeTask.new do |project|
# end

# https://github.com/archan937/motion-bundler
# Track and specify files and their mutual dependencies within the :motion Bundler group
# MotionBundler.setup

// Generated by IB v1.0.1 gem. Do not edit it manually
// Run `rake ib:open` to refresh

#import <CFNetwork/CFNetwork.h>
#import <CoreAudio/CoreAudio.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MessageUI/MessageUI.h>
#import <CoreTelephony/CoreTelephony.h>
#import <CoreText/CoreText.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <SafariServices/SafariServices.h>
#import <Security/Security.h>
#import <SystemConfiguration/SystemConfiguration.h>

@interface AppDelegate: UIResponder <UIApplicationDelegate>
@end

@interface Character: NSObject
@end

@interface CharacterController: UIViewController

@property IBOutlet UIButton * scout_button;

-(IBAction) select_scout;
-(IBAction) dismiss_modal;

@end

@interface DbView: UIView
-(IBAction) drawRect:(id) rect;

@end

@interface DbViewController: UIViewController
-(IBAction) loadView;

@end

@interface Game: NSObject
-(IBAction) initialize;
-(IBAction) generate_new_id;

@end

@interface GameController: UIViewController

@property IBOutlet MKMapView * map_view;
@property IBOutlet UIButton * button_pylon;

-(IBAction) viewDidLoad;
-(IBAction) locationUpdate:(id) location;
-(IBAction) touch_down;
-(IBAction) touch_up;
-(IBAction) touch_out;
-(IBAction) set_button_color:(id) color;

@end

@interface JoinController: UIViewController

@property IBOutlet UILabel * gamecode;
@property IBOutlet CharacterController * character_view;
@property IBOutlet UIButton * cancel_button;

-(IBAction) viewDidLoad;
-(IBAction) cancel_new_game;
-(IBAction) dismiss_new;

@end

@interface LoginController: UIViewController
-(IBAction) viewDidLoad;

@end

@interface Machine: NSObject
-(IBAction) initialize;
-(IBAction) set_state:(id) state;
-(IBAction) segue:(id) name;
-(IBAction) generate_new_id;
-(IBAction) set_player:(id) player;

@end

@interface MenuController: UIViewController

@property IBOutlet UIButton * button_login;
@property IBOutlet UIButton * button_settings;
@property IBOutlet UIButton * button_characters;
@property IBOutlet UIButton * button_game_new;
@property IBOutlet UIButton * button_game_join;

-(IBAction) viewDidLoad;
-(IBAction) controlTouched:(id) sender;
-(IBAction) action_login:(id) sender;
-(IBAction) action_settings:(id) sender;
-(IBAction) action_characters:(id) sender;
-(IBAction) action_game_new:(id) sender;
-(IBAction) action_game_join:(id) sender;

@end

@interface NewController: UIViewController

@property IBOutlet UILabel * gamecode;
@property IBOutlet CharacterController * character_view;
@property IBOutlet UIButton * cancel_button;

-(IBAction) viewDidLoad;
-(IBAction) cancel_new_game;
-(IBAction) compose_sms;
-(IBAction) dismiss_new;

@end

@interface Pylon: NSObject
-(IBAction) life;

@end

@interface Scout: Character
-(IBAction) initialize;

@end

@interface SettingsController: UIViewController
-(IBAction) dismiss_modal;

@end

@interface SplashController: UIViewController
-(IBAction) viewDidLoad;
-(IBAction) handleSingleTap:(id) recognizer;

@end


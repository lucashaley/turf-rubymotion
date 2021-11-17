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
#import <MapKit/MapKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreTelephony/CoreTelephony.h>
#import <CoreText/CoreText.h>
#import <FirebaseAnalytics/FirebaseAnalytics.h>
#import <GoogleAppMeasurement/GoogleAppMeasurement.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <SafariServices/SafariServices.h>
#import <Security/Security.h>
#import <StoreKit/StoreKit.h>
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
-(IBAction) set_ref:(id) ref;
-(IBAction) generate_new_id;
-(IBAction) create_new_pylon:(id) location;
-(IBAction) modify_pylon;
-(IBAction) start_observing_pylons;

@end

@interface GameController: UIViewController

@property IBOutlet MKMapView * map_view;
@property IBOutlet UIButton * button_pylon;

-(IBAction) viewWillAppear:(id) animated;
-(IBAction) viewDidLoad;
-(IBAction) renderOverlays;
-(IBAction) touch_down;
-(IBAction) touch_up;
-(IBAction) touch_out;
-(IBAction) set_button_color:(id) color;
-(IBAction) add_overlays_and_annotations;
-(IBAction) add_overlays;
-(IBAction) add_annotations;
-(IBAction) create_play_region:(id) args;
-(IBAction) player_for_audio:(id) filename;
-(IBAction) create_new_pylon;
-(IBAction) handle_new_pylon:(id) data;

@end

@interface MKPolygon: NSObject
@end

@interface Pylon: Site
-(IBAction) distance_from_pylon:(id) pylon;
-(IBAction) distance_from_location:(id) location;
-(IBAction) to_s;
-(IBAction) setLocation:(id) location;
-(IBAction) to_hash;
-(IBAction) lifespan_color;
-(IBAction) set_uuid:(id) new_uuid;
-(IBAction) set_annotation:(id) new_annotation;
-(IBAction) get_uicolor;

@end

@interface PylonAnnotation: NSObject
-(IBAction) initialize:(id) pylon;
-(IBAction) initWithPylon:(id) pylon;
-(IBAction) color;
-(IBAction) pylon_id;
-(IBAction) set_coordinate:(id) coord;
-(IBAction) coordinate;

@end

@interface PylonCell: NSObject
-(IBAction) edges;
-(IBAction) vertices;
-(IBAction) overlay;

@end

@interface VoronoiMap: NSObject
-(IBAction) initialize;
-(IBAction) voronoi_cells_from_pylons:(id) in_pylons;
-(IBAction) voronoi_cells;
-(IBAction) annotations;
-(IBAction) add_pylon:(id) pylon;

@end

@interface Wakawaka: NSObject
-(IBAction) color;
-(IBAction) edges;
-(IBAction) vertices;
-(IBAction) overlay;
-(IBAction) to_s;

@end

@interface JoinController: UIViewController

@property IBOutlet UITextField * gamecode;
@property IBOutlet CharacterController * character_view;
@property IBOutlet UIButton * cancel_button;
@property IBOutlet UIButton * continue_button;

-(IBAction) viewDidLoad;
-(IBAction) cancel_new_game:(id) sender;
-(IBAction) dismiss_join:(id) sender;

@end

@interface LoginController: UIViewController
-(IBAction) viewDidAppear:(id) animated;
-(IBAction) dismiss_modal;

@end

@interface Machine: NSObject
-(IBAction) initialize;
-(IBAction) set_state:(id) state;
-(IBAction) segue:(id) name;
-(IBAction) initialize_location_manager;
-(IBAction) locationUpdate:(id) location;
-(IBAction) set_player:(id) player;
-(IBAction) create_new_game;
-(IBAction) set_game:(id) game;
-(IBAction) create_new_pylon:(id) location;

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

@interface Player: NSObject
-(IBAction) initialize;

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

@interface String: NSObject
-(IBAction) colorize:(id) color_code;
-(IBAction) red;
-(IBAction) green;
-(IBAction) yellow;
-(IBAction) blue;
-(IBAction) pink;
-(IBAction) light_blue;
-(IBAction) recursive_symbolize_keys:(id) h;

@end


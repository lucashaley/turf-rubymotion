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
#import <JavaScriptCore/JavaScriptCore.h>
#import <FirebaseAnalytics/FirebaseAnalytics.h>
#import <CoreTelephony/CoreTelephony.h>
#import <CoreText/CoreText.h>
#import <GoogleAppMeasurement/GoogleAppMeasurement.h>
#import <GoogleAppMeasurementIdentitySupport/GoogleAppMeasurementIdentitySupport.h>
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

-(IBAction) viewDidLoad;
-(IBAction) select_player_class:(id) sender;
-(IBAction) dismiss_modal;

@end

@interface DbView: UIView
-(IBAction) drawRect:(id) rect;

@end

@interface DbViewController: UIViewController
-(IBAction) loadView;

@end

@interface FirebaseObject: NSObject
-(IBAction) pull;
-(IBAction) start_observing;
-(IBAction) set_uuid_with_string:(id) in_uuid_string;
-(IBAction) update_all;
-(IBAction) update:(id) node;
-(IBAction) uuid_string;
-(IBAction) to_s;

@end

@interface Game: FirebaseObject
-(IBAction) initialize;
-(IBAction) generate_new_id;
-(IBAction) add_local_player:(id) user;
-(IBAction) create_new_pylon:(id) coord;
-(IBAction) create_new_pouwhenua:(id) coord;
-(IBAction) modify_pylon;
-(IBAction) start_observing_pylons;
-(IBAction) start_observing_pouwhenua;
-(IBAction) check_for_game:(id) gamecode;
-(IBAction) start_observing_players;
-(IBAction) start_observing_kapa;

@end

@interface MachineViewController: UIViewController
-(IBAction) viewDidLoad;

@end

@interface GameController: MachineViewController

@property IBOutlet MKMapView * map_view;
@property IBOutlet UIButton * button_pylon;

-(IBAction) setup_mapview;
-(IBAction) setup_audio;
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
-(IBAction) player_for_audio:(id) filename;
-(IBAction) create_new_pouwhenua;
-(IBAction) handle_new_pylon:(id) data;
-(IBAction) handle_new_pouwhenua:(id) data;
-(IBAction) observe_new_pouwhenua;
-(IBAction) observe_new_pylon:(id) notification_object;
-(IBAction) observe_change_pylon;
-(IBAction) observe_death_pylon:(id) notification_object;

@end

@interface GameOld: NSObject
-(IBAction) initialize;
-(IBAction) set_ref:(id) ref;
-(IBAction) generate_new_id;
-(IBAction) add_local_player:(id) user;
-(IBAction) create_new_pylon:(id) coord;
-(IBAction) create_new_pouwhenua:(id) coord;
-(IBAction) modify_pylon;
-(IBAction) start_observing_pylons;
-(IBAction) start_observing_pouwhenua;
-(IBAction) check_for_game:(id) gamecode;
-(IBAction) start_observing_players;
-(IBAction) start_observing_kapa;

@end

@interface MKPolygon: NSObject
@end

@interface PouAnnotation: MKPointAnnotation
@end

@interface PouSite: Site
@end

@interface Pouwhenua: Site
-(IBAction) distance_from_pylon:(id) pylon;
-(IBAction) distance_from_location:(id) location;
-(IBAction) set_location:(id) location;
-(IBAction) lifespan_color;
-(IBAction) set_uuid:(id) new_uuid;
-(IBAction) uuid_string;
-(IBAction) set_annotation:(id) new_annotation;
-(IBAction) get_uicolor;
-(IBAction) to_hash;
-(IBAction) recursive_symbolize_keys:(id) h;

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
-(IBAction) add_pouwhenua:(id) pouwhenua;

@end

@interface Wakawaka: NSObject
-(IBAction) color;
-(IBAction) edges;
-(IBAction) vertices;
-(IBAction) overlay;
-(IBAction) to_s;

@end

@interface JoinController: MachineViewController

@property IBOutlet UITextField * gamecode;
@property IBOutlet CharacterController * character_view;
@property IBOutlet UIButton * cancel_button;
@property IBOutlet UIButton * continue_button;
@property IBOutlet UITableView * table_team_a;
@property IBOutlet UITableView * table_team_b;
@property IBOutlet UILabel * not_close_enough;

-(IBAction) viewDidLoad;
-(IBAction) viewWillAppear:(id) animated;
-(IBAction) reload_data;
-(IBAction) handle_new_player;
-(IBAction) cancel_new_game:(id) sender;
-(IBAction) dismiss_join:(id) sender;
-(IBAction) textFieldDidBeginEditing:(id) text_field;
-(IBAction) textFieldShouldEndEditing:(id) text_field;
-(IBAction) check_input_text;

@end

@interface Kaitarako: NSObject
-(IBAction) display_name;
-(IBAction) get_remote_display_name;
-(IBAction) email;
-(IBAction) character;
-(IBAction) get_remote_email;
-(IBAction) user_id;
-(IBAction) coordinate;
-(IBAction) get_remote_data:(id) in_key;

@end

@interface Kapa: NSObject
-(IBAction) color;
-(IBAction) name;

@end

@interface KapaFirebaseObject: FirebaseObject
-(IBAction) update_average_location;
-(IBAction) add_player_to_kapa:(id) player;
-(IBAction) nga_kaitakaro_to_firebase;
-(IBAction) count;
-(IBAction) player_names;
-(IBAction) to_s;

@end

@interface Machine: NSObject
-(IBAction) initialize;
-(IBAction) set_state:(id) state;
-(IBAction) segue:(id) name;
-(IBAction) initialize_location_manager;
-(IBAction) set_player:(id) player;
-(IBAction) create_new_game;
-(IBAction) set_game:(id) game;
-(IBAction) create_new_pylon;
-(IBAction) create_new_pouwhenua;
-(IBAction) check_for_game:(id) gamecode;

@end

@interface MenuController: MachineViewController

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

@interface NewController: MachineViewController

@property IBOutlet UILabel * gamecode;
@property IBOutlet CharacterController * character_view;
@property IBOutlet UIButton * continue_button;
@property IBOutlet UIButton * cancel_button;
@property IBOutlet UITableView * table_team_a;
@property IBOutlet UITableView * table_team_b;
@property IBOutlet UILabel * not_close_enough;

-(IBAction) viewDidLoad;
-(IBAction) handle_new_player;
-(IBAction) handle_changed_player;
-(IBAction) cancel_new_game;
-(IBAction) compose_sms;
-(IBAction) continue_button_action:(id) sender;
-(IBAction) dismiss_new;
-(IBAction) add_bot_action:(id) sender;

@end

@interface Player: FirebaseObject
-(IBAction) initialize:(id) args;
-(IBAction) update_location:(id) in_location;
-(IBAction) to_hash;
-(IBAction) to_s;

@end

@interface PlayerCell: UITableViewCell

@property IBOutlet UILabel * player_name;

-(IBAction) viewDidLoad;

@end

@interface ClayPathMaker: NSObject
@end

@interface Scout: Character
-(IBAction) initialize;

@end

@interface SettingsController: MachineViewController
-(IBAction) viewDidLoad;
-(IBAction) dismiss_modal;

@end

@interface SplashController: MachineViewController
-(IBAction) viewDidLoad;
-(IBAction) handleSingleTap:(id) recognizer;

@end

@interface Takaro: NSObject
-(IBAction) initialize:(id) in_uuid;
-(IBAction) start_syncing;
-(IBAction) stop_syncing;
-(IBAction) init_kapa;
-(IBAction) set_up_observers;
-(IBAction) create_new_remote_kapa;
-(IBAction) add_local_player:(id) in_user;
-(IBAction) update_kapa_location:(id) kapa_ref;
-(IBAction) list_player_names_for_index:(id) in_index;
-(IBAction) player_count_for_index:(id) in_index;
-(IBAction) generate_new_id;
-(IBAction) set_initial_pouwhenua;
-(IBAction) start_observing_pouwhenua;
-(IBAction) create_new_pouwhenua:(id) coord;
-(IBAction) get_all_pouwhenua_coords;
-(IBAction) create_bot_player;

@end

@interface String: NSObject
-(IBAction) colorize:(id) color_code;
-(IBAction) red;
-(IBAction) green;
-(IBAction) yellow;
-(IBAction) blue;
-(IBAction) pink;
-(IBAction) light_blue;
-(IBAction) focus;
-(IBAction) to_firebase;

@end

@interface Fixnum: NSObject
-(IBAction) to_firebase;
-(IBAction) to_s;

@end

@interface CIColor: NSObject
-(IBAction) to_firebase;
-(IBAction) to_s;
-(IBAction) to_cgpoint;

@end

@interface CGPoint: NSObject
-(IBAction) to_s;
-(IBAction) to_firebase;
-(IBAction) to_cgpoint;
-(IBAction) to_cgrect;
-(IBAction) to;

@end

@interface CLLocation: NSObject
-(IBAction) to_firebase;
-(IBAction) to_s;
-(IBAction) to_cgpoint;
-(IBAction) to_cgrect;
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) recursive_symbolize_keys:(id) h;

@end

@interface CLLocationCoordinate2D: NSObject
-(IBAction) to_s;
-(IBAction) to_firebase;
-(IBAction) to_cgpoint;
-(IBAction) to_cgrect;
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) recursive_symbolize_keys:(id) h;

@end

@interface MKMapPoint: NSObject
-(IBAction) to_cgpoint;
-(IBAction) to_cgrect;
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) recursive_symbolize_keys:(id) h;
-(IBAction) format_to_location_coord:(id) input;

@end

@interface MKMapRect: NSObject
-(IBAction) to_cgrect;
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) recursive_symbolize_keys:(id) h;
-(IBAction) format_to_location_coord:(id) input;

@end

@interface Hash: NSObject
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) recursive_symbolize_keys:(id) h;
-(IBAction) format_to_location_coord:(id) input;

@end


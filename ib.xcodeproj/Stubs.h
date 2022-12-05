// Generated by IB v1.0.1 gem. Do not edit it manually
// Run `rake ib:open` to refresh

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CFNetwork/CFNetwork.h>
#import <CoreAudio/CoreAudio.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreServices/CoreServices.h>
#import <CoreTelephony/CoreTelephony.h>
#import <CoreText/CoreText.h>
#import <FirebaseAnalytics/FirebaseAnalytics.h>
#import <GoogleAppMeasurement/GoogleAppMeasurement.h>
#import <GoogleAppMeasurementIdentitySupport/GoogleAppMeasurementIdentitySupport.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <SafariServices/SafariServices.h>
#import <Security/Security.h>
#import <StoreKit/StoreKit.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreLocation/CoreLocation.h>
#import <MessageUI/MessageUI.h>
#import <MapKit/MapKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <AuthenticationServices/AuthenticationServices.h>

@interface AppDelegate: UIResponder <UIApplicationDelegate>
@end

@interface CharacterController: UIViewController

@property IBOutlet UIButton * scout_button;

-(IBAction) viewDidLoad;
-(IBAction) select_player_class:(id) sender;
-(IBAction) dismiss_modal;

@end

@interface FirebaseObject: NSObject
-(IBAction) push;
-(IBAction) pull;
-(IBAction) start_observing;
-(IBAction) value_at:(id) node_string;
-(IBAction) update:(id) node_hash;
-(IBAction) delete;
-(IBAction) key;
-(IBAction) to_s;

@end

@interface MachineViewController: UIViewController
-(IBAction) viewDidLoad;

@end

@interface GameController: MachineViewController

@property IBOutlet MKMapView * map_view;
@property IBOutlet UIButton * button_pylon;
@property IBOutlet UILabel * timer_label;
@property IBOutlet UILabel * pouwhenua_label;
@property IBOutlet UILabel * left_score_label;
@property IBOutlet UILabel * right_score_label;

-(IBAction) setup_mapview;
-(IBAction) setup_audio;
-(IBAction) update_pouwhenua_label;
-(IBAction) update_marker_label;
-(IBAction) setup_timers;
-(IBAction) timer_decrement;
-(IBAction) handle_game_over;
-(IBAction) format_seconds:(id) in_seconds;
-(IBAction) calculate_score;
-(IBAction) init_observers;
-(IBAction) viewDidLoad;
-(IBAction) button_down;
-(IBAction) button_up;
-(IBAction) pouwhenua_annotation:(id) annotation;
-(IBAction) kaitarako_annotation:(id) annotation;
-(IBAction) try_render_overlays;
-(IBAction) render_overlays;
-(IBAction) touch_down;
-(IBAction) touch_up;
-(IBAction) touch_out;
-(IBAction) button_color:(id) color;
-(IBAction) player_for_audio:(id) filename;
-(IBAction) play_forward_sound_thread;
-(IBAction) play_forward_sound:(id) context;
-(IBAction) handle_new_marker;
-(IBAction) observe_new_pouwhenua;

@end

@interface GameCountdownController: MachineViewController
-(IBAction) viewDidLoad;

@end

@interface GameOptionsController: MachineViewController
-(IBAction) viewDidLoad;
-(IBAction) select_duration:(id) sender;

@end

@interface InfoViewController: UIViewController

@property IBOutlet UIButton * button_close;

-(IBAction) close:(id) sender;

@end

@interface KaitakaroAnnotation: MKPointAnnotation
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
-(IBAction) voronoi_cells;
-(IBAction) annotations;

@end

@interface Wakawaka: NSObject
-(IBAction) color;
-(IBAction) edges;
-(IBAction) vertices;
-(IBAction) overlay;
-(IBAction) to_s;

@end

@interface JoinExistingController: MachineViewController

@property IBOutlet UITextField * gamecode;
@property IBOutlet UIButton * continue_button;

-(IBAction) viewWillAppear:(id) animated;
-(IBAction) textFieldShouldEndEditing:(id) text_field;
-(IBAction) check_input_text;

@end

@interface KaitakaroFbo: FirebaseObject
-(IBAction) init_observers;
-(IBAction) coordinate;
-(IBAction) check_taiapa;
-(IBAction) placing:(id) in_bool;
-(IBAction) check_placing;
-(IBAction) recalculate_kapa:(id) in_coordinate;
-(IBAction) exit_bounds;
-(IBAction) enter_bounds;
-(IBAction) eject;
-(IBAction) display_name;
-(IBAction) name_and_character;
-(IBAction) data_for_kapa;
-(IBAction) data_for_pouwhenua;
-(IBAction) character;
-(IBAction) kapa;
-(IBAction) deploy_time;
-(IBAction) lifespan_ms;
-(IBAction) pouwhenua_current;
-(IBAction) pouwhenua_decrement;
-(IBAction) pouwhenua_increment;

@end

@interface KapaFbo: FirebaseObject
-(IBAction) add_kaitakaro:(id) in_kaitakaro;
-(IBAction) remove_kaitakaro:(id) in_kaitakaro;
-(IBAction) check_distance:(id) in_coordinate;
-(IBAction) recalculate_coordinate;
-(IBAction) list_display_names_and_classes;
-(IBAction) kaitakaro;
-(IBAction) kaitakaro_hash;
-(IBAction) color;
-(IBAction) coordinate;
-(IBAction) data_for_kaitakaro;
-(IBAction) data_for_pouwhenua;
-(IBAction) format_to_location_coord:(id) input;
-(IBAction) recursive_symbolize_keys:(id) hsh;

@end

@interface LoginController: MachineViewController

@property IBOutlet UIButton * button_apple;
@property IBOutlet UIButton * button_google;

-(IBAction) unwind_to_main_menu:(UIStoryboardSegue*) sender;
-(IBAction) viewDidLoad;
-(IBAction) handle_apple_authorization:(id) sender;
-(IBAction) presentationAnchorForAuthorizationController:(id) controller;
-(IBAction) handle_google_authorization:(id) sender;
-(IBAction) complete_authorization:(id) credential;
-(IBAction) generate_nonce;

@end

@interface Machine: NSObject
-(IBAction) initialize;
-(IBAction) state;
-(IBAction) segue:(id) name;
-(IBAction) initialize_location_manager;
-(IBAction) check_for_game:(id) gamecode;

@end

@interface Marker: FirebaseObject
-(IBAction) initialize_firebase_observers;
-(IBAction) destroy;

@end

@interface MenuController: MachineViewController

@property IBOutlet UIButton * button_login;
@property IBOutlet UIButton * button_logout;
@property IBOutlet UIButton * button_settings;
@property IBOutlet UIButton * button_characters;
@property IBOutlet UIButton * button_game_new;
@property IBOutlet UIButton * button_game_join;

-(IBAction) viewDidLoad;
-(IBAction) controlTouched:(id) sender;
-(IBAction) action_login:(id) sender;
-(IBAction) action_logout:(id) sender;
-(IBAction) action_test:(id) sender;
-(IBAction) action_settings:(id) sender;
-(IBAction) action_characters:(id) sender;
-(IBAction) action_game_new:(id) sender;
-(IBAction) action_game_join:(id) sender;
-(IBAction) login;
-(IBAction) logout;
-(IBAction) action_dismiss_login:(id) segue;

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
-(IBAction) init_observers;
-(IBAction) reload_table_data;
-(IBAction) handle_new_player;
-(IBAction) handle_changed_player;
-(IBAction) cancel_new_game;
-(IBAction) compose_sms;
-(IBAction) dismiss_new;

@end

@interface Notification: NSObject
@end

@interface NSNotificationCenter: NSObject
-(IBAction) observers;
-(IBAction) unobserve:(id) observer;

@end

@interface Player: FirebaseObject
-(IBAction) init_observers;
-(IBAction) coordinate;
-(IBAction) check_taiapa;
-(IBAction) placing:(id) in_bool;
-(IBAction) check_placing;
-(IBAction) recalculate_team:(id) in_coordinate;
-(IBAction) exit_bounds;
-(IBAction) enter_bounds;
-(IBAction) eject;
-(IBAction) display_name;
-(IBAction) updating;
-(IBAction) name_and_character;
-(IBAction) data_for_team;
-(IBAction) data_for_pouwhenua;
-(IBAction) data_for_marker;
-(IBAction) character;
-(IBAction) kapa;
-(IBAction) team;
-(IBAction) deploy_time;
-(IBAction) lifespan_ms;
-(IBAction) pouwhenua_current;
-(IBAction) pouwhenua_decrement;
-(IBAction) pouwhenua_increment;
-(IBAction) marker_decrement;
-(IBAction) marker_increment;

@end

@interface PlayerCell: UITableViewCell

@property IBOutlet UILabel * player_name;

-(IBAction) viewDidLoad;

@end

@interface PouwhenuaFbo: FirebaseObject
-(IBAction) destroy;

@end

@interface ClayPathMaker: NSObject
@end

@interface SelectCharacterController: MachineViewController
-(IBAction) viewDidLoad;
-(IBAction) select_player_class:(id) sender;

@end

@interface SettingsController: MachineViewController
-(IBAction) viewDidLoad;
-(IBAction) dismiss_modal;

@end

@interface SplashController: MachineViewController
-(IBAction) viewDidLoad;
-(IBAction) handleSingleTap:(id) recognizer;

@end

@interface TakaroFbo: FirebaseObject
-(IBAction) initialize_firebase_observers;
-(IBAction) init_states;
-(IBAction) initialize_local_player:(id) in_character;
-(IBAction) create_bot_player;
-(IBAction) add_player:(id) in_player;
-(IBAction) kapa_with_key:(id) in_key;
-(IBAction) get_kapa_for_coordinate:(id) coordinate;
-(IBAction) set_initial_markers;
-(IBAction) player_count_for_index:(id) in_index;
-(IBAction) list_player_names_for_index:(id) in_index;
-(IBAction) calculate_score;
-(IBAction) gamecode;
-(IBAction) duration;
-(IBAction) kapa_hash;
-(IBAction) kapa_array;
-(IBAction) kaitakaro;
-(IBAction) kaitakaro_for_kapa:(id) kapa_key;
-(IBAction) pouwhenua_array;
-(IBAction) pouwhenua_array_for_kapa:(id) kapa_key;
-(IBAction) pouwhenua_array_enabled_only;
-(IBAction) markers_array_enabled_only;
-(IBAction) taiapa;
-(IBAction) playfield;
-(IBAction) waiting;
-(IBAction) playing;
-(IBAction) game_state;
-(IBAction) player_annotations;
-(IBAction) marker_annotations;

@end

@interface Team: FirebaseObject
-(IBAction) add_player:(id) in_player;
-(IBAction) remove_player:(id) in_player;
-(IBAction) check_distance:(id) in_coordinate;
-(IBAction) recalculate_coordinate;
-(IBAction) list_display_names_and_classes;
-(IBAction) players_hash;
-(IBAction) color;
-(IBAction) coordinate;
-(IBAction) data_for_team;
-(IBAction) data_for_pouwhenua;
-(IBAction) format_to_location_coord:(id) input;
-(IBAction) recursive_symbolize_keys:(id) hsh;

@end

@interface TeamManager: NSObject
-(IBAction) initialize;
-(IBAction) add_player_to_team:(id) in_player;
-(IBAction) create_new_team:(id) in_coordinate;
-(IBAction) find_nearest_team:(id) coordinates;

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
-(IBAction) to_hash;

@end

@interface CIColor: NSObject
-(IBAction) to_firebase;
-(IBAction) to_s;
-(IBAction) to_hash;
-(IBAction) to_cgpoint;

@end

@interface CGPoint: NSObject
-(IBAction) to_s;
-(IBAction) to_hash;
-(IBAction) to_cgpoint;
-(IBAction) to_cgrect;
-(IBAction) to_CLLocationCoordinate2D;

@end

@interface CLLocation: NSObject
-(IBAction) to_hash;
-(IBAction) to_s;
-(IBAction) to_cgpoint;
-(IBAction) to_cgrect;
-(IBAction) to_CLLocationCoordinate2D;

@end

@interface CLLocationCoordinate2D: NSObject
-(IBAction) to_s;
-(IBAction) to_hash;
-(IBAction) to_cgpoint;
-(IBAction) to_cgrect;
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) test;
-(IBAction) minutes;
-(IBAction) recursive_symbolize_keys:(id) h;

@end

@interface MKMapPoint: NSObject
-(IBAction) to_cgpoint;
-(IBAction) to_cgrect;
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) test;
-(IBAction) minutes;
-(IBAction) recursive_symbolize_keys:(id) h;
-(IBAction) format_to_location_coord:(id) input;

@end

@interface MKMapRect: NSObject
-(IBAction) to_cgrect;
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) test;
-(IBAction) minutes;
-(IBAction) recursive_symbolize_keys:(id) h;
-(IBAction) format_to_location_coord:(id) input;
-(IBAction) random_color;

@end

@interface Hash: NSObject
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) test;
-(IBAction) minutes;
-(IBAction) recursive_symbolize_keys:(id) h;
-(IBAction) format_to_location_coord:(id) input;
-(IBAction) random_color;
-(IBAction) puts_open;
-(IBAction) puts_close;

@end

@interface Numeric: NSObject
-(IBAction) minutes;
-(IBAction) recursive_symbolize_keys:(id) h;
-(IBAction) format_to_location_coord:(id) input;
-(IBAction) random_color;
-(IBAction) puts_open;
-(IBAction) puts_close;

@end


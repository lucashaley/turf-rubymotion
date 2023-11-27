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
#import <SpriteKit/SpriteKit.h>

@interface AppDelegate: UIResponder <UIApplicationDelegate>
-(IBAction) debug_start_app;
-(IBAction) initialize_bugsnag;

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
-(IBAction) machine;
-(IBAction) app_machine;

@end

@interface MachineViewController: UIViewController
-(IBAction) viewDidLoad;
-(IBAction) machine;
-(IBAction) app_machine;
-(IBAction) login_machine;
-(IBAction) location_machine;
-(IBAction) current_game;

@end

@interface GameController: MachineViewController

@property IBOutlet MKMapView * map_view;
@property IBOutlet UIButton * button_pylon;
@property IBOutlet UILabel * timer_label;
@property IBOutlet UILabel * pouwhenua_label;
@property IBOutlet UILabel * marker_label;
@property IBOutlet UILabel * left_score_label;
@property IBOutlet UILabel * right_score_label;
@property IBOutlet SKView * skview;

-(IBAction) setup_mapview;
-(IBAction) setup_audio;
-(IBAction) update_marker_label;
-(IBAction) setup_timers;
-(IBAction) timer_decrement;
-(IBAction) handle_game_over;
-(IBAction) calculate_score;
-(IBAction) init_observers;
-(IBAction) viewDidLoad;
-(IBAction) button_down;
-(IBAction) button_up;
-(IBAction) marker_annotation:(id) annotation;
-(IBAction) player_annotation:(id) annotation;
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
-(IBAction) format_seconds:(id) in_seconds;

@end

@interface GameCountdownController: MachineViewController
-(IBAction) viewDidLoad;

@end

@interface GameOptionsController: MachineViewController
-(IBAction) select_duration:(id) sender;
-(IBAction) action_continue;
-(IBAction) action_cancel;

@end

@interface InfoViewController: MachineViewController

@property IBOutlet UIButton * button_close;

-(IBAction) close:(id) sender;

@end

@interface MarkerAnnotation: MKPointAnnotation
-(IBAction) description;

@end

@interface MKPolygon: NSObject
@end

@interface PlayerAnnotation: MKPointAnnotation
-(IBAction) description;

@end

@interface PylonAnnotation: NSObject
-(IBAction) initialize:(id) pylon;
-(IBAction) initWithPylon:(id) pylon;
-(IBAction) color;
-(IBAction) pylon_id;
-(IBAction) set_coordinate:(id) coord;
-(IBAction) coordinate;

@end

@interface VoronoiCell: NSObject
-(IBAction) color;
-(IBAction) edges;
-(IBAction) vertices;
-(IBAction) overlay;
-(IBAction) to_s;

@end

@interface VoronoiMap: NSObject
-(IBAction) initialize;
-(IBAction) recalculate_cells;
-(IBAction) voronoi_cells;

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
-(IBAction) motion_print:(id) mp;
-(IBAction) to_hash;

@end

@interface CIColor: NSObject
-(IBAction) to_firebase;
-(IBAction) to_s;
-(IBAction) motion_print:(id) mp;
-(IBAction) to_hash;
-(IBAction) to_cgpoint;

@end

@interface CGPoint: NSObject
-(IBAction) to_s;
-(IBAction) motion_print:(id) mp;
-(IBAction) to_hash;
-(IBAction) to_cgpoint;
-(IBAction) to_cgrect;

@end

@interface CLLocation: NSObject
-(IBAction) to_hash;
-(IBAction) to_s;
-(IBAction) to_cgpoint;
-(IBAction) to_cgrect;
-(IBAction) motion_print:(id) mp;

@end

@interface CLLocationCoordinate2D: NSObject
-(IBAction) to_s;
-(IBAction) to_hash;
-(IBAction) to_cgpoint;
-(IBAction) to_cgrect;
-(IBAction) motion_print:(id) mp;
-(IBAction) to_CLLocationCoordinate2D;

@end

@interface MKMapPoint: NSObject
-(IBAction) to_cgpoint;
-(IBAction) to_hash;
-(IBAction) to_cgrect;
-(IBAction) to_s;
-(IBAction) motion_print:(id) mp;
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) test;
-(IBAction) minutes;

@end

@interface MKMapRect: NSObject
-(IBAction) to_cgrect;
-(IBAction) to_hash;
-(IBAction) to_s;
-(IBAction) motion_print:(id) mp;
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) test;
-(IBAction) minutes;

@end

@interface MKCoordinateSpan: NSObject
-(IBAction) to_hash;
-(IBAction) to_s;
-(IBAction) motion_print:(id) mp;
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) test;
-(IBAction) minutes;
-(IBAction) motion_;

@end

@interface MKCoordinateRegion: NSObject
-(IBAction) to_hash;
-(IBAction) to_s;
-(IBAction) motion_print:(id) mp;
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) test;
-(IBAction) minutes;

@end

@interface MKPolygon: NSObject
-(IBAction) motion_print:(id) mp;
-(IBAction) to_s;
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) test;
-(IBAction) minutes;
-(IBAction) recursive_symbolize_keys:(id) h;

@end

@interface Cell: NSObject
-(IBAction) to_s;
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) test;
-(IBAction) minutes;
-(IBAction) recursive_symbolize_keys:(id) h;

@end

@interface Site: NSObject
-(IBAction) to_s;
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) test;
-(IBAction) minutes;
-(IBAction) recursive_symbolize_keys:(id) h;

@end

@interface Vertex: NSObject
-(IBAction) to_s;
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) test;
-(IBAction) minutes;
-(IBAction) recursive_symbolize_keys:(id) h;

@end

@interface Hash: NSObject
-(IBAction) to_CLLocationCoordinate2D;
-(IBAction) test;
-(IBAction) minutes;
-(IBAction) to_s;
-(IBAction) recursive_symbolize_keys:(id) h;
-(IBAction) format_to_location_coord:(id) input;
-(IBAction) random_color;
-(IBAction) puts_open;
-(IBAction) puts_close;
-(IBAction) breadcrumb:(id) message;

@end

@interface Numeric: NSObject
-(IBAction) minutes;
-(IBAction) to_s;
-(IBAction) recursive_symbolize_keys:(id) h;
-(IBAction) format_to_location_coord:(id) input;
-(IBAction) random_color;
-(IBAction) puts_open;
-(IBAction) puts_close;
-(IBAction) breadcrumb:(id) message;

@end

@interface FIRAuth: NSObject
-(IBAction) to_s;
-(IBAction) recursive_symbolize_keys:(id) h;
-(IBAction) format_to_location_coord:(id) input;
-(IBAction) random_color;
-(IBAction) puts_open;
-(IBAction) puts_close;
-(IBAction) breadcrumb:(id) message;

@end

@interface FIRUser: NSObject
-(IBAction) to_s;
-(IBAction) recursive_symbolize_keys:(id) h;
-(IBAction) format_to_location_coord:(id) input;
-(IBAction) random_color;
-(IBAction) puts_open;
-(IBAction) puts_close;
-(IBAction) breadcrumb:(id) message;

@end

@interface FIRUserInfo: NSObject
-(IBAction) to_s;
-(IBAction) recursive_symbolize_keys:(id) h;
-(IBAction) format_to_location_coord:(id) input;
-(IBAction) random_color;
-(IBAction) puts_open;
-(IBAction) puts_close;
-(IBAction) breadcrumb:(id) message;

@end

@interface FIRUserInfoImpl: NSObject
-(IBAction) recursive_symbolize_keys:(id) h;
-(IBAction) format_to_location_coord:(id) input;
-(IBAction) random_color;
-(IBAction) puts_open;
-(IBAction) puts_close;
-(IBAction) breadcrumb:(id) message;

@end

@interface VoronoiSite: Site
-(IBAction) to_s;

@end

@interface JoinExistingController: MachineViewController

@property IBOutlet UITextField * gamecode_label;
@property IBOutlet UIButton * continue_button;
@property IBOutlet UIButton * cancel_button;

-(IBAction) viewDidLoad;
-(IBAction) viewWillAppear:(id) animated;
-(IBAction) textFieldShouldEndEditing:(id) text_field;
-(IBAction) check_input_text;
-(IBAction) cancel_new_game;

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
-(IBAction) transition_splash_to_main_menu;
-(IBAction) transition_main_menu_to_credits;
-(IBAction) transition_credits_to_main_menu;
-(IBAction) transition_main_menu_to_settings;
-(IBAction) transition_settings_to_main_menu;
-(IBAction) transition_main_menu_to_characters;
-(IBAction) transition_characters_to_main_menu;
-(IBAction) transition_main_menu_to_how_to_play;
-(IBAction) transition_how_to_play_to_main_menu;
-(IBAction) transition_main_menu_to_log_in;
-(IBAction) transition_log_in_to_main_menu;
-(IBAction) transition_main_menu_to_game_options;
-(IBAction) transition_game_options_to_main_menu;
-(IBAction) transition_game_options_to_character_select;
-(IBAction) transition_main_menu_to_game_join;
-(IBAction) transition_game_join_to_main_menu;
-(IBAction) transition_game_join_to_character_select;
-(IBAction) transition_character_select_to_main_menu;
-(IBAction) transition_character_select_to_waiting_room;
-(IBAction) transition_waiting_room_to_main_menu;
-(IBAction) transition_waiting_room_to_prep;
-(IBAction) transition_prep_to_game;
-(IBAction) transition_waiting_room_to_game;
-(IBAction) transition_game_to_main_menu;
-(IBAction) transition_game_to_game_over;
-(IBAction) transition_game_over_to_main_menu;
-(IBAction) state;
-(IBAction) segue:(id) name;
-(IBAction) game;
-(IBAction) dismiss_modal;
-(IBAction) initialize_location_manager;
-(IBAction) initialize_character_classes;
-(IBAction) check_for_game:(id) gamecode;
-(IBAction) create_new_game;
-(IBAction) generate_gamecode;
-(IBAction) destroy_current_game;

@end

@interface MachineLocation: NSObject
-(IBAction) initialize;
-(IBAction) initialize_location_manager;

@end

@interface MachineLogin: NSObject
-(IBAction) initialize;
-(IBAction) initialize_firebase_auth;
-(IBAction) auth_state_changed;

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
@property IBOutlet UIButton * button_credits;
@property IBOutlet UIButton * button_how_to_play;

-(IBAction) viewDidLoad;
-(IBAction) controlTouched:(id) sender;
-(IBAction) buttons_logged_in;
-(IBAction) buttons_logged_out;
-(IBAction) action_login:(id) sender;
-(IBAction) action_logout:(id) sender;
-(IBAction) action_test:(id) sender;
-(IBAction) action_credits:(id) sender;
-(IBAction) action_settings:(id) sender;
-(IBAction) action_characters:(id) sender;
-(IBAction) action_game_new:(id) sender;
-(IBAction) action_game_join:(id) sender;
-(IBAction) action_dismiss_login:(id) segue;

@end

@interface SelectCharacterController: MachineViewController
-(IBAction) viewDidLoad;
-(IBAction) select_player_class:(id) sender;

@end

@interface NewController: MachineViewController

@property IBOutlet UILabel * gamecode_label;
@property IBOutlet SelectCharacterController * character_view;
@property IBOutlet UIButton * continue_button;
@property IBOutlet UIButton * button_continue;
@property IBOutlet UIButton * cancel_button;
@property IBOutlet UIButton * button_pylon;
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

@end

@interface Notification: NSObject
@end

@interface NSNotificationCenter: NSObject
-(IBAction) observers;
-(IBAction) unobserve:(id) observer;

@end

@interface Player: FirebaseObject
-(IBAction) initialize_state_machine;
-(IBAction) initialize_coordinate_machine;
-(IBAction) initialize_observers;
-(IBAction) initialize_firebase_observers;
-(IBAction) coordinate;
-(IBAction) check_taiapa;
-(IBAction) placing:(id) in_bool;
-(IBAction) check_placing;
-(IBAction) exit_bounds;
-(IBAction) enter_bounds;
-(IBAction) eject;
-(IBAction) display_name;
-(IBAction) updating;
-(IBAction) name_and_character;
-(IBAction) data_for_team;
-(IBAction) data_for_marker;
-(IBAction) character;
-(IBAction) color;
-(IBAction) team;
-(IBAction) deploy_time;
-(IBAction) lifespan;
-(IBAction) marker_decrement;
-(IBAction) marker_increment;

@end

@interface PlayerCell: UITableViewCell

@property IBOutlet UILabel * player_name;

-(IBAction) viewDidLoad;

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
-(IBAction) initialize_state_machine;
-(IBAction) initialize_local_player:(id) in_character;
-(IBAction) prepare_local_variables;
-(IBAction) create_bot_player;
-(IBAction) kapa_with_key:(id) in_key;
-(IBAction) get_kapa_for_coordinate:(id) coordinate;
-(IBAction) set_initial_markers;
-(IBAction) player_count_for_index:(id) in_index;
-(IBAction) list_player_names_for_index:(id) in_index;
-(IBAction) gamecode;
-(IBAction) duration;
-(IBAction) markers_array_enabled_only;
-(IBAction) playfield_region;
-(IBAction) game_state;
-(IBAction) create_overlays;
-(IBAction) create_overlay_for_cell:(id) cell;
-(IBAction) create_map_point_for_halfedge:(id) halfedge;
-(IBAction) local_player_state:(id) in_state;
-(IBAction) player_annotations;
-(IBAction) marker_annotations;
-(IBAction) hash_to_CLLocationCoordinate2D:(id) in_hash;
-(IBAction) hash_to_MKCoordinateRegion:(id) in_hash;

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


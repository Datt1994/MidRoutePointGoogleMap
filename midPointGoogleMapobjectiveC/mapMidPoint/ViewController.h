

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "AFNetworking.h"

@import GoogleMaps;

typedef void(^completion_handler_t)(NSMutableDictionary *, NSError*error, long code);
typedef void(^user_completion_block)(NSDictionary *user,NSString *, int status);

@interface ViewController : UIViewController
@property (strong, nonatomic) IBOutlet GMSMapView *mapView;
-(void)googleMapsAPICall:(user_completion_block)completion;
@end


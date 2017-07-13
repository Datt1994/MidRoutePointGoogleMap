

#import "ViewController.h"

@interface ViewController (){
    CLLocationCoordinate2D position;
    CLLocationCoordinate2D position1;
}

@end

@implementation ViewController
@synthesize mapView;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self displayMap];
    
    [self getRoutes];
    position= CLLocationCoordinate2DMake(23.0590, 72.5368);
    position1= CLLocationCoordinate2DMake(21.1702, 72.8311);
    
}
-(void)displayMap{
    [mapView clear];
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:23.0590
                                                            longitude:72.5368
                                                                 zoom:6];
    mapView.camera = camera;
}
-(void)viewDidAppear:(BOOL)animated
{
    GMSMarker *marker = [GMSMarker markerWithPosition:position];
    marker.map = mapView;
    
    GMSMarker *marker1 = [GMSMarker markerWithPosition:position1];
    marker1.map = mapView;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)getRoutes
{
    @try{
        [self googleMapsAPICall:^(NSDictionary *user, NSString *str, int status) {
            if (status == 1) {
                GMSMutablePath *paths = [GMSMutablePath path];
                NSInteger count = [[[[[[user objectForKey:@"routes"] objectAtIndex:0] objectForKey:@"legs"] objectAtIndex:0] objectForKey:@"steps"]  count];
                    for (int i = 0; i < count; i++)
                    {

                        GMSPath *path = [GMSPath pathFromEncodedPath:[[[[[[[[user objectForKey:@"routes"] objectAtIndex:0] objectForKey:@"legs"] objectAtIndex:0] objectForKey:@"steps"] objectAtIndex:i] objectForKey:@"polyline"] valueForKey:@"points"]];

                        for (int j = 0; j<path.count; j++) {
                             [paths addCoordinate:[path coordinateAtIndex:j]];
                        }
                    }
     
                    double totalDistance = [self findTotalDistanceOfPath:paths];
                    GMSMarker *marker = [GMSMarker markerWithPosition:[self findMiddlePointInPath:paths distance:totalDistance threshold:10]];
                    marker.map = mapView;
                    
                    GMSPolyline *line = [GMSPolyline polylineWithPath:paths];
                    line.strokeWidth = 2.0f;
                    line.map = self.mapView;

            }
            else {
            }
        }];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception At: %s %d %s %s %@", __FILE__, __LINE__, __PRETTY_FUNCTION__, __FUNCTION__,exception);
    }
}

-(CLLocationCoordinate2D)findMiddlePointInPath:(GMSMutablePath *)path distance :(double)totalDistance threshold:(int)threshold{
    threshold = threshold;
    double numberOfCoords = path.count;
    double halfDistance = totalDistance/2;
    double midDistance = 0.0;
    if(numberOfCoords > 1){
        for (int i = 0; i < numberOfCoords-1; i++) {
            
            CLLocationCoordinate2D currentCoord = [path coordinateAtIndex:i];
            CLLocationCoordinate2D nextCoord = [path coordinateAtIndex: i+1];
            
            CLLocationDistance newDistance =  GMSGeometryDistance(currentCoord,nextCoord);
            midDistance = midDistance + newDistance;
            
            if (fabs(midDistance - halfDistance) < threshold){ //Found the middle point in route
                return nextCoord;
            }
        }
    }
    return [self findMiddlePointInPath:path distance:totalDistance threshold:2*threshold];
}

-(double)findTotalDistanceOfPath:(GMSMutablePath *)path{
    NSLog(@"%lu",(unsigned long)path.count);
    
    double numberOfCoords = path.count;
    double totalDistance = 0.0;
    if(numberOfCoords > 1){
        for (int i = 0; i < numberOfCoords-1; i++) {
            
            CLLocationCoordinate2D currentCoord = [path coordinateAtIndex:i];
            CLLocationCoordinate2D nextCoord = [path coordinateAtIndex: i+1];
            
            CLLocationDistance newDistance =  GMSGeometryDistance(currentCoord,nextCoord);
            totalDistance = totalDistance + newDistance;
        }
    }
    return totalDistance;
}

-(void)googleMapsAPICall:(user_completion_block)completion
{
    @try{
        
        NSString *url_String = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/directions/json?"];
        
        NSMutableDictionary *parameters=[[NSMutableDictionary alloc]init];
        [parameters setValue:@"23.0590,72.5368" forKey:@"origin"];
        [parameters setValue: @"21.1702, 72.8311" forKey:@"destination"];
        [parameters setValue:@"driving" forKey:@"mode"];
        [parameters setValue:@"AIzaSyC0wK2p24XbUFF0v3A1RdbxWRTuQb12hJY" forKey:@"key"];
        
        [self callGetWebService:url_String andDictionary:parameters completion:^(NSDictionary* responseDict, NSError*error, long code)
         {
             if(error)
             {
                 if(completion)
                 {
                     completion(responseDict,@"OOPS Seems like something is wrong with server",-1);
                 }
                 
             }
             else{
                 if(completion)
                 {
                     NSLog(@"%@",responseDict);
                     if([responseDict valueForKey:@"routes"])
                     {
                         completion(responseDict,@"Got Response ",1);
                     }
                 }
             }
         }];
    } @catch (NSException *exception) {
        NSLog(@"Exception At: %s %d %s %s %@", __FILE__, __LINE__, __PRETTY_FUNCTION__, __FUNCTION__,exception);
    }
    
    
}
-(void)callGetWebService:(NSString *)urlStr andDictionary:(NSDictionary *)parameter completion:(completion_handler_t)completion{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"text/html" forHTTPHeaderField:@"Content-Type"];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    
    [manager GET:urlStr parameters: parameter success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completion) {
            long code=200;
            NSDictionary* json = responseObject;
            completion([json mutableCopy], nil,code);
        }
    }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            long code=(long)[[[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
            completion([operation responseObject], error,code);
        }
    }
     ];
    
}

@end

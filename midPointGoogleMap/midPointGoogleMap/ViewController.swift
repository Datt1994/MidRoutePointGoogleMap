//
//  ViewController.swift
//  midPointGoogleMap
//
//  Created by datt on 6/14/17.
//  Copyright © 2017 datt. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController {
    var mapView : GMSMapView?
    var startLat,startLong,endLat,endLong : Double?
    override func viewDidLoad() {
        super.viewDidLoad()
//        startLat = 37.2358
//        startLong = -121.9624
//        endLat = 37.2872
//        endLong = -121.9500
        startLat = 23.0590
        startLong = 72.5368
        endLat = 21.1702
        endLong = 72.8311
        
        let camera = GMSCameraPosition.camera(withLatitude: startLat!, longitude: startLong!, zoom: 10)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        view = mapView
        // Creates a marker in the center of the map.
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: startLat!, longitude: startLong!)
        marker.map = mapView
        
        let marker2 = GMSMarker()
        marker2.position = CLLocationCoordinate2D(latitude: endLat!, longitude: endLong!)
        marker2.map = mapView
        
        drawPath(startLat: startLat!, startLong: startLong!, endLat: endLat!, endLong: endLong!)
        // Do any additional setup after loading the view, typically from a nib.
    }
    func drawPath(startLat: CLLocationDegrees , startLong : CLLocationDegrees, endLat : CLLocationDegrees , endLong : CLLocationDegrees)
    {
        let origin = "\(startLat),\(startLong)"
        let destination = "\(endLat),\(endLong)"
        
        
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=driving&key=AIzaSyAzk3IHdq3zsyxEXKaGXnoE1Td5-xdr7sk"
        
        requestGetMethod(apiUrl: url) { (succes, response) in
            
            //  print(response as AnyObject)
            let json = response as AnyObject
            let routes = json["routes"] as! [Any]
            
            
            
            for route in routes
            {
                DispatchQueue.main.async {
                let routeOverviewPolyline = (((route as! [String:AnyObject])["legs"] as! [[String:AnyObject]])[0]["steps"] as! [[String:AnyObject]])
                    let path = GMSMutablePath()
                  //  var points : String = ""
                for i in 0 ..< routeOverviewPolyline.count
                {
                    for j in 0 ..< Int((GMSPath.init(fromEncodedPath: (routeOverviewPolyline[i]["polyline"]?["points"] as! String))?.count())!)
                    {
                         path.add((GMSPath.init(fromEncodedPath: (routeOverviewPolyline[i]["polyline"]?["points"] as! String))?.coordinate(at: UInt(j)))!)
                    }
                    
//                    points =  points + (routeOverviewPolyline[i]["polyline"]?["points"] as! String)
                }
                    
               // let points = routeOverviewPolyline["points"]! as! String
               
                let totalDistance = self.findTotalDistanceOfPath(path: path)
                

                
                
                    let marker = GMSMarker()
                    marker.position = self.findMiddlePointInPath(path ,totalDistance:totalDistance)!
                marker.map = self.mapView
                
                
                    let polyline = GMSPolyline.init(path: path)
                    //polyline.strokeWidth = 3
                    polyline.map = self.mapView
                }
                
            }
            
            
            
        }
        
    }
    func findTotalDistanceOfPath(path: GMSPath) -> Double {
        
        let numberOfCoords = path.count()
        
        var totalDistance = 0.0
        
        if numberOfCoords > 1 {
            
            var index = 0 as UInt
            
            while index < numberOfCoords - 1{
                
                //1.1 cal the next distance

                let currentCoord = path.coordinate(at: index)
               
                let nextCoord = path.coordinate(at: index + 1)
               
                let newDistance = GMSGeometryDistance(currentCoord,nextCoord)
                if index == numberOfCoords - 2
                {
                    
                }
                totalDistance = totalDistance + newDistance
                
                index = index + 1
                
                }

       }
    return totalDistance
        
    }

    
    func findMiddlePointInPath(_ path: GMSPath ,totalDistance distance:Double , threadhold:Int? = 10) -> CLLocationCoordinate2D? {
        
        let numberOfCoords = path.count()
        
        let halfDistance = distance/2
        
        let threadhold = threadhold //10 meters
        
        var midDistance = 0.0
        
        if numberOfCoords > 1 {
            
            var index = 0 as UInt
            
            while index  < numberOfCoords - 1{
                
                //1.1 cal the next distance
                
                let currentCoord = path.coordinate(at: index)
                
                let nextCoord = path.coordinate(at: index + 1)
                
                let newDistance = GMSGeometryDistance(currentCoord, nextCoord)
                
                midDistance = midDistance + newDistance
                if index == numberOfCoords - 2
                {
                    
                }
                if fabs(midDistance - halfDistance) < Double(threadhold!) { //Found the middle point in route
                    
                    return nextCoord
                    
                }
                
                index = index + 1
                
            }
            
        }
        return findMiddlePointInPath(path, totalDistance: distance, threadhold: threadhold! * 2) //Return nil if we cannot find middle point in path for some reason
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    open func requestGetMethod(apiUrl : String , completion: @escaping (_ success: Bool, _ object: AnyObject?) -> ()) {
       // if !isInternetAvailable(){return}
        var request = URLRequest(url: URL(string: apiUrl)!)
        // Set request HTTP method to GET. It could be POST as well
        request.httpMethod = "GET"//method as String
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task: URLSessionDataTask = session.dataTask(with : request as URLRequest, completionHandler: { (data, response, error) -> Void in
            
            // Check for error
            if error != nil
            {
                print("error=\(error)")
                return
            }
            // Print out response string
            //            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            //            print("responseString = \(responseString)")
            
            do {
                if let convertedJsonIntoDict = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] {
                    // Print out dictionary
                    // print(convertedJsonIntoDict)
                    completion(true, convertedJsonIntoDict as AnyObject?)
                }
                else{
                    completion(false, nil)
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        })
        task.resume()
    }

}


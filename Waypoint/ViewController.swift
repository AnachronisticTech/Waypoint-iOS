//
//  ViewController.swift
//  Waypoint
//
//  Created by Daniel Marriner on 27/07/2019.
//  Copyright © 2019 Daniel Marriner. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var locationsArray = [StoredAnnotation]()
    var overlayList = [[String: MKOverlay]]()
    let impact = UIImpactFeedbackGenerator()
    var trackPosition = false
    var initialTrack = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Clear all stored data
//        let domain = Bundle.main.bundleIdentifier!
//        UserDefaults.standard.removePersistentDomain(forName: domain)
//        UserDefaults.standard.synchronize()
        
        // Set up map view
        mapView.delegate = self

        // Restore saved waypoints
        if UserDefaults.standard.object(forKey:"locationsArray") != nil {
            print("Stuff detected")
            guard let locationsData = UserDefaults.standard.object(forKey: "locationsArray") as? Data else {
                return
            }
            guard let locations = try? PropertyListDecoder().decode([StoredAnnotation].self, from: locationsData) else {
                return
            }
//            print(locations)
            locationsArray = locations
            for i in locations {
                let annotation = MKPointAnnotation()
                let coordinate = CLLocationCoordinate2D(latitude: i.lat, longitude: i.lon)
                annotation.coordinate = coordinate
                annotation.title = (i.subLocality) + " " + (i.country)
//                print(annotation.title as Any)
//                print("(\(i.lat), \(i.lon))")
                mapView.addAnnotation(annotation)
                let region = CLCircularRegion(center: coordinate, radius: 20, identifier: i.subLocality + " " + i.country)
                let circle = MKCircle(center: coordinate, radius: 20)
                circle.title = "\(i.lat), \(i.lon)"
                self.overlayList.append([circle.title!: circle])
                self.mapView.addOverlay(circle)
                region.notifyOnEntry = true
                self.locationManager.startMonitoring(for: region)
            }
        }

        //Get current location
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()

        // Register long press event
//        let uilpgr = UITapGestureRecognizer(target: self, action: #selector(ViewController.longPress(gestureRecognizer:)))
        let uilpgr = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.longPress(gestureRecognizer:)))
        uilpgr.minimumPressDuration = 1
        mapView.addGestureRecognizer(uilpgr)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation is MKUserLocation {
            return
        }
        let annotation = view.annotation as! MKPointAnnotation
        let lat = annotation.coordinate.latitude as CLLocationDegrees
        let lon = annotation.coordinate.longitude as CLLocationDegrees
        let location = locationsArray.first { $0.lat == lat && $0.lon == lon }!
        let title = "\(location.lat), \(location.lon)"
        let overlays = self.overlayList.filter { $0[title] != nil }
        var list = [MKOverlay]()
        for i in overlays {
            list.append(contentsOf: Array(i.values))
        }
        mapView.removeOverlays(list)
        self.overlayList = self.overlayList.filter { $0[title] == nil }
        locationsArray.removeAll {$0.lat == lat && $0.lon == lon }
        UserDefaults.standard.set(try? PropertyListEncoder().encode(self.locationsArray), forKey: "locationsArray")
        mapView.removeAnnotation(annotation)
        impact.impactOccurred()
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let aRenderer = MKCircleRenderer(overlay: overlay)
        aRenderer.fillColor = UIColor(red: 0, green: 0.5, blue: 1, alpha: 0.2)
        aRenderer.strokeColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.7)
        aRenderer.lineWidth = 1
        return aRenderer
    }
    
    @objc func longPress(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            
            let selectedLocation: CLLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            CLGeocoder().reverseGeocodeLocation(selectedLocation) { (placemarks, error) in
                if let e = error {
                    print(e)
                } else {
                    if let placemark = placemarks?[0] {
                        var subThoroughfare = ""
                        if placemark.subThoroughfare != nil {
                            subThoroughfare = placemark.subThoroughfare!
                        }
                        var thoroughfare = ""
                        if placemark.thoroughfare != nil {
                            thoroughfare = placemark.thoroughfare!
                        }
                        var subLocality = ""
                        if placemark.subLocality != nil {
                            subLocality = placemark.subLocality!
                        }
                        var subAdministrativeArea = ""
                        if placemark.subAdministrativeArea != nil {
                            subAdministrativeArea = placemark.subAdministrativeArea!
                        }
                        var postalCode = ""
                        if placemark.postalCode != nil {
                            postalCode = placemark.postalCode!
                        }
                        var country = ""
                        if placemark.country != nil {
                            country = placemark.country!
                        }
                        
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = coordinate
                        annotation.title = subLocality + " " + country
                        self.mapView.addAnnotation(annotation)
                        let region = CLCircularRegion(center: coordinate, radius: 20, identifier: subLocality + " " + country)
                        let circle = MKCircle(center: coordinate, radius: 20)
                        circle.title = "\(coordinate.latitude), \(coordinate.longitude)"
                        self.overlayList.append([circle.title!: circle])
                        self.mapView.addOverlay(circle)
                        region.notifyOnEntry = true
                        self.locationManager.startMonitoring(for: region)
                        
                        self.locationsArray.append(StoredAnnotation(lat: coordinate.latitude, lon: coordinate.longitude, subThoroughfare: subThoroughfare, thoroughfare: thoroughfare, subLocality: subLocality, subAdminArea: subAdministrativeArea, postCode: postalCode, country: country))
                        
                        UserDefaults.standard.set(try? PropertyListEncoder().encode(self.locationsArray), forKey: "locationsArray")
                        self.impact.impactOccurred()
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Within 20m of target")
        self.impact.impactOccurred()
        self.impact.impactOccurred()
        self.impact.impactOccurred()
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region")
        self.impact.impactOccurred()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation: CLLocation = locations[0]
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        let coords: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region: MKCoordinateRegion = MKCoordinateRegion(center: coords, span: span)
        if trackPosition || initialTrack {
            mapView.setRegion(region, animated: true)
            initialTrack = false
        }
    }
    
    struct StoredAnnotation: Codable {
        
        var lat: CLLocationDegrees
        var lon: CLLocationDegrees
        var subThoroughfare: String
        var thoroughfare: String
        var subLocality: String
        var subAdminArea: String
        var postCode: String
        var country: String
        
        init(lat: CLLocationDegrees, lon: CLLocationDegrees, subThoroughfare: String, thoroughfare: String, subLocality: String, subAdminArea: String, postCode: String, country: String) {
            self.lat = lat
            self.lon = lon
            self.subThoroughfare = subThoroughfare
            self.thoroughfare = thoroughfare
            self.subLocality = subLocality
            self.subAdminArea = subAdminArea
            self.postCode = postCode
            self.country = country
        }
    }

}


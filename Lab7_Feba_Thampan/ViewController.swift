//
//  ViewController.swift
//  Lab7_Feba_Thampan
//
//  Created by user234888 on 11/8/23.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController,CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var map: MKMapView! // The map
    
    @IBOutlet weak var startTripButton: UIButton! //Start Trip Button
    @IBOutlet weak var stopTripButton: UIButton! // Stop trip Button
    @IBOutlet weak var currentSpeedLabel: UILabel! //Label for current speed
    @IBOutlet weak var maxSpeedLabel: UILabel! //Label for maximum speed
    @IBOutlet weak var averageSpeedLabel: UILabel! //Label for average speed
    @IBOutlet weak var distanceLabel: UILabel! //Label for distance
    @IBOutlet weak var maxAccelerationLabel: UILabel! //Label for max acceleration
    
    @IBOutlet weak var overSpeedingIndicator: UILabel! //Label changes color when overspeeding
    @IBOutlet weak var tripStatus: UILabel! //Label changes color to green when trip starts and gray when trip ends
    
    var tripStartTime: Date? //Start time
    var isTripInProgress = false //Flag for changing trip status label color
    var currentSpeed: CLLocationSpeed = 0.0 //variable to hold current speed
    var maxSpeed: CLLocationSpeed = 0.0 //variable to hold maximum speed acquired
    var totalDistance: CLLocationDistance = 0.0 //variable to hold total distance value
    var maxAcceleration: Double = 0.0 //variable to hold maximum acceleration value
    let regionInMeters: Double = 5000 //zoom level in map
    
    var locationManager = CLLocationManager ()
    var locations: [CLLocation] = [] //Array to hold locations
    var distanceBeforeExceedingSpeedLimit = 0.0 //distance before exceeding speed limit for the first time in current trip
    var hasCalculatedDistanceBeforeOverspeed = false //helper flag
    var userPath: [CLLocationCoordinate2D] = [] //path for polyline
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //Make map visable and set initial location
        setToInitials() //sets initial values to all labels and variables
        locationManager.delegate = self
        map.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        map.showsUserLocation = true
    }
    
    /**
     *  Sets all variables and labels to initial values
     *  Sets start location to Conestoga Waterloo
     */
    func setToInitials(){
        currentSpeedLabel.text = "0 km/h"
        maxSpeedLabel.text = "0 km/h"
        averageSpeedLabel.text = "0 km/h"
        distanceLabel.text = "0 km"
        maxAccelerationLabel.text = "0 m/s^2"
        stopTripButton.isEnabled = false // Stop Trip Button is enabled only when Start Trip is clicked
        tripStatus.backgroundColor = UIColor.lightGray
        overSpeedingIndicator.backgroundColor = UIColor.clear
        locations.removeAll()
        userPath.removeAll()
        isTripInProgress = false
        currentSpeed = 0.0
        maxSpeed = 0.0
        totalDistance = 0.0
        maxAcceleration = 0.0
        distanceBeforeExceedingSpeedLimit = 0.0
        hasCalculatedDistanceBeforeOverspeed = false
        overSpeedingIndicator.text = ""
        // Set the initial location to Conestoga College, Waterloo
        let initialLocation = CLLocationCoordinate2D(latitude: 43.4681, longitude: -80.5449)
        let region = MKCoordinateRegion(center: initialLocation, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        map.setRegion(region, animated: true)
    }
    /**
     * Action for Start Trip Button
     */
    @IBAction func startTrip(_ sender: Any) {
        tripStartTime = Date()
        
        //sets all initial values
        setToInitials()
        
        //Updates locations
        locationManager.startUpdatingLocation()
        
        //Changes label color to green when trip starts
        tripStatus.backgroundColor = UIColor.green
        stopTripButton.isEnabled = true
        
        //zooms in to user location
        centerViewOnUserLocation()
        isTripInProgress = true
    }
    
    /**
     * Action for Stop Trip Button
     */
    @IBAction func stopTrip(_ sender: Any) {
        isTripInProgress = false
        
        //stop updating location
        locationManager.stopUpdatingLocation()
        
        //change label color to gray when trip stops
        tripStatus.backgroundColor = UIColor.gray
        stopTripButton.isEnabled = false
        
        //when trip stops, current speed is zero
        currentSpeedLabel.text = "0 km/h"
        
        //clear overspeeding label color to clear
        overSpeedingIndicator.backgroundColor = UIColor.clear
        
        //Log to console
        print("Max speed == \(maxSpeed)")
        let avg = averageSpeedLabel.text!
        print("Average speed == \(avg)")
        let dist = distanceLabel.text!
        print("Distance Travelled == \(dist)")
        
        if !hasCalculatedDistanceBeforeOverspeed {
            //if the flag is false, it means that the user hasn't crossed speed limit in this trip
            print("Distance Travelled Before Exceeding Speed Limit == \(dist)")
        }else{
            print("Distance Travelled Before Exceeding Speed Limit == \(distanceBeforeExceedingSpeedLimit)")
        }
    }
    
    /**
     * Zooms in to user's location
     */
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            map.setRegion(region, animated: true)
        }
    }
    
    /**
     * Location Manager
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //Do things only when trip is in progress
        if(isTripInProgress){
            guard let location = locations.last else { return }
            let centre =           CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion.init(center: centre, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            map.setRegion(region, animated: true)
            
            //Calculate speed, distance, etc.
            calculateTripVariables(newLocation: location)
            
            //Update UI labels
            updateDisplayLabels()
            
            // Add the new location to the userPath array for the polyline
            userPath.append(location.coordinate)
            createUserPathInMap()
            
        }
    }
    
    /**
     * Update all the labels displayed
     */
    func updateDisplayLabels() {
        
        currentSpeedLabel.text = String(format: "%.2f km/h", currentSpeed)
        maxSpeedLabel.text = String(format: "%.2f km/h", maxSpeed)
        
        // If locations array has some value, then calculate average. Else it is 0.
        if locations.count > 1 {
            let speedsArray = locations.map { $0.speed * 3.6 } // Convert speeds to km/h
            
            // Average calculated by summing up all speeds and diving by array length
            let averageSpeed = speedsArray.reduce(0, +) / Double(speedsArray.count)
            averageSpeedLabel.text = String(format: "%.2f km/h", averageSpeed)
        } else {
            averageSpeedLabel.text = "0 km/h"
        }
        
        // Display distance in kms
        distanceLabel.text = String(format: "%.2f km", totalDistance / 1000)
        maxAccelerationLabel.text = String(format: "%.2f m/s^2", maxAcceleration)
        
        // If current speed exceeds 115, display label in red
        if currentSpeed > 115 {
            
            // If it is the first time in this trip exceeding speed limit, then capture distance travelled before overspeeding
            if !hasCalculatedDistanceBeforeOverspeed{
                distanceBeforeExceedingSpeedLimit = totalDistance/1000
                hasCalculatedDistanceBeforeOverspeed = true
            }
            overSpeedingIndicator.backgroundColor = UIColor.red
        } else {
            
            // If speed reduces, remove label color red
            overSpeedingIndicator.backgroundColor = UIColor.clear
        }
        
        //Logs current speed
        print("Current speed == \(currentSpeed)")
    }
    
    /**
     * Calculates current speed, max speed, total distance, max acceleration
     */
    func calculateTripVariables(newLocation: CLLocation) {
        if let startTime = tripStartTime {
            let currentTime = Date()
            let timeInterval = currentTime.timeIntervalSince(startTime)
            
            // Set current speed in km/h
            let speed = newLocation.speed * 3.6 // m/s to km/h
            currentSpeed = speed
            
            // If current speed is more than existing max speed, change max speed to new value
            if speed > maxSpeed {
                maxSpeed = speed
            }
            
            // Append the new location to the array
            locations.append(newLocation)
            
            // Calculate distance based on the array of locations
            if locations.count > 1 {
                totalDistance += newLocation.distance(from: locations[locations.count - 2])
            }
            
            // Calculate acceleration (absolute value)
            let previousSpeed = locations.count > 1 ? locations[locations.count - 2].speed * 3.6 : 0.0
            let acceleration = abs((speed - previousSpeed) / timeInterval)
            if acceleration > maxAcceleration {
                maxAcceleration = acceleration
            }
        }
        
    }
    
    /**
     * Uses polyline to show the path user has traversed
     */
    func createUserPathInMap() {
        // Remove any existing overlays
        map.removeOverlays(map.overlays)
        
        // Create a polyline with the user's path
        let polyline = MKPolyline(coordinates: userPath, count: userPath.count)
        
        // Add the polyline to the map
        map.addOverlay(polyline)
        
        // Zoom to the user's path region
        if !userPath.isEmpty {
            let region = MKCoordinateRegion(center: userPath.last!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            map.setRegion(region, animated: true)
        }
    }
    
    // MKMapViewDelegate method to render the overlay (polyline)
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 3
            return renderer
        }
        return MKOverlayRenderer()
    }
    
}


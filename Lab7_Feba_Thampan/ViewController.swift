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
    
    @IBOutlet weak var map: MKMapView!
    
    @IBOutlet weak var startTripButton: UIButton!
    @IBOutlet weak var stopTripButton: UIButton!
    @IBOutlet weak var currentSpeedLabel: UILabel!
    @IBOutlet weak var maxSpeedLabel: UILabel!
    @IBOutlet weak var averageSpeedLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var maxAccelerationLabel: UILabel!
    
    @IBOutlet weak var overSpeedingIndicator: UILabel!
    @IBOutlet weak var tripStatus: UILabel!
    
    var tripStartTime: Date?
    var isTripInProgress = false
    var currentSpeed: CLLocationSpeed = 0.0
    var maxSpeed: CLLocationSpeed = 0.0
    var totalDistance: CLLocationDistance = 0.0
    var maxAcceleration: Double = 0.0
    let regionInMeters: Double = 5000
    
    var locationManager = CLLocationManager ()
    var locations: [CLLocation] = []
    var distanceBeforeExceedingSpeedLimit = 0.0
    var hasCalculatedDistanceBeforeOverspeed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewDidAppear(_ animated: Bool) {
        //Make map visable and set initial location
        setToInitials()
        
        locationManager.delegate = self
        map.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        map.showsUserLocation = true
    }
    
    func setToInitials(){
        currentSpeedLabel.text = "0 km/h"
        maxSpeedLabel.text = "0 km/h"
        averageSpeedLabel.text = "0 km/h"
        distanceLabel.text = "0 km"
        maxAccelerationLabel.text = "0 m/s^2"
        stopTripButton.isEnabled = false
        tripStatus.backgroundColor = UIColor.lightGray
        overSpeedingIndicator.backgroundColor = UIColor.clear
        locations.removeAll()
        isTripInProgress = false
        currentSpeed = 0.0
        maxSpeed = 0.0
        totalDistance = 0.0
        maxAcceleration = 0.0
        distanceBeforeExceedingSpeedLimit = 0.0
        hasCalculatedDistanceBeforeOverspeed = false
        overSpeedingIndicator.text = ""
    }
    
    @IBAction func startTrip(_ sender: Any) {
        tripStartTime = Date()
        setToInitials()
        locationManager.startUpdatingLocation()
        tripStatus.backgroundColor = UIColor.green
        stopTripButton.isEnabled = true
        centerViewOnUserLocation()
        isTripInProgress = true
        // updateUI()
    }
    
    @IBAction func stopTrip(_ sender: Any) {
        isTripInProgress = false
        locationManager.stopUpdatingLocation()
        // updateUI()
        tripStatus.backgroundColor = UIColor.gray
        stopTripButton.isEnabled = false
        currentSpeedLabel.text = "0 km/h"
        overSpeedingIndicator.backgroundColor = UIColor.clear
        print("Max speed == \(maxSpeed)")
        let avg = averageSpeedLabel.text!
        print("Average speed == \(avg)")
        let dist = distanceLabel.text!
        print("Distance Travelled = \(dist)")
        print("Distance Travelled Before Exceeding Speed Limit == \(distanceBeforeExceedingSpeedLimit)")
    }
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            map.setRegion(region, animated: true)
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if(isTripInProgress){
            guard let location = locations.last else { return }
            let centre = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion.init(center: centre, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            map.setRegion(region, animated: true)
            updateTripData(newLocation: location)
            updateUI()
            
        }
    }
    
    func updateUI() {
        
        currentSpeedLabel.text = String(format: "%.2f km/h", currentSpeed)
        maxSpeedLabel.text = String(format: "%.2f km/h", maxSpeed)
        
        if locations.count > 1 {
            let speedsArray = locations.map { $0.speed * 3.6 } // Convert speeds to km/h
            let averageSpeed = speedsArray.reduce(0, +) / Double(speedsArray.count)
            averageSpeedLabel.text = String(format: "%.2f km/h", averageSpeed)
        } else {
            averageSpeedLabel.text = "0 km/h"
        }
        
        distanceLabel.text = String(format: "%.2f km", totalDistance / 1000)
        maxAccelerationLabel.text = String(format: "%.2f m/s^2", maxAcceleration)
        
        if currentSpeed > 115 {
            if !hasCalculatedDistanceBeforeOverspeed{
                distanceBeforeExceedingSpeedLimit = totalDistance/1000
                hasCalculatedDistanceBeforeOverspeed = true
                overSpeedingIndicator.text = String(distanceBeforeExceedingSpeedLimit) + " km"
                
                // print("Distance Travelled Before Exceeding Speed Limit == \(distanceBeforeExceedingSpeedLimit)")
            }
            overSpeedingIndicator.backgroundColor = UIColor.red
        } else {
            overSpeedingIndicator.backgroundColor = UIColor.clear
        }
        print("Current speed == \(currentSpeed)")
    }
    
    func updateTripData(newLocation: CLLocation) {
        if let startTime = tripStartTime {
            let currentTime = Date()
            let timeInterval = currentTime.timeIntervalSince(startTime)
            
            let speed = newLocation.speed * 3.6 // m/s to km/h
            currentSpeed = speed
            
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
    
    
}


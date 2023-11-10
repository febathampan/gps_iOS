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
    let regionInMeters: Double = 10000
    
    var locationManager = CLLocationManager ()
    
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
        
        
    }
    
    @IBAction func startTrip(_ sender: Any) {
        isTripInProgress = true
        tripStartTime = Date()
        locationManager.startUpdatingLocation()
        tripStatus.backgroundColor = UIColor.green
        stopTripButton.isEnabled = true
        centerViewOnUserLocation()
        // updateUI()
    }
    
    @IBAction func stopTrip(_ sender: Any) {
        isTripInProgress = false
        locationManager.stopUpdatingLocation()
        // updateUI()
        tripStatus.backgroundColor = UIColor.gray
        stopTripButton.isEnabled = false
        
    }
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            map.setRegion(region, animated: true)
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let centre = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: centre, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        map.setRegion(region, animated: true)
        updateTripData(newLocation: location)
        updateUI()
        
    }
    
    func updateUI() {
        currentSpeedLabel.text = String(format: "%.2f km/h", currentSpeed)
        maxSpeedLabel.text = String(format: "%.2f km/h", maxSpeed)
        if let startTime = tripStartTime {
            let currentTime = Date()
            let timeInterval = currentTime.timeIntervalSince(startTime)
            let averageSpeed = totalDistance / timeInterval
            averageSpeedLabel.text = String(format: "%.2f km/h", averageSpeed)
        }
        distanceLabel.text = String(format: "%.2f km", totalDistance / 1000)
        maxAccelerationLabel.text = String(format: "%.2f m/s^2", maxAcceleration)
        
        if currentSpeed > 115 {
            overSpeedingIndicator.backgroundColor = UIColor.red
        } else {
            overSpeedingIndicator.backgroundColor = UIColor.clear
        }
    }
    
    
    /*func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
     if let location = locations.last {
     updateTripData(newLocation: location)
     updateUI()
     }
     }*/
    func updateTripData(newLocation: CLLocation) {
        if let startTime = tripStartTime {
            let currentTime = Date()
            let timeInterval = currentTime.timeIntervalSince(startTime)
            
            let speed = newLocation.speed * 3.6 // m/s to km/h
            currentSpeed = speed
            
            if speed > maxSpeed {
                maxSpeed = speed
            }
            
            totalDistance += newLocation.distance(from: newLocation)
            
            // Calculate acceleration (absolute value)
            let acceleration = abs((speed - currentSpeed) / timeInterval)
            if acceleration > maxAcceleration {
                maxAcceleration = acceleration
            }
        }
    }
    
    
}


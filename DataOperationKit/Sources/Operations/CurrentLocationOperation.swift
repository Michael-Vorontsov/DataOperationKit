//
//  CurrentLocationOperation.swift
//  DataOperationKit
//
//  Created by Mykhailo Vorontsov on 08/04/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import Foundation
import CoreLocation

private let timeout =  60.0

/** 
 Operation exctacting current Region with current location
 */
class CurrentLocationOperation: DataRetrievalOperation, CLLocationManagerDelegate {
  
  var objectBuilder: ObjectBuilder!
  
  var locationManager: CLLocationManager!
  
  var geocoder: CLGeocoder!
  
  var location:CLLocation? = nil
  
  var dataReceived = false
  
  var geolocationError:NSError? = nil
  
  override func prepareForRetrieval() throws {
    guard true == CLLocationManager.locationServicesEnabled() else {
      throw DataRetrievalOperationError.InvalidParameter(parameterName: "locationServicesEnabled")
    }
    
    
    locationManager = CLLocationManager()
    locationManager.delegate = self
    
    locationManager.requestWhenInUseAuthorization()

    try super.prepareForRetrieval()
  }
  
  override func retriveData() throws {
    
    // First - find current geo location (coordinates)
    try super.retriveData()
    
    self.locationManager.startUpdatingLocation()
    let syncDate = NSDate()
    
    // Can't use semaphore without blocking delegation thread, so use wait loop.
    while false == cancelled && false == dataReceived && timeout > -syncDate.timeIntervalSinceNow {
      NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.1))
    }
    
    guard false == cancelled else {
      return
    }
    
    guard true == dataReceived, let location = location else {
      throw DataRetrievalOperationError.WrongDataFormat(error: nil)
    }
    
    // Second - revers geocode location to placemark
    geocoder = CLGeocoder()
    let semaphore = dispatch_semaphore_create(0)
    geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
      self.convertedObject = placemarks
      dispatch_semaphore_signal(semaphore)
    }
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * Double(NSEC_PER_SEC))))
    if let geolocationError = geolocationError {
      throw DataRetrievalOperationError.WrappedNSError(error: geolocationError)
    }
    
    
  }
  
  //Third: Extract description from placemark
  override func parseData() throws {
    guard let convertedObject = convertedObject as? [CLPlacemark],
      let placemark = convertedObject.first else {
        throw DataRetrievalOperationError.InternalError(error: nil)
    }
    results = [placemark]
  }

  override func cancel() {
    super.cancel()
    locationManager?.stopUpdatingLocation()
    geocoder?.cancelGeocode()
  }
  
}

// MARK: CLLocationManagerDelegate
extension CurrentLocationOperation {
  
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    locationManager.stopUpdatingLocation()
    location = locations.first
    dataReceived = true
    
  }
  
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    dataReceived = true
    self.geolocationError = error
  }
  
}

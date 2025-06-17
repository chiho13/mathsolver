//
//  LocationManager.swift
//  videoeditor
//
//  Created by Anthony Ho on 17/06/2025.
//


import CoreLocation


class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var placeName: String?
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onPlaceNameUpdate: ((String) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        if let location = locations.last {
            // Stop location updates after getting the location
            locationManager.stopUpdatingLocation()
            
            // Perform reverse geocoding
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    return
                }
                
                if let placemark = placemarks?.first {
                    print("Placemark details:")
                    print("Name: \(placemark.name ?? "nil")")
                    print("Locality: \(placemark.locality ?? "nil")")
                    print("Administrative Area: \(placemark.administrativeArea ?? "nil")")
                    print("Country: \(placemark.country ?? "nil")")
                    print("Postal Code: \(placemark.postalCode ?? "nil")")
                    
                    let placeName = [
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.country
                    ].compactMap { $0 }.joined(separator: ", ")
                    
                    print("Final place name: \(placeName)")
                    
                    DispatchQueue.main.async {
                        self?.placeName = placeName
                        self?.onPlaceNameUpdate?(placeName)
                    }
                } else {
                    print("No placemark found")
                }
            }
            onLocationUpdate?(location)
            onLocationUpdate = nil // Reset the callback after it has been triggered
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
} 

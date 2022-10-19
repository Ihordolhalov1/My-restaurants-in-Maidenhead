//
//  MapViewController.swift
//  Maidenhead restaurants
//
//  Created by Ihor Dolhalov on 16.10.2022.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    var place = Place()
    let annotationIdentifier = "annotationIdentifier"
    let locationManager = CLLocationManager()   // локейшн менеджер отвечает за геолокацию
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupPlacemark()
        checkLocationServices()
    }
    
    @IBAction func centerViewInUserLocation() {
        // отцентрировать карту по расположению пользователя
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: 10000, longitudinalMeters: 10000)
            mapView.setRegion(region, animated: true)
            
        }
        
    }
    
    
    
    private func setupPlacemark() {
        guard let location = place.location else { return }
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            let placemark = placemarks.first
            
            let annotation = MKPointAnnotation()
            annotation.title = self.place.name
            annotation.subtitle = self.place.type
            
            
            guard let placemarkLocation = placemark?.location else { return }
            annotation.coordinate = placemarkLocation.coordinate
            
            self.mapView.showAnnotations([annotation], animated: true)
            self.mapView.selectAnnotation(annotation, animated: true)
            
        }
    }
    
    private func checkLocationServices() { // перевірка чи включена служба локації
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else { //если не разрешен сервис геолокации, то открыть алерт контроллер
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                self.showAlert(title: "Location services are disabled", message: "To enable it go Settings")
            }
        }
    }
    
    private func setupLocationManager() { // настройка точности геолокации
        locationManager.delegate = self // назначаем делегата для CLLocationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func checkLocationAuthorization() { //проверка чи дозволив користувач геолокацію
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            break
        case .denied:
        //showAlertController
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            //showAlertController
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                self.showAlert(title: "Location services are disabled", message: "To enable it go Settings")
            }
                break
        case .authorizedAlways:
            break
        @unknown default:
            break
        }
        
    }
    
    private func showAlert(title: String, message: String) { //створення алерт контроллепа
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}
    extension MapViewController: MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil}
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKPinAnnotationView
            
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
                annotationView?.canShowCallout = true
            }
            
            if let imageData = place.imageData {
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
                imageView.layer.cornerRadius = 10
                imageView.clipsToBounds = true
                imageView.image = UIImage(data: imageData)
                annotationView?.rightCalloutAccessoryView = imageView
            }
            return annotationView
        }
    }

extension MapViewController: CLLocationManagerDelegate { //отслеживаем статус авторизации локации в реальном времени
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}


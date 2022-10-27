//
//  MapViewController.swift
//  Maidenhead restaurants
//
//  Created by Ihor Dolhalov on 16.10.2022.
//

import UIKit
import MapKit
import CoreLocation

protocol MapViewControllerDelegate { //Протоколы используются для передачи данных между классами
    func getAddress(_address: String?)
}

class MapViewController: UIViewController {
    let mapManager = MapManager()
    var mapViewControlerDelegate: MapViewControllerDelegate?
    var place = Place()
    let annotationIdentifier = "annotationIdentifier"
   
    var incomeSegueIdentifier = ""  // ідентифікатор сегвея по якому переход на карту, по першому чи по другому
    var previousLocation: CLLocation? { // координати попереднього місця перебування користувача
        didSet {
            mapManager.startTrackingUserLocation(
                for: mapView,
                and: previousLocation) { (currentLocation) in
                    self.previousLocation = currentLocation
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.mapManager.showUserLocation(mapView: self.mapView)
                    }
                }}}
   
        
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapPinImage: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    
    override func viewDidLoad() {
        addressLabel.text = ""
        super.viewDidLoad()
        mapView.delegate = self
        setupMapView()
    
    }
    
    @IBAction func doneButtonPressed() {
        mapViewControlerDelegate?.getAddress(_address: addressLabel.text) //передаем адрес
        
        dismiss(animated: true) // закрываем вью контроллер
    }
    
    @IBAction func goButtonPressed(_ sender: UIButton) {
        mapManager.getDirections(for: mapView) { (location) in self.previousLocation = location}
    }
    
    @IBAction func centerViewInUserLocation() {
        // отцентрировать карту по расположению пользователя
        mapManager.showUserLocation(mapView: mapView)
        
        
    }
    
    private func setupMapView() {
        goButton.isHidden = true
        
        mapManager.checkLocationServices(mapView: mapView, segueIdentifier: incomeSegueIdentifier) {mapManager.locationManager.delegate = self}
        
        if incomeSegueIdentifier == "showPlace" {
            mapManager.setupPlacemark(place: place, mapView: mapView)
            mapPinImage.isHidden = true
            addressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
        }
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
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated: Bool) {
            let center = mapManager.getCenterLocation(for: mapView) // получаем координати центра
            let geocoder = CLGeocoder() //обьект связки координат и адреса
            
            if incomeSegueIdentifier == "showPlace" && previousLocation != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.mapManager.showUserLocation(mapView: self.mapView)  //при зміні масштаба чи фокуса на карті повертати назад на користувача через 3 секунди
                }
            }
            
            geocoder.cancelGeocode() //очистка памяті при використанні відкладенного завдання
            
            geocoder.reverseGeocodeLocation(center) { (placemarks, error) in
                if let error = error {
                    print(error)
                    return
                }
                
                guard let placemarks = placemarks else { return }
                let placemark = placemarks.first
                let streetName = placemark?.thoroughfare
                let buildNumber = placemark?.subThoroughfare
                
                if streetName != nil && buildNumber != nil {
                    self.addressLabel.text = "\(streetName!), \(buildNumber!)"}
                else if streetName != nil {
                    self.addressLabel.text = "\(streetName!)"}
                else {self.addressLabel.text = ""}
                
            }
        }
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer { //подсветить маршрути різними кольорами
            let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
            renderer.strokeColor = .blue
            
            return renderer
        }
    }

extension MapViewController: CLLocationManagerDelegate { //отслеживаем статус авторизации локации в реальном времени
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        
        mapManager.checkLocationAuthorization(mapView: mapView,
                                              segueIdentifier: incomeSegueIdentifier)

    }
}


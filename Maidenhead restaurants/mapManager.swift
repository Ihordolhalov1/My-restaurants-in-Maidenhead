//
//  mapManager.swift
//  Maidenhead restaurants
//
//  Created by Ihor Dolhalov on 25.10.2022.
//


import UIKit
import MapKit

class MapManager {
    
    let locationManager = CLLocationManager()   // локейшн менеджер отвечает за геолокацию
    private var directionsArray: [MKDirections] = [] //масив маршрутів
    private var placeCoordinate: CLLocationCoordinate2D? //коордитати ресторана

    func setupPlacemark(place: Place, mapView: MKMapView) {
        
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
            annotation.title = place.name
            annotation.subtitle = place.type
            
            
            guard let placemarkLocation = placemark?.location else { return }
            annotation.coordinate = placemarkLocation.coordinate
            self.placeCoordinate = placemarkLocation.coordinate
            
            mapView.showAnnotations([annotation], animated: true)
            mapView.selectAnnotation(annotation, animated: true)
            
        }
    }
    
    
    func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: ()->()) { // перевірка чи включена служба локації
       if CLLocationManager.locationServicesEnabled() {
           locationManager.desiredAccuracy = kCLLocationAccuracyBest
           checkLocationAuthorization(mapView: mapView, segueIdentifier: segueIdentifier)
           closure()
       } else { //если не разрешен сервис геолокации, то открыть алерт контроллер
           DispatchQueue.main.asyncAfter(deadline: .now()+1) {
               self.showAlert(title: "Location services are disabled", message: "To enable it go Settings")
           }
       }
   }
    
    func showUserLocation(mapView: MKMapView) {
        // отцентрировать карту по расположению пользователя
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
            
        }
    }
    
    func getDirections(for mapView: MKMapView, previousLocation: (CLLocation) -> ()) { //функція побудови марщрута
        
        guard let location = locationManager.location?.coordinate else //визначаємо координати користувача
        { showAlert(title: "Error", message: "Current location is not found")
            return }
        locationManager.startUpdatingLocation() //обновляти місцерасположення користувача
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
        
        guard let request = createDirectionsRequest(from: location) else //создаємо запрос на маршрут
        { print("REQUEST CANNOT BE CREATED. DESTINATION NOT FOUND")
            showAlert(title: "Error", message: "Destination is not found")
            return }
        
        
        let directions = MKDirections(request: request) // маршрут
        
        resetMapView(withNew: directions, mapView: mapView) // удаляємо всі старі маршрути
        
        directions.calculate { (response, error) in
            if let error = error {
                print("ERROR WITH DIRECTION CALCULATE")
                print(error)
                DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                    self.showAlert(title: "Location services are disabled", message: "To enable it go to Settings")
                }
                return }
            guard let response = response else
            { self.showAlert(title: "Error", message: "Direction is not found")
                return }
 
            
         
            for route in response.routes {  //response = массив из разных вариантов маршрутов, перебираем их в цикле
                mapView.addOverlay(route.polyline) // показуємо на карті всі маршрути
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true) //маштабуємо карту щоб було видно всі маршрути
                
                let distance = String(format: "%.1f", route.distance / 1000) //округляєм і ділимо на 1000 щоб з метрів перейти в км
                let timeInterval = route.expectedTravelTime
                print ("Відстань до місця: \(distance) км.")
                print ("Час в путі: \(timeInterval) сек.")
            }
        }
    }
    
    
    func createDirectionsRequest (from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? { //функція створення запроса на побудову маршрута
        guard let destinationCoordinate = placeCoordinate else { return nil } //координати цілі куди їдемо
        let startingLocation = MKPlacemark(coordinate: coordinate)    //координати початку маршруту, тобто коордінати користувача
        let destination   = MKPlacemark(coordinate: destinationCoordinate) //ціль, куди ідемо
        
        let request = MKDirections.Request() //запрос на маршрут від однієї точки до іншої
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true  //пропонувати альтернативні варианти
        
        return request
    }
    
    func startTrackingUserLocation(for mapView: MKMapView, and location: CLLocation?, closure: (_ currentLocation: CLLocation) -> ()) {
        guard let location = location else { return }
        let center = getCenterLocation(for: mapView) // визначаємо центр карти що відображається
        guard center.distance(from: location) > 50 else { return } //якщо дистанція від центра карти до точки попереднього расположення користувача більше 50 метрів то виконувати наступний код
        closure(center) //показуємо нову локацію користувача через 2 секунди
        }
    
    func resetMapView(withNew directions: MKDirections, mapView: MKMapView) { // функція для зачистки мапи від старих маршрутів
        mapView.removeOverlays(mapView.overlays) // видалення всіх попередніх маршрутів з мапи
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel() } //видаляємо всі маршрути
        directionsArray.removeAll()
    }
    
     func getCenterLocation(for MapView: MKMapView) -> CLLocation { //визначення коордінат центра карти
        let latitude = MapView.centerCoordinate.latitude // широта
        let longitude = MapView.centerCoordinate.longitude //долгота
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    
    func checkLocationAuthorization(mapView: MKMapView, segueIdentifier: String) { //проверка чи дозволив користувач геолокацію
        let manager = CLLocationManager()
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if segueIdentifier == "getAddress" {
                showUserLocation(mapView: mapView)
            }
            break
        case .denied:
        //showAlertController
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                self.showAlert(title: "Location services are disabled", message: "To enable it go to Settings")
            }
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            //showAlertController
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                self.showAlert(title: "Location services are disabled", message: "To enable it go to Settings")
            }
                break
        case .authorizedAlways:
            break
        @unknown default:
            break
        }
        
    }
    
     
    
   
    
    
    private func showAlert(title: String, message: String) { //створення алерт контроллера
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        let alertWindow  = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert+1 //вище всіх вікон
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alert, animated: true)
    }
    
  
    
    
    
    
    
    
}

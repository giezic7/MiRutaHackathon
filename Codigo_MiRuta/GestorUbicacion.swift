import Foundation
import CoreLocation
import Combine

class GestorUbicacion: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var ubicacionUsuario: CLLocationCoordinate2D?
    @Published var permisoConcedido: Bool = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func solicitarPermiso() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let nuevaUbicacion = locations.last else { return }
        DispatchQueue.main.async {
            self.ubicacionUsuario = nuevaUbicacion.coordinate
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            permisoConcedido = true
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            permisoConcedido = false
        default:
            break
        }
    }
}
import Foundation
import MapKit
import Combine

class GestorBusqueda: ObservableObject {
    static func buscarCoordenada(para texto: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        guard !texto.trimmingCharacters(in: .whitespaces).isEmpty else {
            completion(nil)
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = texto
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let item = response?.mapItems.first else {
                completion(nil)
                return
            }
            completion(item.placemark.coordinate)
        }
    }
}
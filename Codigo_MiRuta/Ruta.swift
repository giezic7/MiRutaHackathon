import Foundation
import CoreLocation
import SwiftData

enum TipoTransporte: String, Codable, CaseIterable, Identifiable {
    case autobus = "Autobús"
    case combi = "Combi"
    case mototaxi = "Mototaxi"
    var id: String { self.rawValue }
}

@Model
final class PuntoCoordenada {
    var id: UUID
    var nombre: String
    var latitud: Double
    var longitud: Double
    var orden: Int 
    
    init(id: UUID = UUID(), nombre: String, latitud: Double, longitud: Double, orden: Int) {
        self.id = id
        self.nombre = nombre
        self.latitud = latitud
        self.longitud = longitud
        self.orden = orden
    }
}

@Model
final class Ruta {
    var id: UUID
    var nombre: String
    var tipoRaw: String
    
    @Relationship(deleteRule: .cascade) 
    var paradas: [PuntoCoordenada]
    
    var tipo: TipoTransporte {
        get { TipoTransporte(rawValue: tipoRaw) ?? .combi }
        set { tipoRaw = newValue.rawValue }
    }
    
    init(id: UUID = UUID(), nombre: String, tipo: TipoTransporte, paradas: [PuntoCoordenada]) {
        self.id = id
        self.nombre = nombre
        self.tipoRaw = tipo.rawValue
        self.paradas = paradas
    }
}
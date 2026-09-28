import SwiftUI
import MapKit
import SwiftData

struct PantallaRegistrarRuta: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var nombreRuta: String = ""
    @State private var tipoSeleccionado: TipoTransporte = .combi
    
    @State private var paradasRegistradas: [PuntoCoordenada] = []
    @State private var nombreParadaActual: String = ""
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 14.9041, longitude: -92.2611),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información del Transporte")) {
                    TextField("Nombre o número (ej. Ruta 5)", text: $nombreRuta)
                    Picker("Tipo de Transporte", selection: $tipoSeleccionado) {
                        ForEach(TipoTransporte.allCases) { tipo in
                            Text(tipo.rawValue).tag(tipo)
                        }
                    }
                }
                
                Section(header: Text("Agregar Parada o Punto del Trayecto")) {
                    Text("Mueve el mapa y presiona 'Marcar Punto' en el centro:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    ZStack {
                        Map(coordinateRegion: $region)
                            .frame(height: 200)
                            .cornerRadius(10)
                        
                        Image(systemName: "mappin")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                    
                    TextField("Nombre del punto (ej. Frente al Mercado)", text: $nombreParadaActual)
                    
                    Button(action: agregarPuntoActual) {
                        HStack {
                            Image(systemName: "plus.location")
                            Text("Marcar este punto")
                        }
                    }
                    .disabled(nombreParadaActual.isEmpty)
                }
                
                if !paradasRegistradas.isEmpty {
                    Section(header: Text("Puntos Registrados (\(paradasRegistradas.count))")) {
                        ForEach(paradasRegistradas) { punto in
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                Text(punto.nombre)
                                    .font(.subheadline)
                            }
                        }
                        .onDelete(perform: eliminarPunto)
                    }
                }
                
                Button("Guardar y Compartir Ruta") {
                    if !nombreRuta.isEmpty {
                        let nuevaRuta = Ruta(
                            nombre: nombreRuta,
                            tipo: tipoSeleccionado,
                            paradas: paradasRegistradas
                        )
                        modelContext.insert(nuevaRuta)
                        dismiss()
                    }
                }
                .disabled(nombreRuta.isEmpty || paradasRegistradas.isEmpty)
            }
            .navigationTitle("Registrar Ruta")
            .toolbar {
                Button("Cancelar") { dismiss() }
            }
        }
    }
    
    private func agregarPuntoActual() {
        let nuevoPunto = PuntoCoordenada(
            nombre: nombreParadaActual,
            latitud: region.center.latitude,
            longitud: region.center.longitude,
            orden: paradasRegistradas.count
        )
        paradasRegistradas.append(nuevoPunto)
        nombreParadaActual = ""
    }
    
    private func eliminarPunto(at offsets: IndexSet) {
        paradasRegistradas.remove(atOffsets: offsets)
    }
}
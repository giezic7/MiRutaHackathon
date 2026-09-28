import SwiftUI
import MapKit
import SwiftData

struct MapaConLineas: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var paradas: [PuntoCoordenada]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true // Punto azul del usuario
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        for parada in paradas {
            let annotation = MKPointAnnotation()
            annotation.title = parada.nombre
            annotation.coordinate = CLLocationCoordinate2D(latitude: parada.latitud, longitude: parada.longitud)
            mapView.addAnnotation(annotation)
        }
        
        if paradas.count >= 2 {
            let coordenadas = paradas.map { CLLocationCoordinate2D(latitude: $0.latitud, longitude: $0.longitud) }
            let polyline = MKPolyline(coordinates: coordenadas, count: coordenadas.count)
            mapView.addOverlay(polyline)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 5.0
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var rutasGuardadas: [Ruta]
    @StateObject private var gestorUbicacion = GestorUbicacion()
    
    @State private var textoOrigen: String = ""
    @State private var textoDestino: String = ""
    @State private var estaBuscando = false
    @State private var mostrarModalRegistro = false
    @State private var rutaSeleccionada: Ruta? = nil
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 14.9041, longitude: -92.2611),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    HStack {
                        TextField("Ubicación de origen (o deja vacío para usar GPS)", text: $textoOrigen)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        if !textoOrigen.isEmpty {
                            Button(action: { textoOrigen = "" }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("¿A dónde quieres ir? (ej. Mercado, Centro)", text: $textoDestino)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        if !textoDestino.isEmpty {
                            Button(action: { textoDestino = "" }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Button(action: {
                        filtrarRutaMasViable()
                    }) {
                        HStack {
                            if estaBuscando {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).padding(.trailing, 5)
                            }
                            Text(estaBuscando ? "Buscando..." : "Buscar Transporte Más Viable")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(estaBuscando)
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                ZStack(alignment: .bottomTrailing) {
                    MapaConLineas(region: $region, paradas: paradasAMostrar)
                        .frame(maxHeight: .infinity)
                    
                    Button(action: {
                        gestorUbicacion.solicitarPermiso()
                        if let miUbicacion = gestorUbicacion.ubicacionUsuario {
                            withAnimation {
                                region = MKCoordinateRegion(
                                    center: miUbicacion,
                                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                )
                            }
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .padding(12)
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
                
                List(rutasGuardadas) { ruta in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ruta.nombre)
                                .font(.headline)
                                .foregroundColor(rutaSeleccionada?.id == ruta.id ? .blue : .primary)
                            
                            Text("Tipo: \(ruta.tipo.rawValue) • \(ruta.paradas.count) paradas")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if rutaSeleccionada?.id == ruta.id {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                        } else {
                            Image(systemName: "chevron.right").foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { seleccionarRuta(ruta) }
                }
                .frame(height: 220)
            }
            .navigationTitle("Rutas Locales")
            .toolbar {
                Button(action: { mostrarModalRegistro = true }) {
                    Image(systemName: "plus.circle.fill").font(.title2)
                }
            }
            .sheet(isPresented: $mostrarModalRegistro) {
                PantallaRegistrarRuta()
            }
        }
    }
    
    private var paradasAMostrar: [PuntoCoordenada] {
        if let ruta = rutaSeleccionada {
            return ruta.paradas.sorted { $0.orden < $1.orden }
        } else {
            return [] // Mapa limpio si no hay selección
        }
    }
    
    private func seleccionarRuta(_ ruta: Ruta) {
        rutaSeleccionada = ruta
        if let primeraParada = ruta.paradas.sorted(by: { $0.orden < $1.orden }).first {
            withAnimation {
                region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: primeraParada.latitud, longitude: primeraParada.longitud),
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            }
        }
    }
    
    private func filtrarRutaMasViable() {
        guard !rutasGuardadas.isEmpty else { return }
        estaBuscando = true
        
        if !textoOrigen.isEmpty {
            GestorBusqueda.buscarCoordenada(para: textoOrigen) { coordOrigen in
                if let origen = coordOrigen {
                    evaluarRutas(origen: origen)
                } else if let miUbicacion = gestorUbicacion.ubicacionUsuario {
                    evaluarRutas(origen: miUbicacion)
                } else {
                    estaBuscando = false
                }
            }
        } else if let miUbicacion = gestorUbicacion.ubicacionUsuario {
            evaluarRutas(origen: miUbicacion)
        } else {
            gestorUbicacion.solicitarPermiso()
            estaBuscando = false
        }
    }
    
    private func evaluarRutas(origen: CLLocationCoordinate2D) {
        let puntoOrigen = CLLocation(latitude: origen.latitude, longitude: origen.longitude)
        
        if !textoDestino.isEmpty {
            GestorBusqueda.buscarCoordenada(para: textoDestino) { coordDestino in
                DispatchQueue.main.async {
                    self.estaBuscando = false
                    if let destino = coordDestino {
                        let puntoDestino = CLLocation(latitude: destino.latitude, longitude: destino.longitude)
                        let mejorRuta = self.rutasGuardadas.min { rutaA, rutaB in
                            let distA = self.calcularDistanciaTotal(ruta: rutaA, origen: puntoOrigen, destino: puntoDestino)
                            let distB = self.calcularDistanciaTotal(ruta: rutaB, origen: puntoOrigen, destino: puntoDestino)
                            return distA < distB
                        }
                        if let seleccionada = mejorRuta { self.seleccionarRuta(seleccionada) }
                    } else {
                        self.seleccionarRutaMasCercanaSoloOrigen(origen: puntoOrigen)
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.estaBuscando = false
                self.seleccionarRutaMasCercanaSoloOrigen(origen: puntoOrigen)
            }
        }
    }
    
    private func calcularDistanciaTotal(ruta: Ruta, origen: CLLocation, destino: CLLocation) -> Double {
        let distOrigen = ruta.paradas.map { CLLocation(latitude: $0.latitud, longitude: $0.longitud).distance(from: origen) }.min() ?? Double.greatestFiniteMagnitude
        let distDestino = ruta.paradas.map { CLLocation(latitude: $0.latitud, longitude: $0.longitud).distance(from: destino) }.min() ?? Double.greatestFiniteMagnitude
        return distOrigen + distDestino
    }
    
    private func seleccionarRutaMasCercanaSoloOrigen(origen: CLLocation) {
        let mejorRuta = rutasGuardadas.min { rutaA, rutaB in
            let distA = rutaA.paradas.map { CLLocation(latitude: $0.latitud, longitude: $0.longitud).distance(from: origen) }.min() ?? Double.greatestFiniteMagnitude
            let distB = rutaB.paradas.map { CLLocation(latitude: $0.latitud, longitude: $0.longitud).distance(from: origen) }.min() ?? Double.greatestFiniteMagnitude
            return distA < distB
        }
        if let seleccionada = mejorRuta { seleccionarRuta(seleccionada) }
    }
}
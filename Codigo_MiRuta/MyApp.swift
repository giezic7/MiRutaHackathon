import SwiftUI
import SwiftData

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Registra los modelos en la base de datos local
        .modelContainer(for: [Ruta.self, PuntoCoordenada.self])
    }
}
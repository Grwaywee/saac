import SwiftUI
import SwiftData

@main
struct saacApp: App {
    @StateObject private var viewModel = AttendanceViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .modelContainer(for: WorkSession.self) // ✅ configurations 제거
        }
    }
}

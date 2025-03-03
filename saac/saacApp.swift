import SwiftUI
import SwiftData

@main
struct saacApp: App {
    @StateObject private var viewModel = AttendanceViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .modelContainer(for: AttendanceRecord.self) // ✅ CloudKit 자동 설정
        }
    }
}

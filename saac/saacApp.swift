import SwiftUI
import CloudKit

@main
struct saacApp: App {
    @StateObject private var viewModel = AttendanceViewModel()

    init() {
        setupCloudKit()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .onAppear {
                    viewModel.fetchRecords()
                }
        }
    }

    /// ✅ CloudKit 초기 설정 함수
    private func setupCloudKit() {
        let container = CKContainer.default()
        let database = container.publicCloudDatabase

        // ✅ 데이터베이스 연결 확인 (디버깅용)
        database.fetchAllRecordZones { zones, error in
            if let error = error {
                print("❌ CloudKit 연결 실패: \(error.localizedDescription)")
            } else {
                print("✅ CloudKit 연결 성공: \(zones?.count ?? 0) 개의 레코드 존 발견")
            }
        }
    }
}

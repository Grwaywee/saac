import SwiftUI
import CloudKit

@main
struct saacApp: App {
    init() {
        setupCloudKit()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // viewModel.fetchRecords() // This line is removed as viewModel is no longer used here
                }
        }
    }

    /// ✅ CloudKit 초기 설정 함수
    private func setupCloudKit() {
        let container = CKContainer.default()
        let database = container.publicCloudDatabase

        // ✅ CloudKit 계정 상태 확인
        container.accountStatus { status, error in
            if let error = error {
                print("❌ CloudKit 연결 실패: \(error.localizedDescription)")
            } else {
                switch status {
                case .available:
                    print("✅ CloudKit 사용 가능")
                case .noAccount:
                    print("⚠️ CloudKit 계정이 없음")
                case .restricted:
                    print("⚠️ CloudKit 사용 제한됨")
                case .couldNotDetermine:
                    print("❓ CloudKit 상태 확인 불가")
                @unknown default:
                    print("⚠️ CloudKit의 새로운 상태 감지")
                }
            }
        }
    }
}

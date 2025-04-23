import SwiftUI
import CloudKit

@main
struct saacApp: App {
    @StateObject private var viewModel = AttendanceViewModel()
    @StateObject private var appState = AppStateViewModel()
    
    init() {
        setupCloudKit()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isSignedIn {
                    MainUIView(viewModel: viewModel, currentUserRecord: appState.currentUserRecord!, selectedWorkOption: .constant("기본"))
                } else {
                    ContentView(viewModel: viewModel)
                }
            }
            .environmentObject(appState)
            .task {
                appState.tryAutoSignIn()
//                deleteTestUserRecord() //TODO: 🔥 항상 확인하고 다시 꺼야함.
//                logAllCloudKitUsers() //TODO: 🔥 항상 확인하고 다시 꺼야함.
//                deleteAllWorkSessions() //TODO: 🔥 항상 확인하고 다시 꺼야함.
            }
        }
    }
    
    //MARK: - ✅ CloudKit 초기 설정 함수
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
                    print("✅ CloudKit 연결완료")
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
    
    //MARK: - 🧪 CloudKit 디버깅용: 단일 사용자 레코드 로깅 (직접 fetch)
    private func logAllCloudKitUsers() {
        print("\n----------클라우드킷 디버깅 코드 주석처리 필요----------SaacApp----------\n")
        let testRecordID = CKRecord.ID(recordName: "001496.b3b450c4ac7d417ba2c5b86918b40d62.0454") // ✅ 테스트할 사용자 ID 입력
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: testRecordID) { record, error in
            if let record = record {
                let id = record["id"] as? String ?? "(없음)"
                let name = record["userName"] as? String ?? "(없음)"
                let email = record["email"] as? String ?? "(없음)"
                print("✅ 사용자 레코드 확인됨:")
                print("- 👤 ID: \(id), 이름: \(name), 이메일: \(email)")
                print("----------이상 끝----------SaacApp----------")
            } else {
                print("❌ 사용자 레코드 없음 또는 오류: \(error?.localizedDescription ?? "알 수 없음")")
                print("----------이상 끝----------SaacApp----------")
            }
        }
    }
    
    //MARK: - 🧪 CloudKit 디버깅용: 유저 아이디 기반 레코드 삭제
    private func deleteTestUserRecord() {
        print("\n----------클라우드킷 디버깅 코드 주석처리 필요----------SaacApp----------\n")
        let recordID = CKRecord.ID(recordName: "001496.b3b450c4ac7d417ba2c5b86918b40d62.0454") // 삭제할 userID
        let db = CKContainer.default().publicCloudDatabase

        db.delete(withRecordID: recordID) { deletedRecordID, error in
            if let error = error {
                print("❌ 사용자 레코드 삭제 실패: \(error.localizedDescription)")
                print("----------이상 끝----------SaacApp----------")
            } else {
                print("🗑 사용자 레코드 삭제 완료: \(deletedRecordID?.recordName ?? "알 수 없음")")
                print("----------이상 끝----------SaacApp----------")
            }
        }
    }
    
    //MARK: - 🧪 CloudKit 디버깅용: 전체 WorkSession 레코드 삭제
    private func deleteAllWorkSessions() {
        print("\n----------전체 WorkSession 삭제 시작----------\n")
        let db = CKContainer.default().publicCloudDatabase
        let query = CKQuery(recordType: "WorkSession", predicate: NSPredicate(value: true))

        db.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("❌ WorkSession 조회 실패: \(error.localizedDescription)")
                return
            }

            guard let records = records, !records.isEmpty else {
                print("ℹ️ 삭제할 WorkSession 레코드 없음")
                return
            }

            let recordIDs = records.map { $0.recordID }
            let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
            operation.modifyRecordsCompletionBlock = { _, deletedIDs, error in
                if let error = error {
                    print("❌ WorkSession 레코드 삭제 실패: \(error.localizedDescription)")
                } else {
                    print("🗑 WorkSession \(deletedIDs?.count ?? 0)개 삭제 완료")
                }
                print("----------전체 WorkSession 삭제 종료----------")
            }
            db.add(operation)
        }
    }
}

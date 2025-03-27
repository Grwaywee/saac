import Foundation
import CloudKit

class AttendanceViewModel: ObservableObject {
    @Published var sessions: [WorkSession] = []
    private let database = CKContainer.default().publicCloudDatabase

    //MARK: - 🔹 모든 출퇴근 기록 조회
    func fetchRecords() {
        let query = CKQuery(recordType: "worksession", predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = CKQueryOperation.maximumResults

        operation.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                if let session = WorkSession(from: record) {
                    DispatchQueue.main.async {
                        if !self.sessions.contains(where: { $0.id == session.id }) {
                            self.sessions.append(session)
                        }
                    }
                } else {
                    print("❌ WorkSession 변환 실패: 필드 불일치 가능성")
                }
            case .failure(let error):
                print("❌ [fetchRecords] CloudKit 데이터 불러오기 오류: \(error.localizedDescription)")
            }
        }

        database.add(operation)
    }

    //MARK: - 🔹 특정 사용자의 WorkSession 기록을 가져오는 함수
    func fetchUserSessions(userRecord: CKRecord) {
        let userReference = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        let predicate = NSPredicate(format: "userReference == %@", userReference)
        let query = CKQuery(recordType: "worksession", predicate: predicate)

        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = CKQueryOperation.maximumResults

        operation.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                if let session = WorkSession(from: record) {
                    DispatchQueue.main.async {
                        if !self.sessions.contains(where: { $0.id == session.id }) {
                            self.sessions.append(session)
                        }
                    }
                }
            case .failure(let error):
                print("❌ [fetchUserSessions] 사용자 세션 불러오기 오류: \(error.localizedDescription)")
            }
        }

        database.add(operation)
    }

    //MARK: - 🔹 출근 기록 (Users 레코드 참조 추가)
    func checkIn(userRecord: CKRecord, workOption: String) {
        let userReference = CKRecord.Reference(recordID: userRecord.recordID, action: .none)

        let newSession = WorkSession(
            id: UUID().uuidString,
            date: Date(),
            userReference: userReference,
            userName: userRecord["userName"] as? String ?? "이름없음",
            workOption: workOption,
            checkInTime: Date(),
            checkOutTime: nil,
            breaks: [],
            lastUpdated: Date()
        )

        let record = newSession.toRecord()
        database.save(record) { savedRecord, error in
            if let error = error {
                print("❌ [checkIn] 출근 기록 저장 실패: \(error.localizedDescription)")
                return
            }
            if let savedRecord = savedRecord, let savedSession = WorkSession(from: savedRecord) {
                DispatchQueue.main.async {
                    self.sessions.append(savedSession)
                    print("✅ [checkIn] 출근 기록 성공적으로 저장됨")
                }
            }
        }
    }

    //MARK: - 🔹 퇴근 기록
    func checkOut(session: WorkSession) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index].checkOutTime = Date()
        sessions[index].lastUpdated = Date()

        let record = sessions[index].toRecord()
        database.save(record) { savedRecord, error in
            if let error = error {
                print("❌ [checkOut] 퇴근 기록 저장 실패: \(error.localizedDescription)")
                return
            }
            print("✅ [checkOut] 퇴근 기록 성공적으로 저장됨")
        }
    }
}

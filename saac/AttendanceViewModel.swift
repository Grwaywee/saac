import Foundation
import CloudKit

class AttendanceViewModel: ObservableObject {
    @Published var sessions: [WorkSession] = []
    private let database = CKContainer.default().publicCloudDatabase

    // 🔹 모든 출퇴근 기록 조회
    func fetchRecords() {
        let query = CKQuery(recordType: "worksession", predicate: NSPredicate(value: true))
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = CKQueryOperation.maximumResults

        operation.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                if let session = WorkSession(from: record),
                   !self.sessions.contains(where: { $0.id == session.id }) {  // 🔹 중복 방지
                    DispatchQueue.main.async {
                        self.sessions.append(session)
                    }
                }
            case .failure(let error):
                print("❌ Error fetching records: \(error.localizedDescription)")
            }
        }

        database.add(operation)
    }

    // 🔹 특정 사용자의 WorkSession 기록을 가져오는 함수
    func fetchUserSessions(userRecord: CKRecord) {
        let userReference = CKRecord.Reference(recordID: userRecord.recordID, action: .none)  // ✅ Users 레코드 참조
        let predicate = NSPredicate(format: "userReference == %@", userReference)  // ✅ 특정 사용자만 필터링
        let query = CKQuery(recordType: "worksession", predicate: predicate)

        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = CKQueryOperation.maximumResults

        operation.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                if let session = WorkSession(from: record),
                   !self.sessions.contains(where: { $0.id == session.id }) {  // 🔹 중복 방지
                    DispatchQueue.main.async {
                        self.sessions.append(session)
                    }
                }
            case .failure(let error):
                print("❌ Error fetching user records: \(error.localizedDescription)")
            }
        }

        database.add(operation)
    }

    // 🔹 출근 기록 (Users 레코드 참조 추가)
    func checkIn(userRecord: CKRecord, workOption: String) { // ✅ workOption을 추가하여 오류 해결
        let userReference = CKRecord.Reference(recordID: userRecord.recordID, action: .none)  // ✅ Users 레코드 참조 생성

        let newSession = WorkSession(
            id: UUID().uuidString,
            date: Date(),
            userReference: userReference,
            workOption: workOption,  // ✅ workOption 동적 반영
            checkInTime: Date(),
            checkOutTime: nil as Date?, // ✅ nil의 타입 명시
            breaks: [],
            lastUpdated: Date()
        )

        let record = newSession.toRecord()
        database.save(record) { savedRecord, error in
            if let error = error {
                print("❌ Error saving check-in: \(error.localizedDescription)")
                return
            }
            if let savedRecord = savedRecord, let savedSession = WorkSession(from: savedRecord) {
                DispatchQueue.main.async {
                    self.sessions.append(savedSession)
                }
            }
        }
    }

    // 🔹 퇴근 기록
    func checkOut(session: WorkSession) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[index].checkOutTime = Date()
        sessions[index].lastUpdated = Date()

        let record = sessions[index].toRecord()
        database.save(record) { savedRecord, error in
            if let error = error {
                print("❌ Error saving check-out: \(error.localizedDescription)")
            }
        }
    }
}

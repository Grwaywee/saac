import Foundation
import SwiftData
import Combine

class AttendanceViewModel: ObservableObject {  // ✅ ObservableObject 추가
    @Published var records: [WorkSession] = []

    func checkIn(userName: String) {
        let newRecord = WorkSession(userName: userName, checkInTime: Date())
        records.append(newRecord)
    }

    func checkOut(record: WorkSession) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index].checkOut(time: Date())
        }
    }

    func fetchRecords() {
        // 여기에 CloudKit 또는 SwiftData에서 데이터를 불러오는 코드 추가 가능
    }
}

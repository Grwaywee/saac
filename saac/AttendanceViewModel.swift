import SwiftData
import SwiftUI

class AttendanceViewModel: ObservableObject {
    @Published var records: [AttendanceRecord] = []
    private var modelContext: ModelContext? // ✅ 옵셔널로 변경

    func setContext(_ context: ModelContext) {
        self.modelContext = context
        fetchRecords()
    }

    // 출근 기록 추가
    func checkIn(userName: String) {
        guard let context = modelContext else { return }
        let newRecord = AttendanceRecord(userName: userName, checkInTime: Date())
        context.insert(newRecord)
        fetchRecords()
    }

    // 퇴근 기록 업데이트
    func checkOut(record: AttendanceRecord) {
        guard let context = modelContext else { return }
        do {
            record.checkOutTime = Date()
            try context.save() // ✅ SwiftData를 사용한 저장 방식
            fetchRecords()
        } catch {
            print("❌ 데이터 저장 실패: \(error.localizedDescription)")
        }
    }

    // 근태 데이터 불러오기
    func fetchRecords() {
        guard let context = modelContext else { return }
        let fetchDescriptor = FetchDescriptor<AttendanceRecord>()
        do {
            self.records = try context.fetch(fetchDescriptor)
        } catch {
            print("❌ 데이터 불러오기 실패: \(error.localizedDescription)")
        }
    }
}

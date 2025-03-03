import SwiftData
import Foundation

@Model
class WorkSession: Identifiable {  // ✅ Identifiable 추가하여 List에서 id 사용 가능
    var id = UUID()
    var userName: String
    var checkInTime: Date
    var checkOutTime: Date?

    init(userName: String, checkInTime: Date) {
        self.userName = userName
        self.checkInTime = checkInTime
    }

    func checkOut(time: Date) {
        self.checkOutTime = time
    }
}

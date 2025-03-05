//import Foundation
//import SwiftData
//
//@Model
//class AttendanceRecord {
//    @Attribute(.unique) var id: UUID  // ✅ 고유 ID 추가
//    var userName: String
//    var checkInTime: Date
//    var checkOutTime: Date?
//
//    init(userName: String, checkInTime: Date) {
//        self.id = UUID()  // ✅ ID 자동 생성
//        self.userName = userName
//        self.checkInTime = checkInTime
//        self.checkOutTime = nil
//    }
//}

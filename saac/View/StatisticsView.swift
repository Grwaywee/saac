//import SwiftUI
//
//struct StatisticsView: View {
//    @ObservedObject var viewModel: AttendanceViewModel
//
//    var body: some View {
//        VStack {
//            Text("출퇴근 통계")
//                .font(.largeTitle)
//                .padding()
//
//            List(viewModel.sessions, id: \.id) { record in
//                VStack(alignment: .leading) {
//                    Text("이름: \(record.userName)")
//                    Text("출근: \(record.checkInTime ?? Date(), formatter: DateFormatter.shortTime)")
//                    if let checkOut = record.checkOutTime {
//                        Text("퇴근: \(checkOut, formatter: DateFormatter.shortTime)")
//                    } else {
//                        Text("퇴근 기록 없음").foregroundColor(.red)
//                    }
//                }
//            }
//        }
//    }
//}
//
//// ✅ shortTime이 한 번만 선언되도록 유지
//extension DateFormatter {
//    static let shortTime: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.timeStyle = .short
//        return formatter
//    }()
//}

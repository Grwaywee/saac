import SwiftUI

struct StatisticsView: View {
    @ObservedObject var viewModel: AttendanceViewModel  // ✅ ObservableObject 적용

    var body: some View {
        VStack {
            Text("출퇴근 통계")
                .font(.largeTitle)
                .padding()

            List(viewModel.records, id: \.self) { record in
                VStack(alignment: .leading) {
                    Text("이름: \(record.userName)")
                    Text("출근: \(record.checkInTime, formatter: DateFormatter.shortTime)")
                    if let checkOut = record.checkOutTime {
                        Text("퇴근: \(checkOut, formatter: DateFormatter.shortTime)")
                    } else {
                        Text("퇴근 기록 없음").foregroundColor(.red)
                    }
                }
            }
        }
    }
}

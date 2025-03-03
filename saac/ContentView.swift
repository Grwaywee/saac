import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: AttendanceViewModel

    @State private var userName = ""

    // ✅ 커스텀 이니셜라이저 추가 (외부에서 `viewModel`을 설정 가능하도록 변경)
    init(viewModel: AttendanceViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack {
                TextField("사악한 당신의 이름은?", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                HStack {
                    Button("출근") {
                        viewModel.checkIn(userName: userName)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("퇴근") {
                        if let lastRecord = viewModel.records.last, lastRecord.checkOutTime == nil {
                            viewModel.checkOut(record: lastRecord)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()

                List(viewModel.records) { record in
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
            .navigationTitle("사악한 근태관리")
        }
        .onAppear {
            viewModel.setContext(modelContext) // ✅ 뷰가 나타날 때 `modelContext`를 설정하도록 변경
        }
    }
}

extension DateFormatter {
    static var shortTime: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    let previewModel = AttendanceViewModel()
    return ContentView(viewModel: previewModel) // ✅ 오류 해결: Preview에서 `viewModel`을 명확하게 전달
}

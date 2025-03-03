import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: AttendanceViewModel

    @State private var userName = ""

    init(viewModel: AttendanceViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack {
                TextField("이름을 입력하세요", text: $userName)
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

                List(viewModel.records, id: \.self) { record in  // ✅ id 추가하여 오류 해결
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
            .navigationTitle("근태 관리")
        }
        .onAppear {
            viewModel.fetchRecords()
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
    return ContentView(viewModel: previewModel)
}

import SwiftUI
import CloudKit

struct ContentView: View {
    @StateObject private var viewModel = AttendanceViewModel()
    @State private var currentUser: User?
    @State private var userName = ""
    @State private var selectedWorkOption: String = "에자일 근무"

    let workOptions = ["에자일 근무", "린 근무", "헝그리 근무"]  // ✅ 동적 선택 가능

    var body: some View {
        NavigationView {
            VStack {
                if let user = currentUser {
                    Text("사용자: \(user.userName)")
                        .font(.headline)

                    TextField("이름을 입력하세요", text: $userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Picker("근무 옵션", selection: $selectedWorkOption) {
                        ForEach(workOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    HStack {
                        Button("출근") {
                            if let userRecord = user.toRecord() {
                                viewModel.checkIn(userRecord: userRecord, workOption: selectedWorkOption)
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("퇴근") {
                            if let lastRecord = viewModel.sessions.last, lastRecord.checkOutTime == nil {
                                viewModel.checkOut(session: lastRecord)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()

                    List(viewModel.sessions) { record in
                        VStack(alignment: .leading) {
                            Text("이름: \(record.userName)")
                            Text("출근: \(record.checkInTime ?? Date(), formatter: DateFormatter.shortTime)")
                            if let checkOut = record.checkOutTime {
                                Text("퇴근: \(checkOut, formatter: DateFormatter.shortTime)")
                            } else {
                                Text("퇴근 기록 없음").foregroundColor(.red)
                            }
                        }
                    }
                } else {
                    ProgressView("사용자 정보를 불러오는 중...")
                }
            }
            .navigationTitle("출퇴근 관리")
            .onAppear {
                fetchCurrentUser()
            }
        }
    }

    /// ✅ CloudKit에서 현재 사용자 정보를 불러오는 함수
    func fetchCurrentUser() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Users", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1

        operation.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                if let user = User(from: record) {
                    DispatchQueue.main.async {
                        self.currentUser = user
                        viewModel.fetchUserSessions(userRecord: record)
                    }
                }
            case .failure(let error):
                print("❌ 사용자 로드 실패: \(error.localizedDescription)")
            }
        }

        CKContainer.default().publicCloudDatabase.add(operation)
    }
}

/// ✅ 날짜 포맷 설정 (중복 선언 방지)
extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

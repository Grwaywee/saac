import SwiftUI
import CloudKit

struct MainUIView: View {
    @ObservedObject var viewModel: AttendanceViewModel
    @EnvironmentObject var appState: AppStateViewModel
    var currentUserRecord: CKRecord
    @Binding var selectedWorkOption: String
    @State private var checkInTime: Date? = nil
    @State private var checkOutTime: Date? = nil
    @State private var coreStartTime: Date? = nil
    @State private var coreEndTime: Date? = nil
    @State private var isCheckedIn: Bool = false
    @State private var showAdditionPopup = false
    
    @State private var workedTimeText: String = "0h 0m"
    @State private var timer: Timer? = nil
    
    func xOffset(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        let hour = CGFloat(components.hour ?? 0)
        let minute = CGFloat(components.minute ?? 0)
        let second = CGFloat(components.second ?? 0)
        let seconds = (hour * 3600) + (minute * 60) + second
        return (seconds / totalSeconds) * fullWidth
    }
    
    func widthBetween(_ start: Date, _ end: Date) -> CGFloat {
        max(xOffset(for: end) - xOffset(for: start), 0)
    }
    
    func startWorkTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            updateWorkedTime()
        }
        updateWorkedTime()
    }

    func updateWorkedTime() {
        guard let start = checkInTime else {
            workedTimeText = "0h 0m"
            return
        }
        let interval = Int(Date().timeIntervalSince(start))
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        workedTimeText = "\(hours)h \(minutes)m"
    }
    
    let fullWidth = UIScreen.main.bounds.width - 32
    let totalSeconds: CGFloat = 24 * 60 * 60
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                //MARK: - ✅ "이름" 님의 사악한 업무 + 설정 버튼
                HStack {
                    Text("\(currentUserRecord["userName"] as? String ?? "사용자") 님의 사악한 업무 😈")
                        .font(.title3)
                        .bold()
                    Spacer()
                    
                    NavigationLink(
                        destination: SettingsView()
                            .environmentObject(viewModel)
                            .environmentObject(appState)
                    ) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                
                Spacer().frame(height: 16)
                
                Divider()
                
                Spacer().frame(height: 16)
                
                ScrollView {
                    VStack(spacing: 16) {
                        //MARK: - ✅ 개인 업무 인사이트 섹션
                        NavigationLink(destination: StatisticsView()) {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.green.opacity(0.1))
                                .frame(maxWidth: .infinity)
                                .frame(height: UIScreen.main.bounds.height / 3.5)
                                .overlay(
                                    Text("개인 업무 인사이트")
                                        .foregroundColor(.primary)
                                )
                        }

                        //MARK: - ✅ 세부 업무 인사이트 섹션
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.blue.opacity(0.1))
                            .frame(maxWidth: .infinity)
                            .frame(height: UIScreen.main.bounds.height / 3.5)
                            .overlay(
                                Text("세부 업무 인사이트")
                                    .foregroundColor(.primary)
                            )

                        //MARK: - ✅ WorkSession 리스트뷰
                        NavigationLink(destination: WorkSessionView()) {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.red.opacity(0.1))
                                .frame(maxWidth: .infinity)
                                .frame(height: UIScreen.main.bounds.height / 3.5)
                                .overlay(
                                    Text("WorkSession 리스트")
                                        .foregroundColor(.primary)
                                )
                        }
                        
                        //MARK: - ✅ 신기능 제안 블럭
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.yellow.opacity(0.1))
                            .frame(maxWidth: .infinity)
                            .frame(height: UIScreen.main.bounds.height / 3.5)
                            .overlay(
                                Text("새로운 기능을 제안해주세요.!!")
                                    .foregroundColor(.primary)
                            )
                    }
                }
                
                Divider()
                    .padding(.horizontal, -16)
                Spacer().frame(height: 16)
                
                //MARK: - ✅ Saac Control영역 핵심 기능!!
                HStack(spacing: 8) {
                    Text("SAAC")
                        .font(.body).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 3)
                        .background(Color.blue)
                        .cornerRadius(20)
                    
                    Text("Control")
                        .font(.body).bold()
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer().frame(height: 16)
                
                // ✅ 오늘의 한 마디
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        HStack() {
                            Text(workedTimeText)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .padding(.vertical, -8)
                                .background(Color.blue)
                                .cornerRadius(20)
                            
                            Spacer()
                            
                            Text("사악한 업무 V1.0~~💫")
                                .font(.subheadline)
                                .bold()
                                .padding()
                            
                            Spacer()
                        }
                        .padding(.leading, 8)
                        .padding(.trailing, 8)
                    )
                    .padding(.horizontal)
                    .frame(height: 50)
                
                Spacer().frame(height: 16)

                // ✅ 업무 그래프
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("00시")
                            .font(.caption2)
                        Spacer()
                        Text("24시")
                            .font(.caption2)
                    }
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 14)
                        
                        if let start = checkInTime {
                            Capsule()
                                .fill(Color.green.opacity(0.4))
                                .frame(width: widthBetween(start, checkOutTime ?? Date()), height: 14)
                                .offset(x: xOffset(for: start))
                        }
                        
                        if let start = coreStartTime, let end = coreEndTime {
                            Capsule()
                                .fill(Color.blue)
                                .frame(width: widthBetween(start, end), height: 14)
                                .offset(x: xOffset(for: start))
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer().frame(height: 16)

                let today = Date()
                let userReference = CKRecord.Reference(recordID: currentUserRecord.recordID, action: .none)

                if let mainSession = viewModel.sessions.first(where: {
                    $0.userReference.recordID == userReference.recordID &&
                    Calendar.current.isDate($0.date, inSameDayAs: today) &&
                    $0.workOption == "Main"
                }) {
                    if mainSession.checkOutTime == nil {
                        HStack(spacing: 16) {
                            SessionButton(isCheckedIn: $isCheckedIn) {
                                checkOutTime = Date()
                                timer?.invalidate()
                                workedTimeText = "0h 0m"
                                viewModel.checkOut(userRecord: currentUserRecord)
                            }

                            CoreTimeButton {
                                if coreStartTime == nil {
                                    coreStartTime = Date()
                                } else if coreEndTime == nil {
                                    coreEndTime = Date()
                                } else {
                                    coreStartTime = nil
                                    coreEndTime = nil
                                }
                            }

                            AdditionButton(isPresented: $showAdditionPopup)
                        }
                        .padding(.top, 8)
                    }
                } else {
                    HStack(spacing: 16) {
                        SessionButton(isCheckedIn: $isCheckedIn) {
                            let now = Date()
                            viewModel.checkIn(userRecord: currentUserRecord)
                            checkInTime = now
                            startWorkTimer()
                        }

                        CoreTimeButton {
                            if coreStartTime == nil {
                                coreStartTime = Date()
                            } else if coreEndTime == nil {
                                coreEndTime = Date()
                            } else {
                                coreStartTime = nil
                                coreEndTime = nil
                            }
                        }

                        AdditionButton(isPresented: $showAdditionPopup)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .sheet(isPresented: $showAdditionPopup) {
                AdditionPopupView(isPresented: $showAdditionPopup)
            }
            .onAppear {
                print("🟡 [MainUIView] onAppear - fetching sessions...")
                viewModel.fetchTodayMainSession(userRecord: currentUserRecord)
            }
            .onReceive(viewModel.$sessions) { sessions in
                let today = Calendar.current.startOfDay(for: Date())
                let userReference = CKRecord.Reference(recordID: currentUserRecord.recordID, action: .none)
                print("🟢 [MainUIView] Received \(sessions.count) session(s). Checking today's Main session state...")

                if let session = sessions.first(where: {
                    $0.userReference.recordID == userReference.recordID &&
                    Calendar.current.startOfDay(for: $0.date) == today &&
                    $0.workOption == "Main" &&
                    $0.checkOutTime == nil
                }) {
                    print("✅ [MainUIView] Main session found for today without checkOutTime → Showing 퇴근 버튼")
                    checkInTime = session.checkInTime
                    isCheckedIn = true
                    startWorkTimer()
                } else if let session = sessions.first(where: {
                    $0.userReference.recordID == userReference.recordID &&
                    Calendar.current.startOfDay(for: $0.date) == today &&
                    $0.workOption == "Main" &&
                    $0.checkOutTime != nil
                }) {
                    print("🔵 [MainUIView] Main session exists but already checked out → Hiding buttons")
                    isCheckedIn = false
                    checkInTime = session.checkInTime
                    checkOutTime = session.checkOutTime
                } else {
                    print("🟠 [MainUIView] No Main session for today → Showing 출근 버튼")
                    isCheckedIn = false
                    checkInTime = nil
                    checkOutTime = nil
                }
            }
        }
    }
}

// MARK: - MainUIView Extensions
extension MainUIView {
    private func updateTodayMainSessionState() {
        let today = Date()
        let userReference = CKRecord.Reference(recordID: currentUserRecord.recordID, action: .none)

        let mainSession = viewModel.sessions.first(where: {
            $0.userReference.recordID == userReference.recordID &&
            Calendar.current.isDate($0.date, inSameDayAs: today) &&
            $0.workOption == "Main" &&
            $0.checkOutTime == nil
        })

        if let session = mainSession {
            checkInTime = session.checkInTime
            isCheckedIn = true
            startWorkTimer()
        }
    }
}

//MARK: - ✅ 프리뷰 코드
struct MainUIView_Previews: PreviewProvider {
    static var previews: some View {
        MainUIView(
            viewModel: AttendanceViewModel(),
            currentUserRecord: {
                let record = CKRecord(recordType: "AppUsers")
                record["userName"] = "고양이"
                return record
            }(),
            selectedWorkOption: .constant("에자일 근무")
        )
        .environmentObject(AppStateViewModel()) // ✅ Inject environment object
    }
}

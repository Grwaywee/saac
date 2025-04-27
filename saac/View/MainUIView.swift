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
    @State private var isCoreTimeEnded = false

    @State private var workedTimeText: String = "0h 0m"
    @State private var timer: Timer? = nil

    @State private var graphWidth: CGFloat = 0
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
                    .padding(.horizontal, -16)
                
                ScrollView {
                    VStack(spacing: 16) {
                        
                        Spacer().frame(height: 2)

                        //MARK: - ✅ WorkSession 리스트뷰 (고급 카드형)
                        NavigationLink(destination: WorkSessionView()) {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(.systemBackground), Color.red.opacity(0.07)]),
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 220)
                                .overlay(
                                    VStack(alignment: .leading, spacing: 14) {
                                        Text("WorkSession 리스트")
                                            .font(.title3)
                                            .bold()
                                            .foregroundColor(Color.red.opacity(0.6))
                                            .padding(.bottom, 2)
                                        
                                        let recentMainSessions = viewModel.sessions
                                            .filter { $0.workOption == "Main" }
                                            .sorted { $0.date > $1.date }
                                            .prefix(3)
                                        
                                        ForEach(Array(recentMainSessions), id: \.id) { session in
                                            WorkSessionCardView(session: session)
                                        }
                                        if recentMainSessions.isEmpty {
                                            Text("최근 세션 정보가 없습니다.")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .padding(.top, 8)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 8)
                                )
                        }
                        
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
                        
                        //MARK: - ✅ 신기능 제안 블럭
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.yellow.opacity(0.1))
                            .frame(maxWidth: .infinity)
                            .frame(height: UIScreen.main.bounds.height / 3.5)
                            .overlay(
                                Text("새로운 기능을 제안해주세요.!!")
                                    .foregroundColor(.primary)
                            )
                        Spacer().frame(height: 2)
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
                
                //MARK: - ✅ 오늘의 한 마디
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

                //MARK: - ✅ 업무 그래프
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("00시")
                            .font(.caption2)
                        Spacer()
                        Text("06시")
                            .font(.caption2)
                        Spacer()
                        Text("12시")
                            .font(.caption2)
                        Spacer()
                        Text("18시")
                            .font(.caption2)
                        Spacer()
                        Text("24시")
                            .font(.caption2)
                    }

                    ZStack(alignment: .leading) {
                        // ✅ 그래프 배경
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 14)
                            .background(
                                GeometryReader { proxy in
                                    Color.clear
                                        .onAppear {
                                            graphWidth = proxy.size.width
                                        }
                                        .onChange(of: proxy.size.width) { newWidth in
                                            graphWidth = newWidth
                                        }
                                }
                            )

                        // ✅ 메인세션 그래프
                        if let start = checkInTime {
                            Capsule()
                                .fill(Color.green.opacity(0.4))
                                .frame(width: TimeBarCalculator.barWidth(from: start, to: checkOutTime ?? Date(), totalWidth: graphWidth), height: 14)
                                .offset(x: TimeBarCalculator.xOffset(for: start, totalWidth: graphWidth))
                        }

                        // ✅ 코어타임 그래프
                        if let start = coreStartTime, let end = coreEndTime {
                            Capsule()
                                .fill(Color.blue)
                                .frame(width: TimeBarCalculator.barWidth(from: start, to: end, totalWidth: graphWidth), height: 14)
                                .offset(x: TimeBarCalculator.xOffset(for: start, totalWidth: graphWidth))
                        }

                        // ✅ 점심시간 캡슐 (Lunch time capsule)
                        let lunchStart = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
                        let lunchEnd = Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date())!
                        Capsule()
                            .fill(Color.yellow.opacity(0.7))
                            .frame(width: TimeBarCalculator.barWidth(from: lunchStart, to: lunchEnd, totalWidth: graphWidth), height: 14)
                            .offset(x: TimeBarCalculator.xOffset(for: lunchStart, totalWidth: graphWidth))

                        // ✅ Add/Del 세션 캡슐 렌더링
                        ForEach(viewModel.sessions.filter { $0.workOption == "Add" || $0.workOption == "Del" }, id: \.id) { session in
                            if let start = session.checkInTime, let end = session.checkOutTime {
                                Capsule()
                                    .fill(session.workOption == "Add" ? Color.purple.opacity(0.5) : Color.red.opacity(0.3))
                                    .frame(width: TimeBarCalculator.barWidth(from: start, to: end, totalWidth: graphWidth), height: 14)
                                    .offset(x: TimeBarCalculator.xOffset(for: start, totalWidth: graphWidth))
                                    .overlay(
                                        session.workOption == "Del"
                                        ? Capsule()
                                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                            .foregroundColor(.white)
                                        : nil
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer().frame(height: 16)

                //MARK: - ✅ 하단 버튼 상태 관리
                let today = Date()
                let userReference = CKRecord.Reference(recordID: currentUserRecord.recordID, action: .none)

                // 버튼 노출 로직 리팩터링: 출근/퇴근/코어타임 버튼 노출 조건 명확화
                if let mainSession = viewModel.sessions.first(where: {
                    $0.userReference.recordID == userReference.recordID &&
                    Calendar.current.isDate($0.date, inSameDayAs: today) &&
                    $0.workOption == "Main"
                }) {
                    // 출근 상태 (메인세션이 있고, 체크아웃이 안 된 경우): 퇴근 버튼 노출
                    if mainSession.checkOutTime == nil {
                        HStack(spacing: 16) {
                            // 퇴근 버튼: 메인세션이 있고 체크아웃이 안 된 경우에만
                            SessionButton(isCheckedIn: $isCheckedIn) {
                                if let session = viewModel.sessions.first(where: {
                                    $0.userReference.recordID == CKRecord.Reference(recordID: currentUserRecord.recordID, action: .none).recordID &&
                                    Calendar.current.isDate($0.date, inSameDayAs: Date()) &&
                                    $0.workOption == "Main" &&
                                    $0.checkOutTime == nil
                                }) {
                                    // ✅ 서버 저장 성공 후에만 fetchTodayMainSession으로 UI 갱신
                                    viewModel.checkOut(session: session, userRecord: currentUserRecord)
                                    // sessions, checkOutTime, isCheckedIn 등은 onReceive에서만 갱신
                                } else {
                                    print("⚠️ [퇴근 버튼] 퇴근 가능한 메인세션을 찾지 못했습니다.")
                                }
                            }
                            // 코어타임 버튼: 출근 상태이며, 아직 퇴근하지 않았고, 코어타임이 없다면 노출
                            if !isCoreTimeEnded {
                                if let start = mainSession.coreStartTime, let end = mainSession.coreEndTime {
                                    CoreTimeButton(isCoreTimeActive: true, isVisible: true)
                                } else {
                                    CoreTimeButton(isCoreTimeActive: false, isVisible: true) {
                                        let start = Date()
                                        let end = Calendar.current.date(byAdding: .hour, value: 4, to: start)!
                                        viewModel.updateCoreTime(for: mainSession, start: start, end: end)
                                    }
                                }
                            }
                            AdditionButton(isPresented: $showAdditionPopup)
                        }
                        .padding(.top, 8)
                    } else {
                        // 퇴근 완료 상태: 출근/퇴근/코어타임 버튼 모두 숨김 (코어타임 버튼은 퇴근 이후에는 절대 표시하지 않음)
                        HStack(spacing: 16) {
                            AdditionButton(isPresented: $showAdditionPopup)
                        }
                        .padding(.top, 8)
                    }
                } else {
                    // 출근 전: 출근 버튼만 노출, 코어타임 버튼은 숨김
                    HStack(spacing: 16) {
                        SessionButton(isCheckedIn: $isCheckedIn) {
                            let now = Date()
                            viewModel.checkIn(userRecord: currentUserRecord)
                            checkInTime = now
                            startWorkTimer()
                            // 출근 시 코어타임 관련 상태 명확히 초기화
                            coreStartTime = nil
                            coreEndTime = nil
                            isCoreTimeEnded = false
                        }
                        // 코어타임 버튼은 출근 전에는 노출하지 않음
                        EmptyView()
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
                print("\n----------Main WorkSession 조회----------MainUIView onAppear----------\n")
                print("🟡 AttendanceViewModel의 fetchTodayMainSession() 호출...")
                viewModel.fetchTodayMainSession(userRecord: currentUserRecord)
                
                print("🟣 AttendanceViewModel의 fetchUserSessions() 호출...")
                viewModel.fetchUserSessions(userRecord: currentUserRecord)
            }
            .onReceive(viewModel.$sessions) { sessions in
                print("🆕 [onReceive] 전체 세션 업데이트 감지됨: \(sessions.count)개 세션 (Add/Del 포함 가능)")
                print("\n----------Main WorkSession 반영----------MainUIView onReceive----------\n")
                let today = Calendar.current.startOfDay(for: Date())
                let userReference = CKRecord.Reference(recordID: currentUserRecord.recordID, action: .none)
                print("🟢 데이터 변화 발생! 총 \(sessions.count) 세션이 있음. 오늘의 메인세션을 확인하는중...")

                // 오늘 날짜 + 유저ID + workOption == Main
                if let session = sessions.first(where: {
                    $0.userReference.recordID == userReference.recordID &&
                    Calendar.current.startOfDay(for: $0.date) == today &&
                    $0.workOption == "Main"
                }) {
                    // 코어타임 동기화
                    coreStartTime = session.coreStartTime
                    coreEndTime = session.coreEndTime
                    // --- CoreTime Ended 타이머 및 상태 관리 ---
                    if session.checkOutTime != nil {
                        // 퇴근 이후에는 코어타임 버튼 절대 표시하지 않음
                        isCoreTimeEnded = true
                    } else if let end = session.coreEndTime {
                        if end < Date() {
                            isCoreTimeEnded = true
                        } else {
                            isCoreTimeEnded = false
                            let interval = end.timeIntervalSinceNow
                            DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                                isCoreTimeEnded = true
                            }
                        }
                    } else {
                        isCoreTimeEnded = false
                    }
                    if session.checkOutTime == nil {
                        print("✅ 체크아웃되지 않고 오늘에 해당하는 메인세션이 존재함 → Showing 퇴근 버튼")
                        checkInTime = session.checkInTime
                        checkOutTime = nil
                        isCheckedIn = true
                        startWorkTimer()
                    } else {
                        print("🔵 이미 체크아웃된 메인세션이 존재함 → Hiding 출근/퇴근/코어타임 버튼")
                        checkInTime = session.checkInTime
                        checkOutTime = session.checkOutTime
                        isCheckedIn = false
                        timer?.invalidate()
                        workedTimeText = "0h 0m"
                    }
                } else {
                    print("🟠 오늘에 해당하는 메인 세션 없음 → Showing 출근 버튼")
                    checkInTime = nil
                    checkOutTime = nil
                    isCheckedIn = false
                    timer?.invalidate()
                    workedTimeText = "0h 0m"
                    // 출근 세션이 없으므로 코어타임도 nil로
                    coreStartTime = nil
                    coreEndTime = nil
                    isCoreTimeEnded = false
                }
                print("----------이상 반영 끝----------MainUIView onReceive----------\n")
            }
        }
    }
}

// MARK: - ✅ MainUIView Extensions
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

// MARK: - DateFormatter Extension for Short Time
extension DateFormatter {
    static let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - 고급 WorkSession 카드뷰
struct WorkSessionCardView: View {
    let session: WorkSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 사용자 이름
            Text(session.userName)
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.bottom, 2)
            
            HStack(spacing: 10) {
                // 출근 시간
                if let checkIn = session.checkInTime {
                    Label {
                        Text("\(checkIn, formatter: DateFormatter.shortTimeFormatter)")
                            .font(.system(size: 14, weight: .medium))
                    } icon: {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(Color.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
                }
                // 퇴근 시간
                if let checkOut = session.checkOutTime {
                    Label {
                        Text("\(checkOut, formatter: DateFormatter.shortTimeFormatter)")
                            .font(.system(size: 14, weight: .medium))
                    } icon: {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(Color.red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.12))
                    .clipShape(Capsule())
                }
                Spacer()
                // 총 근무 시간
                if let checkIn = session.checkInTime, let checkOut = session.checkOutTime {
                    let interval = Int(checkOut.timeIntervalSince(checkIn))
                    let hours = interval / 3600
                    let minutes = (interval % 3600) / 60
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("\(hours)h \(minutes)m")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            
            // 코어타임 정보 블록
            if let coreStart = session.coreStartTime, let coreEnd = session.coreEndTime {
                let interval = coreEnd.timeIntervalSince(coreStart)
                let hours = Int(interval) / 3600
                let minutes = (Int(interval) % 3600) / 60
                let isNormal = interval >= 4 * 3600
                HStack(spacing: 10) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isNormal ? .blue : .red)
                    Text("코어타임 \(hours)h \(minutes)m")
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                    Text(isNormal ? "코어타임 정상 참여" : "코어타임 미달")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isNormal ? .blue : .red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(isNormal ? Color.blue.opacity(0.15) : Color.red.opacity(0.15))
                        .clipShape(Capsule())
                }
                .padding(.top, 1)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)]),
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.12), lineWidth: 1)
        )
        .padding(.bottom, 2)
    }
}

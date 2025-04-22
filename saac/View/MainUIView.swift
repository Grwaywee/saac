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
    
    let workOptions = ["Main", "addition", "deletion"]
    
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
    
    let fullWidth = UIScreen.main.bounds.width - 32
    let totalSeconds: CGFloat = 24 * 60 * 60
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ✅ "이름" 님의 사악한 업무 + 설정 버튼
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
                        NavigationLink(destination: StatisticsView()) {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(UIColor.systemGray5))
                                .frame(maxWidth: .infinity)
                                .frame(height: UIScreen.main.bounds.height / 3.5)
                                .overlay(
                                    Text("업무 시간 통계")
                                        .foregroundColor(.primary)
                                )
                        }

                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(UIColor.systemGray5))
                            .frame(maxWidth: .infinity)
                            .frame(height: UIScreen.main.bounds.height / 3.5)
                            .overlay(
                                Text("초과 및 공백 통계")
                                    .foregroundColor(.primary)
                            )

                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(UIColor.systemGray5))
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
                HStack {
                    Spacer()
                    Text("주 40시간 오늘도 사악하게 화이팅~~💫")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 0.9, green: 0.95, blue: 1.0))
                .cornerRadius(12)
                
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

                // ✅ 출퇴근, 코어타임 버튼
                HStack(spacing: 16) {
                    SessionButton(isCheckedIn: $isCheckedIn) {
                        if checkInTime == nil {
                            let now = Date()
                            viewModel.checkIn(
                                userRecord: currentUserRecord,
                                workOption: selectedWorkOption
                            )
                            checkInTime = now
                        } else if checkOutTime == nil {
                            checkOutTime = Date()
                        } else {
                            checkInTime = nil
                            checkOutTime = nil
                        }
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
                }
                .padding(.top, 8)
            }
            .padding()
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

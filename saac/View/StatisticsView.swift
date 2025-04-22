import SwiftUI

struct StatisticsView: View {
    @State private var selectedView = "주간"
    private let views = ["Days", "Weeks"]
    
    // Dummy data
    private let weeklyData = [4.0, 6.5, 7.0, 5.5, 8.0, 3.5, 0.0]
    private let monthlyData = [140.0, 132.0, 160.0, 155.0]

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("고양이님의 근태 인사이트")
                    .font(.title)
                    .bold()
                    .padding(.top, 24)

                if selectedView == "Days" {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.green.opacity(0.1))
                        .overlay(
                            BarGraph(data: weeklyData, labels: ["월", "화", "수", "목", "금", "토", "일"])
                                .padding()
                        )
                        .padding(.horizontal)
                        .frame(height: 260)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.green.opacity(0.1))
                        .overlay(
                            BarGraph(data: monthlyData, labels: ["1일", "8일", "15일", "22일"])
                                .padding()
                        )
                        .padding(.horizontal)
                        .frame(height: 260)
                }
                
                Picker("View", selection: $selectedView) {
                    ForEach(views, id: \.self) { view in
                        Text(view)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 90)
                
                Divider()
                    
                HStack(spacing: 8) {
                    Text("SAAC")
                        .font(.body).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 3)
                        .background(Color.green)
                        .cornerRadius(20)
                    
                    Text("Insight")
                        .font(.body).bold()
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                       
                // ✅ 어제와 시간 비교 구역
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.green.opacity(0.1))
                    .overlay(
                        HStack() {
                            Text("+ 1시간 10분")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .padding(.vertical, -8)
                                .background(Color.green)
                                .cornerRadius(20)
                            
                            Spacer()
                            
                            Text("어제보다 더 달리는 중이에요!")
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
                
                // ✅ 지난 주와 시간 비교 구역
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.green.opacity(0.1))
                    .overlay(
                        HStack() {
                            Text("+ 20%")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .padding(.vertical, -8)
                                .background(Color.green)
                                .cornerRadius(20)
                            
                            Spacer()
                            
                            Text("지난 주 보다 더 달리는 중이에요!")
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
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        VStack(alignment: .center, spacing: 8) {
                            Text("주 40시간까지 40%를 채웠어요!")
                                .font(.headline)
                                .bold()
                                .padding(.bottom, 4)

                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 30)

                                Capsule()
                                    .fill(Color.green)
                                    .frame(width: UIScreen.main.bounds.width * 0.4 - 40, height: 30) // 40% 진행
                            }
                            
                            
                            Text("시간은 신뢰의 기반이에요!")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .padding(.top, 5)
                            
                        }
                        .padding()
                    )
                    .padding(.horizontal)
                    .frame(height: 150)
                
                Spacer()
            }
            .navigationTitle("📊 업무 시간 통계")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct BarGraph: View {
    let data: [Double]
    let labels: [String]
    
    var maxValue: Double {
        (data.max() ?? 1.0) * 1.2 // Y축 여유 공간
    }

    var body: some View {
        VStack {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(data.indices, id: \.self) { index in
                    VStack {
                        Text("\(data[index], specifier: "%.1f")h")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 24, height: CGFloat(data[index] / maxValue) * 150)
                        Text(labels[index])
                            .font(.caption)
                            .frame(height: 20)
                    }
                }
            }
            .padding(.horizontal)
            .frame(height: 200)
        }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
    }
}

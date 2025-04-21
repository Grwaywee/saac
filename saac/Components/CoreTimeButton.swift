import SwiftUI

struct CoreTimeButton: View {
    @State private var isCoreActive = false
    @State private var timer: Timer? = nil
    @State private var startTime: Date? = nil

    let action: () -> Void

    var body: some View {
        Button(action: handleTap) {
            Text(isCoreActive ? "코어타임중..." : "코어타임 시작")
                .font(.callout)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isCoreActive ? Color.orange : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(radius: 2)
        }
    }

    private func handleTap() {
        if isCoreActive {
            // 수동 종료
            timer?.invalidate()
            timer = nil
            isCoreActive = false
            startTime = nil
        } else {
            // 코어타임 시작
            startTime = Date()
            isCoreActive = true
            action()

            timer = Timer.scheduledTimer(withTimeInterval: 4 * 60 * 60, repeats: false) { _ in
                isCoreActive = false
                startTime = nil
            }
        }
    }
}

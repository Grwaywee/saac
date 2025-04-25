import Foundation
import SwiftUI

struct TimeBarCalculator {
    
    /// Total seconds in a full 24-hour day.
    static let totalSeconds: CGFloat = 24 * 60 * 60

    /// Converts a `Date` into an X offset (0.0 to 1.0) on a 24-hour timeline, using Asia/Seoul (KST) timezone.
    static func offsetRatio(for date: Date) -> CGFloat {
        let calendar = Calendar(identifier: .gregorian)
        let kst = TimeZone(identifier: "Asia/Seoul")!
        let components = calendar.dateComponents(in: kst, from: date)
        let hour = CGFloat(components.hour ?? 0)
        let minute = CGFloat(components.minute ?? 0)
        let second = CGFloat(components.second ?? 0)
        let seconds = (hour * 3600) + (minute * 60) + second
        return seconds / totalSeconds
    }

    /// Calculates width ratio (0.0 to 1.0) between two `Date`s.
    static func widthRatio(from start: Date, to end: Date) -> CGFloat {
        let startRatio = offsetRatio(for: start)
        let endRatio = offsetRatio(for: end)
        return max(endRatio - startRatio, 0)
    }

    /// Converts a `Date` to pixel offset based on given `totalWidth`
    static func xOffset(for date: Date, totalWidth: CGFloat) -> CGFloat {
        return offsetRatio(for: date) * totalWidth
    }

    /// Converts a time span between two dates to a pixel width, based on given `totalWidth`
    static func barWidth(from start: Date, to end: Date, totalWidth: CGFloat) -> CGFloat {
        return widthRatio(from: start, to: end) * totalWidth
    }
}

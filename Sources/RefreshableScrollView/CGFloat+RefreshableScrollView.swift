import AppKit

extension CGFloat {
    var radiansToDegrees: CGFloat {
        return self * 180 / .pi
    }

    var degreesToRadians: CGFloat {
        return self * .pi / 180
    }
}

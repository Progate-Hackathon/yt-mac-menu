import SwiftUI

/// Viewが希望するウィンドウサイズをFloatingWindowControllerに伝えるPreferenceKey
struct WindowSizeKey: PreferenceKey {
    static let defaultValue: CGSize? = nil
    static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
        value = nextValue() ?? value
    }
}

extension View {
    /// このViewが表示されるウィンドウの希望サイズを指定する
    func preferredWindowSize(width: CGFloat, height: CGFloat) -> some View {
        preference(key: WindowSizeKey.self, value: CGSize(width: width, height: height))
    }
}

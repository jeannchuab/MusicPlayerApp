import SwiftUI

enum AppFont {
    enum Weight: Int {
        case light300 = 300
        case regular400 = 400
        case medium500 = 500
        case semibold600 = 600
        case bold700 = 700
        case heavy800 = 800
    }

    static func font(
        size: CGFloat,
        weight: Weight = .regular400,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        Font.custom(postScriptName(for: weight), size: size, relativeTo: textStyle)
    }

    private static func postScriptName(for weight: Weight) -> String {
        switch weight {
        case .light300:
            "ArticulatCF-Light"
        case .regular400:
            "ArticulatCF-Regular"
        case .medium500:
            "ArticulatCF-Medium"
        case .semibold600:
            "ArticulatCF-DemiBold"
        case .bold700:
            "ArticulatCF-Bold"
        case .heavy800:
            "ArticulatCF-Heavy"
        }
    }
}

extension Font {
    static func app(
        _ size: CGFloat,
        weight: AppFont.Weight = .regular400,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        AppFont.font(size: size, weight: weight, relativeTo: textStyle)
    }
}

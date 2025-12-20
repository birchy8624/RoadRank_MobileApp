import SwiftUI
import UIKit

struct SharePreviewBuilder {
    static let image: UIImage = {
        let size = CGSize(width: 1200, height: 630)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let cgContext = context.cgContext
            let colors = [UIColor(Theme.primary).cgColor, UIColor(Theme.secondary).cgColor]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])

            if let gradient {
                cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }

            cgContext.setFillColor(UIColor.black.withAlphaComponent(0.25).cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))

            let iconSize: CGFloat = 140
            let iconConfig = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .bold)
            if let icon = UIImage(systemName: "road.lanes", withConfiguration: iconConfig)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {
                let iconRect = CGRect(x: 80, y: 120, width: iconSize, height: iconSize)
                icon.draw(in: iconRect)
            }

            let title = "RoadRank"
            let subtitle = "Discover your next favorite road"

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 72, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .semibold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]

            title.draw(at: CGPoint(x: 80, y: 300), withAttributes: titleAttributes)
            subtitle.draw(at: CGPoint(x: 80, y: 390), withAttributes: subtitleAttributes)
        }
    }()
}

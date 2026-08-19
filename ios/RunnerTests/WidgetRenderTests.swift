import SwiftUI
import XCTest

/// Renders every widget tile the design draws and writes it out as a PNG.
///
/// Not an assertion — a contact sheet. The widget's whole job is to look like
/// the design, and 35 skies times three layouts is more than anyone will check
/// by adding widgets to a home screen one at a time. Run this and compare the
/// output against the design's own tiles.
///
///     xcodebuild test -project ios/Runner.xcodeproj -scheme Runner \
///       -destination 'platform=iOS Simulator,name=iPhone 16' \
///       -only-testing:RunnerTests/WidgetRenderTests
///
/// The directory it wrote to is printed at the end of the run.
final class WidgetRenderTests: XCTestCase {
    @MainActor
    func testRenderEveryTile() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("atmosflow-widgets", isDirectory: true)
        try? FileManager.default.removeItem(at: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        for condition in WidgetCondition.allCases {
            for sky in WidgetSky.allCases {
                let entry = entry(condition, sky)
                try write(SmallWidgetView(entry: entry), size: CGSize(width: 160, height: 160),
                          radius: 20, to: directory, named: "small-\(condition)-\(sky)")
                try write(SquareWidgetView(entry: entry), size: CGSize(width: 200, height: 200),
                          radius: 24, to: directory, named: "square-\(condition)-\(sky)")
                try write(WideWidgetView(entry: entry), size: CGSize(width: 280, height: 152),
                          radius: 20, to: directory, named: "wide-\(condition)-\(sky)")
            }
        }

        print("WIDGET TILES: \(directory.path)")
    }

    /// The design's own sample readings, so the render is comparable to it.
    private func entry(_ condition: WidgetCondition, _ sky: WidgetSky) -> WidgetEntry {
        let temperature: [WidgetSky: Int] = [
            .dawn: 12, .morning: 16, .afternoon: 22, .evening: 18, .night: 11,
        ]
        let clock: [WidgetSky: String] = [
            .dawn: "5:42", .morning: "9:15", .afternoon: "14:30",
            .evening: "19:48", .night: "23:20",
        ]
        return WidgetEntry(
            date: Date(),
            condition: condition,
            sky: sky,
            temperature: "\(temperature[sky] ?? 20)°",
            humidity: "58%",
            clock: clock[sky] ?? "12:00",
            place: "SF",
            caption: "\(sky.label) · \(condition.label)",
            conditionLabel: condition.label
        )
    }

    @MainActor
    private func write<V: View>(_ view: V, size: CGSize, radius: CGFloat,
                                to directory: URL, named name: String) throws {
        let renderer = ImageRenderer(
            content: view
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        )
        renderer.scale = 2
        guard let image = renderer.uiImage, let data = image.pngData() else {
            XCTFail("could not render \(name)"); return
        }
        try data.write(to: directory.appendingPathComponent("\(name).png"))
    }
}

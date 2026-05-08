import Foundation
import UIKit

enum StatsPDFExporter {
    static func makeReportPDF(
        sessions: [SessionHistoryEntry],
        periodLabel: String,
        totalMinutes: Int,
        sessionsCount: Int,
        streakDays: Int
    ) -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let df: DateFormatter = {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return f
        }()

        return renderer.pdfData { context in
            context.beginPage()

            let margin: CGFloat = 56
            var y: CGFloat = margin

            let title = "FitSphere — Activity report" as NSString
            title.draw(
                at: CGPoint(x: margin, y: y),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                    .foregroundColor: UIColor.label
                ]
            )
            y += 32

            let subtitle = periodLabel as NSString
            subtitle.draw(
                at: CGPoint(x: margin, y: y),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                    .foregroundColor: UIColor.secondaryLabel
                ]
            )
            y += 28

            let summary = "Sessions: \(sessionsCount)   ·   Total: \(totalMinutes) min   ·   Streak: \(streakDays) days" as NSString
            summary.draw(
                at: CGPoint(x: margin, y: y),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                    .foregroundColor: UIColor.label
                ]
            )
            y += 36

            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: UIColor.secondaryLabel
            ]
            ("Date & time".padding(toLength: 28, withPad: " ", startingAt: 0)
            + "Min".padding(toLength: 6, withPad: " ", startingAt: 0)
            + "Type".padding(toLength: 14, withPad: " ", startingAt: 0)
            + "Routine") .draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttrs)
            y += 18

            let rowAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.label
            ]

            for entry in sessions.sorted(by: { $0.completedAt > $1.completedAt }) {
                if y > pageHeight - margin - 40 {
                    context.beginPage()
                    y = margin
                }

                let dateStr = df.string(from: entry.completedAt)
                let typeStr = entry.source.displayTitle
                let routineStr = entry.routineName ?? "—"
                let line =
                    String(dateStr.prefix(26)).padding(toLength: 28, withPad: " ", startingAt: 0)
                    + "\(entry.durationMinutes)".padding(toLength: 6, withPad: " ", startingAt: 0)
                    + String(typeStr.prefix(12)).padding(toLength: 14, withPad: " ", startingAt: 0)
                    + String(routineStr.prefix(40))
                (line as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: rowAttrs)
                y += 16
            }

            y += 20
            if y > pageHeight - margin - 24 {
                context.beginPage()
                y = margin
            }
            let footer = "Generated in FitSphere (local report)" as NSString
            footer.draw(
                at: CGPoint(x: margin, y: y),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                    .foregroundColor: UIColor.tertiaryLabel
                ]
            )
        }
    }

    static func makeReportPlainText(
        sessions: [SessionHistoryEntry],
        periodLabel: String,
        totalMinutes: Int,
        sessionsCount: Int,
        streakDays: Int
    ) -> String {
        let df2 = DateFormatter()
        df2.dateStyle = .medium
        df2.timeStyle = .short

        var lines: [String] = []
        lines.append("FitSphere — Activity report")
        lines.append(periodLabel)
        lines.append("Sessions: \(sessionsCount) | Total: \(totalMinutes) min | Streak: \(streakDays) days")
        lines.append("")

        for entry in sessions.sorted(by: { $0.completedAt > $1.completedAt }) {
            let routine = entry.routineName.map { " | \($0)" } ?? ""
            lines.append("\(df2.string(from: entry.completedAt)) | \(entry.durationMinutes) min | \(entry.source.displayTitle)\(routine)")
        }
        return lines.joined(separator: "\n")
    }
}

import AppKit
import Foundation

struct DiffHunk: Identifiable, Equatable, Sendable {
	static let codeFontSize: CGFloat = 12
	static let rowHeight: CGFloat = 20
	static let headerHeight: CGFloat = 30
	static let verticalPadding: CGFloat = 8

	let id: Int
	let header: DiffLine?
	let lines: ArraySlice<DiffLine>
	let sideBySideRows: ArraySlice<DiffSideBySideRow>
	let oldTextWidth: CGFloat
	let newTextWidth: CGFloat

	static func verticalCenter(
		of lineID: DiffLine.ID, in hunks: [DiffHunk], mode: DiffPresentationMode
	) -> CGFloat? {
		var top = verticalPadding
		for hunk in hunks {
			if let header = hunk.header {
				if header.id == lineID { return top + headerHeight / 2 }
				top += headerHeight
			}
			switch mode {
			case .unified:
				if let index = hunk.lines.firstIndex(where: { $0.id == lineID }) {
					return top + (CGFloat(index - hunk.lines.startIndex) + 0.5) * rowHeight
				}
				top += CGFloat(hunk.lines.count) * rowHeight
			case .sideBySide:
				if let index = hunk.sideBySideRows.firstIndex(where: { $0.contains(lineID: lineID) }) {
					return top + (CGFloat(index - hunk.sideBySideRows.startIndex) + 0.5) * rowHeight
				}
				top += CGFloat(hunk.sideBySideRows.count) * rowHeight
			}
		}
		return nil
	}

	static func build(from document: DiffDocument) throws -> [DiffHunk] {
		let sideBySideRows = try DiffSideBySideBuilder.buildCancellable(from: document)
		let attributes: [NSAttributedString.Key: Any] = [
			.font: NSFont.monospacedSystemFont(ofSize: codeFontSize, weight: .regular)
		]
		let asciiCharacterWidth = ("M" as NSString).size(withAttributes: attributes).width
		let lines = document.lines
		var hunks: [DiffHunk] = []
		var lineStart = 0
		var rowStart = 0

		while lineStart < lines.count {
			let first = lines[lineStart]
			let header = first.kind == .hunk ? first : nil
			let bodyStart = header == nil ? lineStart : lineStart + 1
			var lineEnd = bodyStart
			var oldTextWidth: CGFloat = 0
			var newTextWidth: CGFloat = 0

			while lineEnd < lines.count, lines[lineEnd].kind != .hunk {
				if lineEnd.isMultiple(of: 256) { try Task.checkCancellation() }
				let line = lines[lineEnd]
				let text = line.sourceText
				let width =
					text.utf8.allSatisfy { (32...126).contains($0) }
					? CGFloat(text.utf8.count) * asciiCharacterWidth
					: (text as NSString).size(withAttributes: attributes).width
				if line.kind != .addition { oldTextWidth = max(oldTextWidth, width) }
				if line.kind != .deletion { newTextWidth = max(newTextWidth, width) }
				lineEnd += 1
			}

			let rowBodyStart = header == nil ? rowStart : rowStart + 1
			var rowEnd = rowBodyStart
			while rowEnd < sideBySideRows.count, sideBySideRows[rowEnd].fullWidthLine?.kind != .hunk {
				rowEnd += 1
			}

			hunks.append(
				DiffHunk(
					id: first.id, header: header, lines: lines[bodyStart..<lineEnd],
					sideBySideRows: sideBySideRows[rowBodyStart..<rowEnd],
					oldTextWidth: oldTextWidth.rounded(.up), newTextWidth: newTextWidth.rounded(.up)))
			lineStart = lineEnd
			rowStart = rowEnd
		}
		return hunks
	}
}

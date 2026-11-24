import DomainGitInterface
import SwiftUI

struct DiffUnifiedView: View {
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	@State private var scrollPosition = ScrollPosition()
	let document: DiffDocument
	let hunks: [DiffHunk]
	let filePath: String?
	let searchModel: RepositorySearchViewModel
	let lineAction: GitDiffLineAction?
	let hunkActions: [GitDiffHunkAction]
	let isApplyingAction: Bool
	let onApplyLine: (GitDiffLineSelection, GitDiffLineAction) -> Void
	let onApplyHunk: (GitDiffHunkSelection, GitDiffHunkAction) -> Void

	var body: some View {
		GeometryReader { geometry in
			let showsOldLineNumbers = document.showsOldLineNumbers
			let showsNewLineNumbers = document.showsNewLineNumbers
			let lineNumberWidth: CGFloat =
				(showsOldLineNumbers ? 46.0 : 0) + (showsNewLineNumbers ? 46 : 0)

			ScrollView(.vertical) {
				LazyVStack(alignment: .leading, spacing: 0) {
					ForEach(hunks) { hunk in
						if let header = hunk.header {
							lineView(header, showsOldLineNumbers: false, showsNewLineNumbers: false)
						}
						if !hunk.lines.isEmpty {
							let width = max(hunk.oldTextWidth, hunk.newTextWidth) + lineNumberWidth + 80
							ScrollView(.horizontal) {
								LazyVStack(alignment: .leading, spacing: 0) {
									ForEach(hunk.lines) { line in
										lineView(
											line, showsOldLineNumbers: showsOldLineNumbers,
											showsNewLineNumbers: showsNewLineNumbers
										)
									}
								}
								.frame(width: max(geometry.size.width, width), alignment: .leading)
								.textSelection(.enabled)
							}
							.defaultScrollAnchor(.leading)
						}
					}
				}
				.padding(.vertical, DiffHunk.verticalPadding)
				.frame(maxWidth: .infinity, alignment: .leading)
			}
			.scrollPosition($scrollPosition)
			.onChange(of: searchModel.currentMatchID) { _, _ in
				guard let sourceID = searchModel.currentMatch?.sourceID,
					let center = DiffHunk.verticalCenter(of: sourceID, in: hunks, mode: .unified)
				else { return }
				let offset = max(0, center - geometry.size.height / 2)
				if reduceMotion {
					scrollPosition.scrollTo(y: offset)
				} else {
					withAnimation(.easeInOut(duration: 0.15)) {
						scrollPosition.scrollTo(y: offset)
					}
				}
			}
		}
	}

	private func lineView(
		_ line: DiffLine, showsOldLineNumbers: Bool, showsNewLineNumbers: Bool
	) -> some View {
		DiffLineView(
			line: line,
			filePath: filePath,
			searchText: searchModel.query,
			activeSearchRange: searchModel.activeRange(for: line.id),
			showsOldLineNumbers: showsOldLineNumbers,
			showsNewLineNumbers: showsNewLineNumbers,
			lineAction: lineAction,
			hunkActions: hunkActions,
			isLoading: isApplyingAction,
			onApplyLine: onApplyLine,
			onApplyHunk: onApplyHunk
		)
	}
}

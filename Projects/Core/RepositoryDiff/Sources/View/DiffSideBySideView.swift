import DomainGitInterface
import SwiftUI

struct DiffSideBySideView: View {
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	@State private var scrollPosition = ScrollPosition()
	let hunks: [DiffHunk]
	let filePath: String?
	let searchModel: RepositorySearchViewModel
	let lineAction: GitDiffLineAction?
	let hunkActions: [GitDiffHunkAction]
	let isApplyingAction: Bool
	let onApplyLine: (GitDiffLineSelection, GitDiffLineAction) -> Void
	let onApplyHunk: (GitDiffHunkSelection, GitDiffHunkAction) -> Void

	private let separatorWidth: CGFloat = 28

	var body: some View {
		GeometryReader { geometry in
			let paneWidth = max(0, (geometry.size.width - separatorWidth) / 2)

			ScrollView(.vertical) {
				LazyVStack(alignment: .leading, spacing: 0) {
					ForEach(hunks) { hunk in
						if let header = hunk.header {
							DiffLineView(
								line: header, filePath: filePath, searchText: searchModel.query,
								activeSearchRange: searchModel.activeRange(for: header.id),
								showsOldLineNumbers: false, showsNewLineNumbers: false,
								lineAction: lineAction, hunkActions: hunkActions, isLoading: isApplyingAction,
								onApplyLine: onApplyLine, onApplyHunk: onApplyHunk
							)
						}
						if !hunk.sideBySideRows.isEmpty {
							HStack(alignment: .top, spacing: 0) {
								codePane(hunk, paneWidth: paneWidth, isOld: true)
								LazyVStack(spacing: 0) {
									ForEach(hunk.sideBySideRows) { row in
										lineActionButton(for: row)
											.frame(width: separatorWidth, height: DiffHunk.rowHeight)
									}
								}
								codePane(hunk, paneWidth: paneWidth, isOld: false)
							}
						}
					}
				}
				.padding(.vertical, DiffHunk.verticalPadding)
				.frame(maxWidth: .infinity, alignment: .leading)
			}
			.scrollPosition($scrollPosition)
			.onChange(of: searchModel.currentMatchID) { _, _ in
				guard let sourceID = searchModel.currentMatch?.sourceID,
					let center = DiffHunk.verticalCenter(of: sourceID, in: hunks, mode: .sideBySide)
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

	private func codePane(_ hunk: DiffHunk, paneWidth: CGFloat, isOld: Bool) -> some View {
		let width = (isOld ? hunk.oldTextWidth : hunk.newTextWidth) + 100
		return ScrollView(.horizontal) {
			LazyVStack(alignment: .leading, spacing: 0) {
				ForEach(hunk.sideBySideRows) { row in
					let line = isOld ? row.oldLine : row.newLine
					DiffSideBySidePane(
						line: line, filePath: filePath, searchText: searchModel.query,
						activeSearchRange: line.flatMap { searchModel.activeRange(for: $0.id) },
						isOld: isOld
					)
					.contextMenu { lineContextMenu(for: row) }
				}
			}
			.frame(width: max(paneWidth, width), alignment: .leading)
		}
		.defaultScrollAnchor(.leading)
		.frame(width: paneWidth)
	}

	@ViewBuilder
	private func lineActionButton(for row: DiffSideBySideRow) -> some View {
		if let selection = row.actionLine?.selection, let lineAction {
			Button {
				onApplyLine(selection, lineAction)
			} label: {
				Image(systemName: lineAction.systemImage)
					.frame(width: 20, height: 20)
			}
			.buttonStyle(.borderless)
			.tint(lineAction.tint)
			.disabled(isApplyingAction)
			.help(lineAction.title)
			.accessibilityLabel(lineAction.title)
		} else {
			Rectangle()
				.fill(.separator)
				.frame(width: 1)
				.accessibilityHidden(true)
		}
	}

	@ViewBuilder
	private func lineContextMenu(for row: DiffSideBySideRow) -> some View {
		if let selection = row.actionLine?.selection, let lineAction {
			Button(lineAction.title, systemImage: lineAction.systemImage) {
				onApplyLine(selection, lineAction)
			}
			.disabled(isApplyingAction)
		}
	}
}

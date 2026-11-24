import SwiftUI

public struct RepositoryActivityIndicator: View {
	private let title: String
	private let cancellation: (label: String, action: () -> Void)?

	public init(_ title: String, cancellation: (label: String, action: () -> Void)? = nil) {
		self.title = title
		self.cancellation = cancellation
	}

	public var body: some View {
		HStack(spacing: 6) {
			ProgressView()
				.controlSize(.small)
				.accessibilityHidden(true)

			Text(verbatim: "\(title)…")
				.font(.callout)
				.foregroundStyle(.secondary)
				.lineLimit(1)
				.truncationMode(.middle)
				.frame(maxWidth: 180)
				.help(title)

			if let cancellation {
				Button(cancellation.label, systemImage: "stop.fill", action: cancellation.action)
					.labelStyle(.iconOnly)
					.help(cancellation.label)
			}
		}
	}
}

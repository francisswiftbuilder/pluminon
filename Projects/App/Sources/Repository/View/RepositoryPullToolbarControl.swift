import FeatureRepositoryOperations
import SwiftUI

struct RepositoryPullToolbarControl: View {
	private let viewModel: RepositorySyncViewModel

	init(viewModel: RepositorySyncViewModel) {
		self.viewModel = viewModel
	}

	var body: some View {
		Button {
			viewModel.didRequestPull()
		} label: {
			Label("Pull", systemImage: "arrow.down")
		}
		.disabled(!viewModel.canPull)
		.help("Pull Current Branch")
	}
}

import FeatureRepositoryOperations
import SwiftUI

struct RepositoryWorkspaceToolbar: ToolbarContent {
	let viewModel: WorkspaceViewModel
	private let operationViewModel: RepositoryOperationViewModel
	private let referencesViewModel: RepositoryReferencesViewModel
	private let syncViewModel: RepositorySyncViewModel
	private let remotesViewModel: RemotesViewModel
	private let allowsRepositoryActions: Bool
	let onCreateBranch: () -> Void

	init(
		viewModel: WorkspaceViewModel,
		operationViewModel: RepositoryOperationViewModel,
		referencesViewModel: RepositoryReferencesViewModel,
		syncViewModel: RepositorySyncViewModel,
		remotesViewModel: RemotesViewModel,
		allowsRepositoryActions: Bool,
		onCreateBranch: @escaping () -> Void
	) {
		self.viewModel = viewModel
		self.operationViewModel = operationViewModel
		self.referencesViewModel = referencesViewModel
		self.syncViewModel = syncViewModel
		self.remotesViewModel = remotesViewModel
		self.allowsRepositoryActions = allowsRepositoryActions
		self.onCreateBranch = onCreateBranch
	}

	var body: some ToolbarContent {
		ToolbarItem(placement: .primaryAction) {
			if allowsRepositoryActions {
				let branchName = referencesViewModel.switchingBranchName
				if let activity = syncViewModel.activity,
					branchName == nil || syncViewModel.isBlockingLocalRefresh
				{
					RepositoryActivityIndicator(
						activity.statusDescription,
						cancellation: (activity.cancellationLabel, syncViewModel.didRequestCancelOperation)
					)
				} else if let branchName {
					RepositoryActivityIndicator("Switching to \(branchName)")
				}
			}
		}

		ToolbarSpacer(.flexible, placement: .primaryAction)

		ToolbarItemGroup(placement: .primaryAction) {
			Button("New Branch", systemImage: "arrow.triangle.branch", action: onCreateBranch)
				.disabled(
					!allowsRepositoryActions || !referencesViewModel.canCreateBranch || isMutating
						|| syncViewModel.isLoading
				)
				.help("Create a Branch from \(referencesViewModel.currentBranchName)")

			Button("Refresh", systemImage: "arrow.clockwise") {
				viewModel.didRequestRefresh()
			}
			.disabled(
				!allowsRepositoryActions || viewModel.isLoading || isMutating || syncViewModel.isLoading
			)
			.help("Refresh Repository")
		}

		ToolbarSpacer(.fixed, placement: .primaryAction)

		ToolbarItemGroup(placement: .primaryAction) {
			RepositoryFetchToolbarControl(
				syncViewModel: syncViewModel, remotesViewModel: remotesViewModel
			)
			.disabled(!allowsRepositoryActions || isMutating)
			RepositoryPullToolbarControl(viewModel: syncViewModel)
				.disabled(!allowsRepositoryActions || isMutating)
			RepositoryPushMenu(viewModel: syncViewModel)
				.disabled(!allowsRepositoryActions || isMutating)
		}
	}

	private var isMutating: Bool {
		operationViewModel.isLoading || referencesViewModel.isLoading
	}
}

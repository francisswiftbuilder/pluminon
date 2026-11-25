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

	var activityDescription: String? {
		guard allowsRepositoryActions else { return nil }
		let branchName = referencesViewModel.switchingBranchName
		if let activity = syncViewModel.activity,
			branchName == nil || syncViewModel.isBlockingLocalRefresh
		{
			return activity.statusDescription
		}
		if let branchName {
			return "Switching to \(branchName)"
		}
		if viewModel.isLoading {
			return viewModel.isLoadingContent ? "Loading Repository" : "Refreshing Repository"
		}
		return nil
	}

	var idleStatusDescription: String? {
		guard allowsRepositoryActions, !isMutating, !remotesViewModel.isLoading,
			referencesViewModel.operationState.isIdle,
			let branch = referencesViewModel.currentBranch,
			let upstream = branch.upstream,
			let remoteName = branch.upstreamRemoteName,
			let remote = remotesViewModel.remotes.first(where: { $0.name == remoteName }),
			remote.fetchError == nil
		else { return nil }

		let upstreamHash =
			branch.customUpstreamHash
			?? remote.branches.first(where: { $0.fullName == upstream })?.hash
		guard upstreamHash == branch.hash else { return nil }
		return String(localized: "Up to date")
	}

	var branchName: String? {
		guard allowsRepositoryActions else { return nil }
		return referencesViewModel.currentBranchName
	}

	var body: some ToolbarContent {
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

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct RepositoryTabsView: View {
	@Environment(\.windowTabCoordinator) private var coordinator
	@Bindable var viewModel: RepositoryTabsViewModel
	let accountViewModel: GitAccountViewModel
	let windowViewModel: RepositoryWindowViewModel
	@Binding var repositoryID: RepositoryTab.ID?
	@State private var browserSource: RepositoryWelcomeContainerView.Source? = .remote

	var body: some View {
		NavigationSplitView {
			sidebar
				.navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
		} detail: {
			if let repositoryTab {
				WorkspaceView(
					workspace: repositoryTab.workspace,
					windowViewModel: windowViewModel,
					repositoryID: repositoryTab.id
				)
			} else {
				RepositoryWelcomeContainerView(
					source: browserSource ?? .remote,
					accountViewModel: accountViewModel,
					repositories: viewModel.tabs.map(\.repository),
					isWorking: viewModel.isAddingRepository,
					onOpenRepository: presentRepositoryImporter,
					onOpenSavedRepository: showRepository,
					onCloneRepository: windowViewModel.didPresentCloneDestinationImporter,
					onCancel: viewModel.didRequestCancelAddingRepository
				)
			}
		}
		.navigationTitle(repositoryTab?.repository.name ?? "New Tab")
		.task {
			restoreRepositoryWindows()
		}
		.onChange(of: repositoryID) { _, id in
			activateRepository(id)
		}
		.onChange(of: windowViewModel.sidebarSelection) { _, selection in
			activateSidebarSelection(selection)
		}
		.toolbar {
			if let workspace = (repositoryTab ?? viewModel.selectedTab)?.workspace {
				RepositoryWorkspaceToolbar(
					viewModel: workspace.viewModel,
					operationViewModel: workspace.operationViewModel,
					referencesViewModel: workspace.referencesViewModel,
					syncViewModel: workspace.syncViewModel,
					remotesViewModel: workspace.remotesViewModel,
					allowsRepositoryActions: repositoryTab != nil,
					onCreateBranch: presentNewBranch
				)
			}
		}
		.toolbarRole(.editor)
		.fileImporter(
			isPresented: folderImporterPresentation,
			allowedContentTypes: [.folder],
			allowsMultipleSelection:
				windowViewModel.folderImportRequest?.allowsMultipleSelection ?? false
		) { handleFolderImport($0) }
		.modifier(RepositoryErrorAlertModifier(message: $viewModel.alertMessage))
	}

	@ViewBuilder
	private var sidebar: some View {
		if let repositoryTab {
			let workspace = repositoryTab.workspace
			RepositorySidebar(
				viewModel: workspace.viewModel,
				windowViewModel: windowViewModel,
				changesViewModel: workspace.changesViewModel,
				operationViewModel: workspace.operationViewModel,
				referencesViewModel: workspace.referencesViewModel,
				remotesViewModel: workspace.remotesViewModel,
				stashesViewModel: workspace.stashesViewModel,
				repositoryID: repositoryTab.id
			)
		} else {
			List(selection: $browserSource) {
				Label("Local", systemImage: "folder")
					.tag(RepositoryWelcomeContainerView.Source.local)
				Label("Remote", systemImage: "network")
					.tag(RepositoryWelcomeContainerView.Source.remote)
			}
			.listStyle(.sidebar)
		}
	}

	private func presentNewBranch() {
		repositoryTab?.workspace.referencesViewModel.didPresentNewBranch()
	}

	private func presentRepositoryImporter() {
		windowViewModel.didPresentRepositoryImporter()
	}

	private func handleFolderImport(_ result: Result<[URL], any Error>) {
		guard let request = windowViewModel.consumeFolderImportRequest() else { return }

		switch result {
		case .success(let urls):
			switch request {
			case .openRepository:
				viewModel.didChooseRepositories(
					urls,
					actions: .init(didOpenRepository: showRepository)
				)
			case .clone(let remoteURL):
				guard let url = urls.first else { return }
				viewModel.didRequestCloneRepository(
					from: remoteURL,
					into: url,
					actions: .init(didOpenRepository: showRepository)
				)
			}
		case .failure(let error):
			guard isUserCancellation(error) == false else { return }
			viewModel.alertMessage = error.localizedDescription
		}
	}

	private func isUserCancellation(_ error: any Error) -> Bool {
		let error = error as NSError
		return error.domain == NSCocoaErrorDomain && error.code == NSUserCancelledError
	}

	private var repositoryTab: RepositoryTab? {
		viewModel.tab(id: repositoryID)
	}

	private var folderImporterPresentation: Binding<Bool> {
		Binding(
			get: { windowViewModel.isFolderImporterPresented },
			set: { isPresented in
				if !isPresented {
					windowViewModel.didDismissFolderImporter()
				}
			}
		)
	}

	private func restoreRepositoryWindows() {
		guard let coordinator else { return }
		guard
			let restoration = viewModel.requestWindowRestoration(
				currentRepositoryID: repositoryID
			)
		else {
			activateRepository(repositoryID)
			return
		}

		repositoryID = restoration.primaryRepositoryID
		activateRepository(repositoryID)
		coordinator.restoreRepositoryWindows(restoration)
	}

	private func activateRepository(_ id: RepositoryTab.ID?) {
		Task { @MainActor in
			await Task.yield()
			guard repositoryID == id else { return }
			guard let id, viewModel.tab(id: id) != nil else {
				windowViewModel.selectSidebarItem(nil)
				return
			}

			viewModel.didPrepareTab(id)
			if windowViewModel.sidebarSelection?.repositoryID != id {
				windowViewModel.selectSidebarItem(
					viewModel.defaultSidebarSelection(repositoryID: id)
				)
			}
		}
	}

	private func activateSidebarSelection(_ selection: RepositorySidebarSelection?) {
		guard let selection else { return }
		viewModel.didActivateSidebarSelection(selection)
		if selection.repositoryID != repositoryID {
			openRepository(selection.repositoryID)
		}
	}

	private func openRepository(_ id: RepositoryTab.ID) {
		guard id != repositoryID else {
			activateRepository(id)
			return
		}
		coordinator?.openNewTab(repositoryID: id, from: nil)
	}

	private func showRepository(_ id: RepositoryTab.ID) {
		guard coordinator?.focusRepositoryIfOpen(id) != true else { return }
		if repositoryID == nil {
			repositoryID = id
		} else {
			openRepository(id)
		}
	}

}

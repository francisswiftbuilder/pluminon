import DomainGitInterface
import SwiftUI

struct RepositoryWelcomeContainerView: View {
	enum Source: Hashable {
		case local, remote
	}

	let source: Source
	let accountViewModel: GitAccountViewModel
	let repositories: [SavedRepository]
	let isWorking: Bool
	let onOpenRepository: () -> Void
	let onOpenSavedRepository: (UUID) -> Void
	let onCloneRepository: (String) -> Void
	let onCancel: () -> Void

	@State private var localSelection: UUID?

	var body: some View {
		switch source {
		case .local:
			localRepositories
		case .remote:
			RepositoryGitHubBrowserView(
				accountViewModel: accountViewModel, isWorking: isWorking,
				onOpenRepository: onOpenRepository, onClone: onCloneRepository,
				onCancel: onCancel)
		}
	}

	private var localRepositories: some View {
		Group {
			if repositories.isEmpty {
				ContentUnavailableView(
					"No Local Repositories", systemImage: "folder",
					description: Text("Open an existing repository or clone a remote repository."))
			} else {
				List(repositories, selection: $localSelection) { repository in
					VStack(alignment: .leading, spacing: 3) {
						Text(repository.name).font(.headline)
						Text(repository.url.path)
							.font(.caption).foregroundStyle(.secondary)
							.lineLimit(1).truncationMode(.middle)
					}
					.padding(.vertical, 4)
					.tag(repository.id)
				}
				.contextMenu(forSelectionType: UUID.self) { ids in
					if let id = ids.first, ids.count == 1 {
						Button("Open") { openSavedRepository(id) }.disabled(isWorking)
					}
				} primaryAction: { ids in
					if let id = ids.first, ids.count == 1 { openSavedRepository(id) }
				}
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.safeAreaInset(edge: .bottom, spacing: 0) {
			VStack(spacing: 0) {
				Divider()
				HStack {
					Button("Open Local…", action: onOpenRepository)
						.keyboardShortcut("o", modifiers: .command)
						.disabled(isWorking)
					Spacer()
					if isWorking {
						ProgressView().controlSize(.small)
						Button("Cancel", action: onCancel).keyboardShortcut(.cancelAction)
					} else {
						Button("Open") {
							if let localSelection { openSavedRepository(localSelection) }
						}
						.keyboardShortcut(.defaultAction)
						.disabled(localSelection == nil)
					}
				}
				.padding(12)
			}
			.background(.bar)
		}
	}

	private func openSavedRepository(_ id: UUID) {
		guard !isWorking, repositories.contains(where: { $0.id == id }) else { return }
		onOpenSavedRepository(id)
	}
}

import Foundation

final class GitLFSExecutableScope: Sendable {
	static let installationURLs = [
		URL(filePath: "/opt/homebrew/bin/git-lfs"),
		URL(filePath: "/usr/local/bin/git-lfs"),
	]

	let directoryURL: URL

	init?(executableURLs: [URL]) throws {
		let fileManager = FileManager.default
		guard
			let executableURL = executableURLs.first(where: { url in
				guard fileManager.isExecutableFile(atPath: url.path) else { return false }
				let resourceValues = try? url.resolvingSymlinksInPath().resourceValues(forKeys: [
					.isRegularFileKey
				])
				return resourceValues?.isRegularFile == true
			})
		else { return nil }

		let directoryURL = fileManager.temporaryDirectory
			.appending(path: "PluminonGitLFS-\(UUID().uuidString)", directoryHint: .isDirectory)
		try fileManager.createDirectory(
			at: directoryURL, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
		do {
			try fileManager.createSymbolicLink(
				at: directoryURL.appending(path: "git-lfs"), withDestinationURL: executableURL)
		} catch {
			try? fileManager.removeItem(at: directoryURL)
			throw error
		}
		self.directoryURL = directoryURL
	}

	deinit {
		try? FileManager.default.removeItem(at: directoryURL)
	}
}

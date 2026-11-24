import Foundation

final class GitLFSExecutableScope: Sendable {
	static let installationURLs = [
		URL(filePath: "/opt/homebrew/bin/git-lfs"),
		URL(filePath: "/usr/local/bin/git-lfs"),
	]

	let directoryURL: URL
	let configurationURL: URL
	let hasExecutable: Bool

	init(executableURLs: [URL]) throws {
		let fileManager = FileManager.default
		let executableURL = executableURLs.first { url in
			guard fileManager.isExecutableFile(atPath: url.path) else { return false }
			let resourceValues = try? url.resolvingSymlinksInPath().resourceValues(forKeys: [
				.isRegularFileKey
			])
			return resourceValues?.isRegularFile == true
		}
		let directoryURL = fileManager.temporaryDirectory
			.appending(path: "PluminonGitLFS-\(UUID().uuidString)", directoryHint: .isDirectory)
		let configurationURL = directoryURL.appending(path: "config")
		try fileManager.createDirectory(
			at: directoryURL, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
		do {
			try """
			[filter "lfs"]
				process = git-lfs filter-process
				clean = git-lfs clean -- %f
				smudge = git-lfs smudge -- %f
				required = true

			""".write(to: configurationURL, atomically: true, encoding: .utf8)
			if let executableURL {
				try fileManager.createSymbolicLink(
					at: directoryURL.appending(path: "git-lfs"), withDestinationURL: executableURL)
			}
		} catch {
			try? fileManager.removeItem(at: directoryURL)
			throw error
		}
		self.directoryURL = directoryURL
		self.configurationURL = configurationURL
		hasExecutable = executableURL != nil
	}

	deinit {
		try? FileManager.default.removeItem(at: directoryURL)
	}
}

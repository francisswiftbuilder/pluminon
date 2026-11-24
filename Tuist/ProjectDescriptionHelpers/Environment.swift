import EnvironmentPlugin

nonisolated(unsafe) public let environment = ProjectEnvironment(
	name: "Pluminon",
	organizationName: "io.github.francisswiftbuilder.pluminon",
	destinations: [.mac],
	deploymentTargets: .macOS("26.0"),
	baseSetting: baseSettings
)

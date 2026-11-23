actor GitPreparedReferenceValidationState {
	private var error: (any Error)?

	func record(_ error: any Error) {
		self.error = error
	}

	func failure() -> (any Error)? {
		error
	}
}

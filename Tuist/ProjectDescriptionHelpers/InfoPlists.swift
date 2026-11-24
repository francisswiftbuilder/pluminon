import ProjectDescription

extension InfoPlist: InfoPlists {
	public static var appInfoPlist: InfoPlist {
		.extendingDefault(
			with: [
				"CFBundleDisplayName": "$(PLUMINON_DISPLAY_NAME)",
				"PluminonDataNamespace": "$(PLUMINON_DATA_NAMESPACE)",
				"PluminonCredentialNamespace": "$(PLUMINON_CREDENTIAL_NAMESPACE)",
				"LSApplicationCategoryType": "public.app-category.developer-tools",
			]
		)
	}
}

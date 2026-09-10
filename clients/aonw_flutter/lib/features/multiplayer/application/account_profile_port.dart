final class AccountProfileView {
  const AccountProfileView({required this.userId, required this.displayName});

  final String userId;
  final String displayName;
}

/// Own-account details; changing the name preserves the account identity.
abstract interface class AccountProfilePort {
  Future<AccountProfileView> readProfile();
  Future<AccountProfileView> updateDisplayName(String displayName);
}

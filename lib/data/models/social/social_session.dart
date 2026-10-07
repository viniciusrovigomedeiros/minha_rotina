enum SocialAuthProvider { apple, google }

class SocialSession {
  const SocialSession({
    required this.isConfigured,
    required this.isAuthenticated,
    this.profileId,
    this.displayName,
    this.email,
  });

  final bool isConfigured;
  final bool isAuthenticated;
  final String? profileId;
  final String? displayName;
  final String? email;

  static const unconfigured = SocialSession(
    isConfigured: false,
    isAuthenticated: false,
  );

  static const signedOut = SocialSession(
    isConfigured: true,
    isAuthenticated: false,
  );
}

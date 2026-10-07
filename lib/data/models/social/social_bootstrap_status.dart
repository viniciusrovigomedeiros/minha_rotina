enum SocialBackendStage { unconfigured, configuredNoSession, ready }

class SocialBootstrapStatus {
  const SocialBootstrapStatus({
    required this.stage,
    required this.isConfigured,
    required this.hasSession,
    required this.missingKeys,
    required this.summary,
  });

  final SocialBackendStage stage;
  final bool isConfigured;
  final bool hasSession;
  final List<String> missingKeys;
  final String summary;
}

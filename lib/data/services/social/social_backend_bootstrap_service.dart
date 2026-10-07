import '../../../core/constants/social_backend_config.dart';
import '../../models/social/social_bootstrap_status.dart';

class SocialBackendBootstrapService {
  SocialBackendBootstrapService({
    SocialBackendConfig config = SocialBackendConfig.current,
  }) : _config = config;

  final SocialBackendConfig _config;

  SocialBackendConfig get config => _config;

  Future<SocialBootstrapStatus> inspect({required bool hasSession}) async {
    if (!_config.isConfigured) {
      return SocialBootstrapStatus(
        stage: SocialBackendStage.unconfigured,
        isConfigured: false,
        hasSession: false,
        missingKeys: _config.missingKeys,
        summary:
            'Configure o projeto Supabase via dart-define antes de ativar o modo social.',
      );
    }

    if (!hasSession) {
      return const SocialBootstrapStatus(
        stage: SocialBackendStage.configuredNoSession,
        isConfigured: true,
        hasSession: false,
        missingKeys: [],
        summary:
            'Backend configurado. Falta conectar login social e sessao do usuario.',
      );
    }

    return const SocialBootstrapStatus(
      stage: SocialBackendStage.ready,
      isConfigured: true,
      hasSession: true,
      missingKeys: [],
      summary: 'Social pronto para uso.',
    );
  }
}

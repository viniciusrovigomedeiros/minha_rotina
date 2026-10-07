# Data Model

## Convenções

- IDs em `uuid`
- datas em `timestamptz`
- soft delete apenas onde fizer sentido
- todo registro social relevante tem `created_at` e `updated_at`

## Tabelas principais

### `profiles`

Representa o perfil social do usuário autenticado.

- `id`
- `auth_user_id`
- `display_name`
- `avatar_url`
- `username`
- `push_opt_in`
- `created_at`
- `updated_at`

### `device_tokens`

Tokens de push por dispositivo.

- `id`
- `profile_id`
- `platform`
- `fcm_token`
- `last_seen_at`
- `created_at`
- `updated_at`

### `social_invites`

Convites para amizade, grupo ou desafio.

- `id`
- `created_by_profile_id`
- `invite_type`
- `target_type`
- `target_id`
- `token`
- `status`
- `expires_at`
- `accepted_by_profile_id`
- `accepted_at`
- `created_at`
- `updated_at`

### `social_groups`

Grupo fixo ou semi-fixo de accountability.

- `id`
- `name`
- `description`
- `group_type`
- `owner_profile_id`
- `visibility`
- `status`
- `created_at`
- `updated_at`

### `social_group_members`

Participantes do grupo.

- `id`
- `group_id`
- `profile_id`
- `role`
- `joined_at`
- `status`
- `created_at`
- `updated_at`

### `challenges`

Entidade base para desafio ou missão.

- `id`
- `group_id` nullable
- `created_by_profile_id`
- `challenge_type`
- `title`
- `description`
- `scoring_type`
- `start_at`
- `end_at`
- `status`
- `consequence_type` nullable
- `consequence_text` nullable
- `created_at`
- `updated_at`

### `challenge_members`

Participantes do desafio.

- `id`
- `challenge_id`
- `profile_id`
- `role`
- `joined_at`
- `status`
- `created_at`
- `updated_at`

### `shared_objectives`

Objetivo compartilhado social.

- `id`
- `challenge_id`
- `title`
- `description`
- `objective_mode`
- `start_at`
- `end_at`
- `status`
- `created_at`
- `updated_at`

### `shared_key_results`

KRs de um objetivo social.

- `id`
- `shared_objective_id`
- `title`
- `measurement_type`
- `initial_value`
- `target_value`
- `unit`
- `weight`
- `ownership_mode`
- `owner_profile_id` nullable
- `created_at`
- `updated_at`

### `member_goal_links`

Vínculo entre o objetivo/KR social e o dado local do usuário.

- `id`
- `profile_id`
- `challenge_id`
- `shared_objective_id` nullable
- `shared_key_result_id` nullable
- `local_objective_id` nullable
- `local_key_result_id` nullable
- `sync_mode`
- `created_at`
- `updated_at`

### `social_check_ins`

Check-ins sociais.

- `id`
- `challenge_id`
- `profile_id`
- `shared_objective_id` nullable
- `shared_key_result_id` nullable
- `check_in_type`
- `value_numeric` nullable
- `status_label` nullable
- `advance_note` nullable
- `blocker_note` nullable
- `next_focus_note` nullable
- `source_type`
- `source_local_event_id` nullable
- `created_at`
- `updated_at`

### `execution_proofs`

Anexos e provas.

- `id`
- `profile_id`
- `challenge_id`
- `social_check_in_id` nullable
- `proof_type`
- `storage_bucket`
- `storage_path`
- `mime_type`
- `size_bytes`
- `caption` nullable
- `created_at`
- `updated_at`

### `challenge_scores`

Tabela materializada ou mantida por job.

- `id`
- `challenge_id`
- `profile_id`
- `score_total`
- `consistency_score`
- `completion_score`
- `check_in_score`
- `current_streak`
- `rank_position`
- `last_calculated_at`
- `created_at`
- `updated_at`

### `buddy_rules`

Regras de cobrança entre duas pessoas.

- `id`
- `owner_profile_id`
- `buddy_profile_id`
- `group_id` nullable
- `challenge_id` nullable
- `days_without_check_in_threshold`
- `weekly_risk_enabled`
- `streak_break_enabled`
- `status`
- `created_at`
- `updated_at`

### `notifications`

Registro de notificações emitidas.

- `id`
- `profile_id`
- `notification_type`
- `title`
- `body`
- `target_type`
- `target_id`
- `aggregation_key` nullable
- `sent_at` nullable
- `read_at` nullable
- `status`
- `created_at`
- `updated_at`

## Enums sugeridos

### `challenge_type`

- `cycle_duel`
- `weekly_short`
- `shared_mission`
- `shared_objective`
- `consistency_league`

### `scoring_type`

- `percentage_progress`
- `completion_count`
- `consistency_score`
- `shared_okr_progress`

### `objective_mode`

- `parallel_individual`
- `shared_goal_split_krs`

### `ownership_mode`

- `individual`
- `shared_visible_single_owner`

### `check_in_type`

- `weekly_reflection`
- `kr_update`
- `activity_completion`
- `manual_progress`

### `source_type`

- `manual`
- `local_sync`
- `system_generated`

## Regras de modelagem

### Desafio 1:1 por ciclo

- 1 registro em `challenges`
- 2 registros em `challenge_members`
- opcionalmente 2 `member_goal_links` para KRs equivalentes

### Missão em comum

- 1 `challenge`
- N `challenge_members`
- cada membro com sua própria ligação em `member_goal_links`

### Objetivo compartilhado com KRs divididos

- 1 `shared_objective`
- N `shared_key_results`
- cada KR pode ter `owner_profile_id`

### Liga de consistência

- usa `challenge_scores`
- score é calculado no servidor e persistido

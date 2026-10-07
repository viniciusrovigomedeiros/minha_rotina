# API And Events

## Abordagem

Para o MVP, preferir:

- `Supabase RPC` para consultas mais estruturadas
- `Edge Functions` para operações com regra de negócio
- acesso direto por SDK apenas em leituras e escritas simples com RLS

## Endpoints lógicos

### Auth

- `POST /auth/sign-in/apple`
- `POST /auth/sign-in/google`
- `POST /auth/sign-out`

### Perfil

- `GET /me/profile`
- `PATCH /me/profile`
- `POST /me/device-token`

### Convites

- `POST /invites`
- `GET /invites/:token`
- `POST /invites/:token/accept`
- `POST /invites/:id/revoke`

### Grupos

- `POST /groups`
- `GET /groups`
- `GET /groups/:id`
- `POST /groups/:id/join`
- `POST /groups/:id/leave`
- `POST /groups/:id/invite`

### Desafios

- `POST /challenges`
- `GET /challenges`
- `GET /challenges/:id`
- `POST /challenges/:id/join`
- `POST /challenges/:id/leave`
- `POST /challenges/:id/close`

A criacao usa a RPC `create_social_challenge(p_title, p_challenge_type,
p_description)` e retorna o UUID do desafio. O banco identifica o perfil pela
sessao, calcula prazo e pontuacao pelo formato e cria o desafio, o membro dono
e o objetivo compartilhado (quando aplicavel) na mesma transacao.

As funcoes auxiliares de perfil e participacao executam com `SECURITY DEFINER`
e `search_path` vazio para evitar recursao das politicas RLS. Elas retornam
somente o perfil ou a participacao do usuario autenticado.

Teste de regressao do banco, apos aplicar as migrations:

```sh
psql "$SOCIAL_TEST_DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/social_challenge_creation.sql
```

O teste roda em transacao revertida e cobre todos os formatos, isolamento entre
usuarios, convite, validacao e rollback se a criacao do objetivo falhar.

### Objetivos/KRs compartilhados

- `POST /shared-objectives`
- `GET /shared-objectives/:id`
- `POST /shared-key-results`
- `PATCH /shared-key-results/:id`

### Vínculos com dados locais

- `POST /member-goal-links`
- `PATCH /member-goal-links/:id`
- `DELETE /member-goal-links/:id`

### Check-ins

- `POST /social-check-ins`
- `GET /challenges/:id/check-ins`
- `GET /groups/:id/check-ins`

### Provas

- `POST /execution-proofs/upload-url`
- `POST /execution-proofs`
- `GET /social-check-ins/:id/proofs`

### Ranking

- `GET /challenges/:id/leaderboard`
- `GET /challenges/:id/summary`

### Buddy rules

- `POST /buddy-rules`
- `PATCH /buddy-rules/:id`
- `DELETE /buddy-rules/:id`

## Payloads mínimos

### Criar desafio semanal

```json
{
  "challengeType": "weekly_short",
  "title": "5 treinos na semana",
  "description": "De segunda a domingo, sem desculpa.",
  "scoringType": "completion_count",
  "startAt": "2026-08-24T00:00:00Z",
  "endAt": "2026-08-31T00:00:00Z",
  "participants": ["profile_a", "profile_b"]
}
```

### Check-in compartilhado

```json
{
  "challengeId": "uuid",
  "checkInType": "weekly_reflection",
  "advanceNote": "Cumpri 4 de 5 treinos.",
  "blockerNote": "Perdi um dia por viagem.",
  "nextFocusNote": "Treinar cedo na quarta e sexta."
}
```

### Prova de execução

```json
{
  "challengeId": "uuid",
  "socialCheckInId": "uuid",
  "proofType": "image",
  "storageBucket": "social-proofs",
  "storagePath": "proofs/user_x/file.jpg",
  "mimeType": "image/jpeg",
  "caption": "Treino finalizado."
}
```

## Eventos de domínio

### Eventos de criação

- `challenge.created`
- `challenge.joined`
- `group.created`
- `invite.accepted`

### Eventos de progresso

- `check_in.created`
- `proof.attached`
- `kr.progress_updated`
- `leaderboard.updated`

### Eventos de alerta

- `buddy.threshold_reached`
- `weekly_summary.ready`
- `streak.at_risk`

## Regras de push

### Push imediato

- convite recebido
- convite aceito
- desafio iniciado
- buddy alert

### Push agregado

- check-ins de grupo
- provas novas
- fechamento semanal

## Regras de agregação

- janela padrão de agregação: `15 minutos`
- chave de agregação:
  - `group:{id}:checkins`
  - `challenge:{id}:proofs`
  - `challenge:{id}:weekly-summary`

## Regras de consistência

O ranking do tipo `liga de consistência` deve usar fórmula configurável, começando por:

- `40%` taxa de conclusão
- `30%` sequência
- `20%` check-ins em dia
- `10%` presença semanal

Essa fórmula deve ficar encapsulada no backend para poder mudar sem update do app.

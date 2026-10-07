# Delivery Plan

## Estratégia

Entregar em camadas, sem tentar resolver tudo em uma vez.

## Fase 0

Objetivo: preparar base técnica.

- adicionar dependências de `Supabase` e `Firebase Messaging`
- definir variáveis de ambiente
- criar projeto Supabase
- configurar projeto Firebase
- configurar autenticação Apple e Google
- criar estrutura de pastas `social`

## Fase 1

Objetivo: habilitar identidade e infraestrutura mínima.

- login social
- `profiles`
- `device_tokens`
- cadastro e refresh de token de push
- tela de entrada no modo social

## Fase 2

Objetivo: habilitar desafio `1:1` e desafio semanal.

- `social_invites`
- `challenges`
- `challenge_members`
- criação e aceite de convite
- listagem de desafios
- leaderboard básico

## Fase 3

Objetivo: habilitar check-in compartilhado.

- `social_check_ins`
- composer de check-in semanal
- timeline simples por desafio
- push agregada de check-ins

## Fase 4

Objetivo: habilitar missão em comum e liga de consistência.

- `social_groups`
- `social_group_members`
- modo `shared_mission`
- `challenge_scores`
- cálculo server-side de score

## Fase 5

Objetivo: habilitar objetivo compartilhado com KR distribuído.

- `shared_objectives`
- `shared_key_results`
- `member_goal_links`
- UI para atribuição de KR por membro
- sync local -> social controlada

## Fase 6

Objetivo: habilitar prova de execução e buddy.

- `execution_proofs`
- upload para storage
- `buddy_rules`
- jobs/Edge Functions de alerta

## Ordem recomendada de implementação no app

### Backend primeiro

- schema
- RLS
- functions
- notificações

### Flutter depois

- auth social
- repositórios sociais
- controladores sociais
- telas

## Definition of done do MVP

- usuário entra com Apple ou Google
- consegue criar desafio 1:1
- convidado aceita por link
- ambos registram check-in
- leaderboard atualiza
- grupo semanal funciona
- push de agregação funciona

## Riscos

### Risco 1

Sincronização excessiva entre OKR local e social.

Mitigação:

- sincronizar apenas entidades explicitamente vinculadas

### Risco 2

Spam de notificação.

Mitigação:

- agregação server-side obrigatória

### Risco 3

Modelagem muito ampla no início.

Mitigação:

- MVP apenas com:
  - auth
  - convite
  - desafio 1:1
  - desafio semanal
  - check-in
  - leaderboard

## Próximo passo após aprovação desta spec

1. Criar migrations SQL do Supabase
2. Criar estrutura Flutter de `social`
3. Implementar login social
4. Implementar convite e desafio 1:1

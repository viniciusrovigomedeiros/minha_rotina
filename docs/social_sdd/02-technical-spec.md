# Technical Spec

## Arquitetura alvo

O app passa a operar em dois modos de persistência:

- `solo/local`: Hive continua sendo a fonte de verdade do uso individual
- `social/server-backed`: Supabase passa a ser a fonte de verdade dos recursos colaborativos

## Stack proposta

### Backend

- `Supabase Auth`
- `Supabase Postgres`
- `Supabase Realtime`
- `Supabase Storage`
- `Supabase Edge Functions`

### Push

- `Firebase Cloud Messaging`

### Flutter

- `supabase_flutter`
- `firebase_core`
- `firebase_messaging`

## Motivos da escolha

- modelo social é relacional
- desafios, membros, rankings e check-ins cabem melhor em Postgres
- Supabase reduz trabalho de backend no MVP
- FCM resolve push de forma barata e madura

## Estratégia de identidade

- conta é obrigatória apenas no social
- usuário anônimo no modo solo não precisa migrar todos os dados para o servidor
- ao conectar uma entidade local ao social, o app cria um vínculo explícito

## Modelo de sincronização

### Princípio

Não sincronizar automaticamente todo o banco local do usuário.

Sincronizar apenas o que entrar no contexto social:

- desafio
- grupo
- objetivo compartilhado
- KR compartilhado
- check-in social
- prova de execução social

### Fluxo

1. usuário cria ou entra em uma entidade social
2. app associa uma entidade local a uma entidade remota
3. mudanças relevantes geram eventos para o backend
4. backend recalcula score, status e notificações
5. app recebe atualização via fetch ou realtime

## Integração com o modelo atual do app

### Mantido

- `Hive` para dados locais
- `Riverpod`
- estrutura atual de `models`, `repositories`, `services`, `state`, `features`

### Novo módulo sugerido

```text
lib/
  data/
    models/social/
    repositories/social/
    services/social/
  state/social/
  features/social/
```

## Estratégia de backend

### Fonte de verdade

- dados sociais ficam no backend
- rankings e regras derivadas não são calculados apenas no cliente

### Cálculo server-side

Devem ser calculados no backend:

- score de consistência
- posição em ranking
- streak social
- alertas de buddy
- agregação de notificações
- estado consolidado do grupo

## Autorização

Usar `Row Level Security` no Supabase.

Regra geral:

- usuário só lê desafios dos quais participa
- usuário só escreve nos seus próprios check-ins e provas
- admins/donos do grupo podem encerrar desafio, remover membro e editar regras

## Upload de prova

- arquivo sobe para `Supabase Storage`
- banco guarda apenas:
  - `bucket`
  - `path`
  - `mime_type`
  - `size_bytes`
  - `owner_user_id`
- push nunca inclui imagem

## Realtime

Usar realtime apenas para:

- placar do desafio
- novo check-in do grupo
- mudança de status relevante

Não usar realtime para tudo.

## Notificações

### Estratégia

- eventos relevantes entram numa fila lógica
- Edge Function agrega eventos por grupo e janela curta
- dispara uma única push por contexto

### Exemplos

- `3 pessoas atualizaram o desafio da semana`
- `Seu buddy está há 3 dias sem check-in`
- `Você perdeu a liderança no desafio`

## Observabilidade mínima

- logs de criação e aceite de convite
- logs de criação e encerramento de desafio
- logs de falha em envio de push
- logs de erro em upload de prova

## Limitações aceitas no MVP

- sem sincronização offline sofisticada para o social
- sem resolução complexa de conflitos
- sem comentários em thread
- sem analytics avançado

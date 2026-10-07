# SDD Social

## Objetivo

Este pacote de especificações define a implementação da camada social do app `Minha Rotina`, mantendo o produto atual como `local-first` para uso individual e adicionando recursos colaborativos suportados por backend.

## Decisão principal

- O app continua funcionando sem conta para uso solo.
- A camada social exige login.
- O backend recomendado para o MVP é:
  - `Supabase Auth`
  - `Supabase Postgres`
  - `Supabase Realtime`
  - `Supabase Storage`
  - `Supabase Edge Functions`
  - `Firebase Cloud Messaging (FCM)` para push

## Escopo inicial

Este SDD cobre:

- desafios `1:1 por ciclo`
- desafios `semanais curtos`
- `missão em comum`
- `objetivo compartilhado de grupo` com KRs distribuídos por pessoa
- `liga de consistência`
- `check-in compartilhado`
- `prova de execução`
- `parceiro de cobrança`

## Documentos

- [01-product-spec.md](/Users/viniciusrovigomedeiros/Documents/dev/projetos/minha_rotina/docs/social_sdd/01-product-spec.md)
- [02-technical-spec.md](/Users/viniciusrovigomedeiros/Documents/dev/projetos/minha_rotina/docs/social_sdd/02-technical-spec.md)
- [03-data-model.md](/Users/viniciusrovigomedeiros/Documents/dev/projetos/minha_rotina/docs/social_sdd/03-data-model.md)
- [04-api-and-events.md](/Users/viniciusrovigomedeiros/Documents/dev/projetos/minha_rotina/docs/social_sdd/04-api-and-events.md)
- [05-delivery-plan.md](/Users/viniciusrovigomedeiros/Documents/dev/projetos/minha_rotina/docs/social_sdd/05-delivery-plan.md)

## Estado

- Status: `draft pronto para implementação`
- Data base: `2026-08-23`

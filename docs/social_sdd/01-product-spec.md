# Product Spec

## Visão

Adicionar uma camada social orientada a execução, responsabilidade e consistência, sem transformar o app em rede social genérica.

O foco é:

- dar visibilidade para progresso compartilhado
- criar cobrança saudável entre pessoas
- permitir objetivos e desafios em comum
- manter o OKR como estrutura central do produto

## Princípios

- `execution-first`: interação social só existe para reforçar execução
- `small groups`: nada de feed aberto ou descoberta pública
- `low-noise`: notificações agregadas e poucas superfícies
- `privacy by default`: o usuário escolhe o que entra no social
- `local-first solo`: o modo individual continua independente

## Problemas que a feature resolve

- falta de accountability externa
- perda de consistência entre check-ins
- abandono de metas por ausência de pressão social
- dificuldade de coordenar metas em grupo

## Personas

### Usuário solo que quer accountability

- usa o app sozinho
- aceita criar conta apenas ao entrar no social
- quer desafiar um amigo ou ter parceiro de cobrança

### Grupo pequeno com meta em comum

- casal, amigos, time pequeno
- quer um objetivo compartilhado
- precisa dividir responsabilidade por KR

### Usuário competitivo por consistência

- prefere ranking simples
- gosta de sequência, taxa de conclusão e check-in no prazo
- não quer ser comparado por volume bruto

## Modos de interação

### 1. Desafio 1:1 por ciclo

- um usuário desafia outro para um ciclo específico
- cada um tem seu próprio KR equivalente
- o app compara:
  - progresso percentual
  - sequência
  - check-ins em dia

### 2. Desafio semanal curto

- desafio com início e fim dentro de uma semana
- exemplos:
  - `5 treinos`
  - `7 dias sem faltar`
  - `3 check-ins`
- placar simples

### 3. Missão em comum

- grupo entra no mesmo tema de objetivo
- cada participante tem seu próprio KR
- a visualização mostra:
  - status individual
  - status agregado do grupo

### 4. Objetivo compartilhado com KRs distribuídos

- o objetivo é do grupo
- os KRs são parte do objetivo de todos
- cada KR tem um responsável principal
- todos podem ver o status, mas a responsabilidade operacional é individual

### 5. Liga de consistência

- ranking calculado por consistência
- não compara volume absoluto
- score considera:
  - dias com execução
  - sequência atual
  - frequência de check-in
  - taxa de conclusão

### 6. Check-in compartilhado

- no fechamento semanal, cada membro registra:
  - `avancei`
  - `travei`
  - `foco da próxima semana`
- o grupo recebe uma única notificação agregada

### 7. Prova de execução

- ao concluir atividade ou check-in relevante, o usuário pode anexar:
  - foto
  - print
  - nota curta
- push não carrega imagem
- push informa apenas que houve atualização

### 8. Parceiro de cobrança

- usuário define um buddy
- buddy é avisado quando:
  - usuário fica X dias sem check-in
  - meta semanal está em risco
  - sequência está perto de quebrar

## Requisitos funcionais

### Conta e acesso

- usuário pode usar o app sem login no modo solo
- usuário precisa criar conta para usar qualquer recurso social
- login mínimo no MVP:
  - `Sign in with Apple`
  - `Google`

### Convites

- usuário pode convidar outra pessoa por link
- usuário pode criar grupo por link ou convite direto
- convites têm expiração e podem ser revogados

### Desafios e grupos

- criar desafio
- entrar em desafio
- sair de desafio
- encerrar desafio
- visualizar placar
- visualizar histórico resumido

### Check-ins

- registrar check-in manual
- sincronizar check-in derivado do OKR local
- anexar nota
- anexar prova opcional

### Notificações

- notificação de convite
- notificação de novo check-in no grupo
- notificação agregada semanal
- notificação de buddy alert
- notificação de mudança de liderança

## Requisitos não funcionais

- suporte inicial para poucas dezenas ou centenas de usuários
- custo próximo de zero no MVP
- latência aceitável para atualizações de ranking e grupo
- regras de acesso estritas
- logs mínimos de auditoria em ações sociais críticas

## Fora do escopo do MVP

- feed público
- busca de usuários aberta
- likes, comentários livres e reações
- chat em tempo real
- comunidades grandes
- marketplace de desafios

## Critérios de sucesso do MVP

- usuário consegue criar conta e convidar outra pessoa
- desafio semanal e desafio 1:1 funcionam do início ao fim
- grupo consegue registrar check-ins e ver ranking
- notificações chegam sem spam
- buddy alert funciona com regra mínima de atraso

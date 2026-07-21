# Plano de Reestruturação para OKR

## Contexto atual analisado

O projeto atual já possui uma base compatível com uma reestruturação direta:

- Arquitetura em camadas simples com `models`, `repositories`, `services`, `state` e `features`.
- Persistência local em Hive via `LocalStorageService`.
- Gerenciamento de estado com Riverpod.
- Estrutura de atividades reutilizável para representar iniciativas.
- Estrutura de atividades reutilizável para iniciativas e tarefas independentes.

## Partes reutilizáveis

### Persistência

- `LocalStorageService`: manter como ponto central de abertura das boxes Hive.
- Repositórios atuais: seguir o mesmo padrão para novos repositórios de OKR.
- `metadata_box`: reutilizar para bootstrap e controle de reset inicial.

### Modelos

- `Activity`: reutilizar como base para iniciativas, adicionando vínculos opcionais com objetivo e resultado-chave.
- `Category`: manter como categoria/área da vida.
- `WeeklyGoal`: passa a ser somente dado obsoleto, fora do fluxo principal.

### Estado

- Padrão atual de `AsyncNotifierProvider` será mantido para ciclos, objetivos e home.

### Interface

- `MainShell`: reutilizar a navegação principal.
- Componentes visuais atuais (`Card`, chips, formulários, estados vazios): reaproveitar nas novas telas.
- Tela de atividades: manter e adaptar a terminologia para iniciativas/tarefas.

## Partes que precisam ser alteradas

### Novos modelos

- `OkrCycle`
- `OkrObjective`
- `KeyResult`
- `KeyResultCheckIn`
- Estruturas derivadas para progresso e visão consolidada

### Persistência

- Novas boxes Hive para ciclos, objetivos, resultados-chave e check-ins.
- Reset inicial dos dados antigos para começar o aplicativo já no modo OKR.

### Estado e regras

- Cálculo de progresso do resultado-chave por tipo de medição.
- Cálculo de progresso do objetivo por média simples ou ponderada.
- Cálculo de progresso geral do ciclo.
- Seleção do ciclo atual.

### Telas e fluxos

- Tela inicial com foco em OKR.
- Lista de objetivos.
- Detalhe do objetivo.
- Formulário simples de criação de OKR.
- Tela de visão de ciclos.
- Ajuste da tela de atividades para mostrar vínculos com OKRs.

## Estratégia de dados

- Como o aplicativo ainda não está em uso, os dados antigos podem ser descartados.
- O bootstrap faz um reset único dos boxes antigos e inicia o app já limpo.
- Após o reset, o app cria automaticamente os ciclos trimestrais do ano atual.
- A partir daí, apenas a estrutura nova de OKR permanece ativa.

## Etapas de implementação

### Etapa 1

- Adicionar modelos, enums e utilitários de cálculo de OKR.
- Adicionar novas boxes e repositórios.
- Implementar bootstrap de fresh start com flag em `metadata`.

### Etapa 2

- Criar controladores de ciclos, objetivos e home.
- Expor visões derivadas com progresso calculado.

### Etapa 3

- Adaptar `Activity` para suportar vínculo opcional com objetivo e resultado-chave.
- Ajustar formulário e listagem de atividades para a terminologia de iniciativas.

### Etapa 4

- Implementar home OKR com ciclo atual, objetivos ativos, resultados-chave pendentes e iniciativas da semana.
- Implementar lista de objetivos e detalhe do objetivo.
- Implementar fluxo mínimo de criação de OKR.

### Etapa 5

- Atualizar navegação principal para refletir a nova estrutura.
- Ajustar textos e estados vazios.

### Etapa 6

- Adicionar testes para:
  - progresso de resultados-chave
  - progresso de objetivos
  - seed dos ciclos trimestrais

## Escopo inicial desta entrega

Prioridade 1:

- Ciclos
- Objetivos
- Resultados-chave
- Cálculo de progresso
- Iniciativas com vínculo opcional
- Tela inicial adaptada
- Tela de detalhes do objetivo

Itens de prioridade 2 e 3 ficam preparados estruturalmente, mas não serão concluídos nesta primeira implementação, exceto o que for necessário para suportar a arquitetura.

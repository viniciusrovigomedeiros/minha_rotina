# Minha Rotina

Aplicativo Flutter para controle pessoal de atividades diárias, com foco em clareza, motivação e evolução contínua.

## Tecnologias

- Flutter
- Riverpod (estado)
- Hive (persistência local)
- `fl_chart` (gráficos da V2)
- `flutter_local_notifications` + `timezone` (lembretes locais)

## Banco Local Escolhido: Hive

Escolha para este caso por simplicidade e velocidade no uso offline para uma única pessoa, sem backend.

- Não exige estrutura SQL complexa
- Leitura/escrita rápida de objetos serializados
- Fácil para backup/restore JSON
- Menos overhead para manter V1/V2 enxutas

## Como rodar

1. Entre na pasta do projeto:

```bash
cd /Users/viniciusrovigomedeiros/Documents/dev/projetos/navalha-manager/minha_rotina
```

2. Instale dependências:

```bash
flutter pub get
```

3. Rode o app:

```bash
flutter run
```

4. Verificação de qualidade:

```bash
flutter analyze
flutter test
```

## Estrutura de pastas

```text
lib/
  app.dart
  main.dart
  core/
    constants/
    theme/
    utils/
  data/
    models/
    repositories/
    services/
  state/
  features/
    today/
    activities/
    history/
    dashboard/
    focus/
    settings/
    shared/
```

## O que foi implementado na V1

- Tela Hoje com:
  - saudação personalizada
  - frase motivacional
  - data atual
  - card de progresso diário
  - lista de atividades do dia
  - status por atividade (pendente/concluída/pulada)
  - ação rápida para concluir/pular
  - estado vazio amigável
- Cadastro de atividades:
  - criar/editar/excluir
  - nome, descrição, categoria
  - horário inicial/final
  - dias da semana
  - cor, ícone
  - ativo/inativo
  - lembretes habilitados por atividade
- Histórico diário:
  - dias anteriores
  - concluídas x planejadas
  - percentual de conclusão
  - resumo das atividades do dia
- Configurações:
  - nome do usuário
  - exportar JSON
  - importar JSON com validação básica
  - limpar dados com confirmação
- Persistência local:
  - atividades
  - logs diários
  - categorias
  - preferências

## O que foi implementado na V2

- Dashboard semanal:
  - progresso da semana
  - total concluído
  - melhor dia
  - sequência atual
- Gráficos simples:
  - conclusão por dia (últimos 7 dias)
  - concluídas por categoria
- Notificações locais:
  - agenda lembretes para atividades com horário inicial
  - respeita flag de lembrete por atividade
- Tela de foco:
  - detalhes da atividade
  - botão grande para concluir
  - botão para pular
  - mensagem motivacional
- Melhorias de UX:
  - feedback imediato via snackbars
  - navegação por abas
  - cards arredondados e paleta suave

## Exportação/Importação JSON

- Exportação:
  - escolhe uma pasta
  - gera `minha_rotina_backup_YYYYMMDD_HHMMSS.json`
- Importação:
  - seleciona um `.json`
  - valida estrutura mínima (`activities`, `dailyLogs`, `categories`, `userSettings`)
  - em erro, retorna mensagem sem quebrar o app

## Observações

- App 100% local (sem backend)
- Sem Firebase nesta versão
- Estrutura preparada para evoluções futuras

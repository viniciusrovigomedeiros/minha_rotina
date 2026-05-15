import 'dart:math';

class MotivationUtils {
  const MotivationUtils._();

  static const List<String> defaultPhrases = [
    'Stay hard.',
    'Não pare quando estiver cansado. Pare quando terminar.',
    'Quando sua mente diz que acabou, você ainda tem mais.',
    'Seja incomum entre os incomuns.',
    'A disciplina é a ponte entre quem você é e quem quer se tornar.',
    'Ninguém virá te salvar. Faça o trabalho.',
    'Treine sua mente para continuar quando for desconfortável.',
    'Sem desculpas. Sem atalhos. Só execução.',
    'A consistência diária vence qualquer explosão de motivação.',
    'A mente pede descanso cedo. O propósito pede continuidade.',
    'Você não precisa sentir vontade para agir.',
    'Faça o difícil primeiro. O resto fica leve.',
    'O desconforto é o preço da evolução.',
    'A disciplina começa quando a empolgação acaba.',
    'Resultados mudam quando o padrão sobe.',
    'A rotina forte nasce de decisões simples repetidas.',
    'Pare de negociar com a preguiça.',
    'Controle o que você faz hoje e o futuro responde.',
    'A melhor resposta é trabalho bem feito, todos os dias.',
    'Seu limite atual é só um ponto de partida.',
    'Sem drama. Sem barulho. Só progresso.',
    'Faça o básico com excelência, todos os dias.',
    'Você não precisa ser perfeito. Precisa ser constante.',
  ];

  static String greetingByTime(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  static String phraseForDay(DateTime date, {List<String>? phrases}) {
    final source =
        (phrases != null && phrases.isNotEmpty) ? phrases : defaultPhrases;
    final seed = date.day + date.month * 31 + date.year * 366;
    final random = Random(seed);
    return source[random.nextInt(source.length)];
  }

  static int indexForDay(DateTime date, {required int length}) {
    if (length <= 0) return 0;
    final seed = date.day + date.month * 31 + date.year * 366;
    final random = Random(seed);
    return random.nextInt(length);
  }
}

import 'dart:math';

class MotivationUtils {
  const MotivationUtils._();

  static const List<String> defaultPhrases = [
    'Sempre que for tomar uma decisão se pergunte, se todo mundo tomasse essa decisão o mundo seria melhor ou pior?',
    'Afinal de contas, o mundo é indiferente ao que nós, humanos, “queremos”. Se persistirmos em querer, em precisar, estaremos apenas nos condenando ao ressentimento, ou a algo ainda pior. Fazer nosso trabalho é o que basta.',
    'Mude a definição de sucesso. “O sucesso é a paz de espírito, que é um resultado direto da satisfação consigo mesmo por saber que você se esforçou para dar o seu melhor em se tornar o melhor que é capaz de ser.”',
    'Faça seu trabalho. E o faça bem. Então, “relaxe e deixe Deus agir”. Isso é tudo que é preciso.',
    '“Primeiro diga a si mesmo o que você seria; e então faça o que você tem que fazer.” – Epicteto.',
    '“Algumas coisas estão sob nosso controle, outras não.” — Epicteto',
    '“Você tem direito ao trabalho, mas não aos frutos do trabalho.” — Bhagavad Gita',
    '“O sucesso é paz de espírito, resultado direto da satisfação de saber que você fez o seu melhor.”',
    '“Se um homem é chamado para ser varredor de rua, deve varrer ruas como Michelangelo pintava.” — Martin Luther King Jr.',
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

class QuarterDateRange {
  const QuarterDateRange({required this.year, required this.quarter});

  final int year;
  final int quarter;

  DateTime get start => DateTime(year, (quarter - 1) * 3 + 1, 1);
  DateTime get end => DateTime(year, quarter * 3 + 1, 0);

  String get label =>
      const [
        '1º trimestre · jan–mar',
        '2º trimestre · abr–jun',
        '3º trimestre · jul–set',
        '4º trimestre · out–dez',
      ][quarter - 1];

  static QuarterDateRange containing(DateTime date) =>
      QuarterDateRange(year: date.year, quarter: (date.month - 1) ~/ 3 + 1);

  static List<QuarterDateRange> forYear(int year) => List.generate(
    4,
    (index) => QuarterDateRange(year: year, quarter: index + 1),
  );
}

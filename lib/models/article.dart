class Article {
  final int id;
  final String title;
  final String content;
  final DateTime date;
  final List<String> tags;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.tags,
  });

  String get formattedDate => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
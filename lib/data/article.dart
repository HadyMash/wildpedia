class Article {
  final String title;
  final DateTime dateAccessed;
  final String url;

  Article({
    required this.title,
    required this.dateAccessed,
    required this.url,
  });

  @override
  String toString() {
    return 'Article{title: $title, dateAccessed: $dateAccessed, url: $url}';
  }
}

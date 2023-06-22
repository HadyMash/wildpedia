import 'package:isar/isar.dart';

part 'article.g.dart';

// TODO: make [Article.bookmarked] non-nullable
@collection
class Article {
  Id id;
  final String title;
  @Index(name: 'dateAccessed', type: IndexType.value)
  final DateTime dateAccessed;
  final String url;
  @Index(name: 'bookmarks', type: IndexType.value)
  bool? bookmarked;

  Article({
    required this.id,
    required this.title,
    required this.dateAccessed,
    required this.url,
    this.bookmarked,
  });

  @override
  String toString() {
    return 'Article{id: $id, title: $title, dateAccessed: $dateAccessed, url: $url, bookmarked: $bookmarked}';
  }
}

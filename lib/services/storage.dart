import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildpedia/data/article.dart';

// TODO: replace factory with get instance method
class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();

  late Isar _isar;
  late List<String> _categories;

  factory LocalStorage() {
    return _instance;
  }

  LocalStorage._internal() {
    getApplicationDocumentsDirectory()
        .then((documentsDirectory) async => _isar = await Isar.open(
              [ArticleSchema],
              directory: documentsDirectory.path,
              // TODO: disable when done testing
              inspector: true,
            ));
    _getSavedCategories().then((value) => _categories = value);
    debugPrint('LocalStorage initialized');
  }

  Future<List<String>> _getSavedCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('categories') ?? [];
  }

  List<String> get categories => _categories;

  set categories(List<String> categories) {
    _categories = categories;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList('categories', categories);
    });
  }

  Future<void> addArticleToHistory(Article article) async {
    await _isar.writeTxn(() async {
      // TODO: check if article was seen before and bookmarked to avoid losing bookmarks
      await _isar.articles.put(article);
      // ! temp // TODO: remove this
      debugPrint('Added article to history: $article');
    });
  }

  Future<({List<Article> articles, bool hasNext})> paginateBookmarkedArticles(
      [DateTime? after, int limit = 20]) async {
    var articles = await _isar.articles
        .where()
        .bookmarkedEqualTo(true)
        .filter()
        .dateAccessedLessThan(after ?? DateTime.now())
        .sortByDateAccessedDesc()
        .limit(limit)
        .findAll();

    return (articles: articles, hasNext: articles.length == limit);
  }

  Future<({List<Article> articles, bool hasNext})> paginateArticles(
      [DateTime? after, int limit = 20]) async {
    var articles = await _isar.articles
        .where()
        .dateAccessedLessThan(after ?? DateTime.now())
        .sortByDateAccessedDesc()
        .limit(limit)
        .findAll();

    return (articles: articles, hasNext: articles.length == limit);
  }

  Future<List<Article>> searchArticles(String query) async {
    return await _isar.articles
        .filter()
        .titleContains(query, caseSensitive: false)
        .findAll();
  }

  Future<Article?> getArticle(Id id) async {
    return await _isar.articles.get(id);
  }

  Future<void> deleteArticle(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.articles.delete(id);
    });
  }
}

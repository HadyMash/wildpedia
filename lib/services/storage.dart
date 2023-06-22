import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildpedia/data/article.dart';

// TODO: replace factory with get instance method and await it before use to insure initialisation
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

  /// Adds [article] to the database, [existingArticle] is used to preserve
  /// the bookmarked state of the article in case the page was visited
  /// before and the user bookmarked it. If [existingArticle] is null a read
  /// transaction is used to check if the article is already in the database.
  ///
  /// * All values for [existingArticle] are ignored except for [Article.bookmarked]
  Future<void> addArticleToHistory(Article article,
      [Article? existingArticle]) async {
    await _isar.writeTxn(() async {
      existingArticle ??= await _isar.articles.get(article.id);
      article.bookmarked = existingArticle?.bookmarked;
      await _isar.articles.put(article);
    });
  }

  /// Sets [Article.bookmarked] of the article with [id] to [value].
  /// Throws an exception if the article with [id] does not exist.
  Future<void> setArticleBookmark(Id id, bool value) async {
    await _isar.writeTxn(() async {
      var article = await _isar.articles.get(id);
      if (article == null) {
        throw Exception('Article with id $id not found');
      }
      article.bookmarked = value;
      await _isar.articles.put(article);
    });
  }

  /// Toggles the bookmarked state of the article with [id].
  /// If [Article.bookmarked] is null, it is set to true.
  /// Throws an exception if the article with [id] does not exist.
  Future<void> toggleArticleBookmark(Id id) async {
    await _isar.writeTxn(() async {
      var article = await _isar.articles.get(id);
      if (article == null) {
        throw Exception('Article with id $id not found');
      }
      article.bookmarked = !(article.bookmarked ?? false);
      await _isar.articles.put(article);
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

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildpedia/data/article.dart';

// TODO: replace factory with getInstance method
class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  static const int maxFileEntries = 100;

  late final Directory _documentsDirectory;
  late List<String> _categories;
  late ({int bookmarks, int history}) _indices;

  // TODO: remove after testing
  // ! temp
  get indices => _indices;
  get documentsDirectory => _documentsDirectory;
  Stopwatch stopwatch = Stopwatch();

  factory LocalStorage() {
    return _instance;
  }

  LocalStorage._internal() {
    stopwatch.start();
    getApplicationDocumentsDirectory()
        .then((dir) => _documentsDirectory = dir)
        .then((_) async => _indices = (await _getFileIndex()));
    _getSavedCategories().then((value) => _categories = value);
  }

  Future<List<String>> _getSavedCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('categories') ?? [];
  }

  // profile this function and see if it needs optimisation since it loops twice to filter bookmarks and history files then loops over to find the largest index when it can loop over everything once and find the largest index for each using regex
  // potential regex for finding the largest index for either `RegExp regex = RegExp(r'(history|bookmark)(\d+)\.json');`
  Future<({int bookmarks, int history})> _getFileIndex() async {
    final RegExp bookmarksRegex = RegExp(r'^bookmarks\d+\.json$');
    final RegExp historyRegex = RegExp(r'^history\d+\.json$');

    final List<FileSystemEntity> entities =
        await _documentsDirectory.list().toList();
    List<File> bookmarkFiles = entities
        .where((e) =>
            (e is File) && (bookmarksRegex.hasMatch(path.basename(e.path))))
        .cast<File>()
        .toList();
    List<File> historyFiles = entities
        .where((e) =>
            (e is File) && (historyRegex.hasMatch(path.basename(e.path))))
        .cast<File>()
        .toList();

    int bookmark = 0, history = 0;
    final RegExp indexRegex = RegExp(r'(\d+)');

    for (var file in bookmarkFiles) {
      Match? match = indexRegex.firstMatch(path.basename(file.path));
      if (match != null) {
        bookmark = max(bookmark, int.parse(match.group(1)!));
      }
    }

    for (var file in historyFiles) {
      Match? match = indexRegex.firstMatch(path.basename(file.path));
      if (match != null) {
        history = max(history, int.parse(match.group(1)!));
      }
    }

    // TODO: check if the existing file has reached the max limit and create a new file and increment the index for bookmark and history
    return (bookmarks: bookmark, history: history);
  }

  // TODO: make private after testing
  Future<List?> getFileEntries(File file) async {
    try {
      if (await file.exists()) {
        var input = await file.readAsString();
        var map = jsonDecode(input);
        var entries = map['entries'] as List;
        return entries
            .map((entry) => Article(
                  title: entry['title'],
                  dateAccessed: DateTime.fromMillisecondsSinceEpoch(
                      entry['dateAccessed']),
                  url: entry['url'],
                ))
            .toList();
      } else {
        throw Exception('File does not exist');
      }
    } catch (e) {
      debugPrint('error in getFileEntries: $e');
    }
  }

  // TODO: make private after testing
  Future<int> getFileEntryCount(File file) async {
    try {
      if (await file.exists()) {
        var input = await file.readAsString();
        var map = jsonDecode(input);
        var entries = map['entries'] as List;
        return entries.length;
      } else {
        throw Exception('File does not exist');
      }
    } catch (e) {
      debugPrint('error in getFileEntryCount: $e');
    }
    return 0;
  }

  // TODO: add create file method

  List<String> get categories => _categories;

  set categories(List<String> categories) {
    _categories = categories;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList('categories', categories);
    });
  }
}

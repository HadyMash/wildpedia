import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wildpedia/data/article.dart';
import 'package:wildpedia/services/storage.dart';
import 'package:wildpedia/shared/snackbars.dart';

class History extends StatefulWidget {
  final HistoryView initialView;

  const History({this.initialView = HistoryView.history, super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> with SingleTickerProviderStateMixin {
  late final TabController tabController;

  final GlobalKey<_PaginatedViewState> bookmarksKey =
      GlobalKey<_PaginatedViewState>();
  final GlobalKey<_PaginatedViewState> historyKey =
      GlobalKey<_PaginatedViewState>();

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      initialIndex: widget.initialView.index,
      length: HistoryView.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () async {
                var result = await showSearch(
                    context: context,
                    delegate: _SearchDelegate(setHistoryState: (
                        {Article? modifiedArticle, Article? deletedArticle}) {
                      final state =
                          (tabController.index == 0 ? bookmarksKey : historyKey)
                              .currentState;

                      if (state == null) {
                        return;
                      }

                      state.setState(() {
                        if (modifiedArticle != null) {
                          var existingArticleIndex = state.articles.indexWhere(
                              (element) => element.id == modifiedArticle.id);
                          if (existingArticleIndex != -1) {
                            state.articles[existingArticleIndex] =
                                modifiedArticle;
                          }
                        }

                        if (deletedArticle != null) {
                          var existingArticleIndex = state.articles.indexWhere(
                              (element) => element.id == deletedArticle.id);
                          if (existingArticleIndex != -1) {
                            state.articles.removeAt(existingArticleIndex);
                          }
                        }
                      });
                    }));
                try {
                  if (result != null && context.mounted) {
                    _closeAndLoadPage(
                        context, Uri.parse((result as Article).url));
                  }
                } catch (e) {
                  debugPrint(e.toString());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        errorSnackBar(context, 'Error opening article'));
                  }
                }
              },
            ),
          )
        ],
        title: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Bookmarks'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _PaginatedView(
            key: bookmarksKey,
            paginationFunction: LocalStorage().paginateBookmarkedArticles,
          ),
          _PaginatedView(
            key: historyKey,
            paginationFunction: LocalStorage().paginateArticles,
          ),
        ],
      ),
    );
  }
}

// TODO: if the currently loaded page's bookmark status is changed form history/bookmarks, update it on the home page
class _PaginatedView extends StatefulWidget {
  final _PaginationFunction paginationFunction;
  const _PaginatedView({required this.paginationFunction, super.key});

  @override
  State<_PaginatedView> createState() => _PaginatedViewState();
}

// TODO: consider using one stream instead of multiple futures
class _PaginatedViewState extends State<_PaginatedView> {
  LocalStorage storage = LocalStorage();

  bool loading = false;
  bool hasNext = true;

  late Future<({List<Article> articles, bool hasNext})> articlesFuture;
  final ScrollController scrollController =
      ScrollController(keepScrollOffset: true);

  List<Article> articles = [];

  @override
  void initState() {
    super.initState();
    articlesFuture = widget.paginationFunction();
    articlesFuture.then((result) => setState(() {
          articles = result.articles;
          hasNext = result.hasNext;
        }));
    scrollController.addListener(() {
      if (scrollController.offset >=
          scrollController.position.maxScrollExtent) {
        if (hasNext) {
          if (!loading) {
            loading = true;
            if (articles.isNotEmpty) {
              widget
                  .paginationFunction(articles.last.dateAccessed)
                  .then((result) {
                hasNext = result.hasNext;
                loading = false;
                setState(() => articles.addAll(result.articles));
              });
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: articlesFuture,
      builder: (context, future) {
        switch (future.connectionState) {
          case ConnectionState.waiting:
            return const Center(child: CircularProgressIndicator());
          case ConnectionState.done:
            if (articles.isEmpty || !future.hasData) {
              return const Center(child: Text('No articles'));
            }

            return Scrollbar(
              controller: scrollController,
              // TODO: add date separators
              child: ListView.builder(
                controller: scrollController,
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  onDismissed() {
                    LocalStorage().deleteArticle(article.id);
                    setState(() => articles.removeAt(index));
                  }

                  final tile = _ArticleTile(
                    article: article,
                    onDismissed: onDismissed,
                    toggleBookmark: () async {
                      await storage.setArticleBookmark(
                          article.id, !(article.bookmarked ?? false));
                      setState(() =>
                          article.bookmarked = !(article.bookmarked ?? false));
                    },
                    onTap: () =>
                        _closeAndLoadPage(context, Uri.parse(article.url)),
                  );

                  if (index == articles.length - 1) {
                    return Column(
                      children: [
                        tile,
                        Padding(
                          padding: EdgeInsets.only(
                              top: 16.0,
                              bottom: max(
                                  8.0, MediaQuery.of(context).padding.bottom)),
                          child: hasNext
                              ? const CircularProgressIndicator()
                              : const Text('No more articles'),
                        ),
                      ],
                    );
                  }
                  return tile;
                },
              ),
            );
          default:
            return const Center(child: Text('Error, unable to read data'));
        }
      },
    );
  }
}

class _SearchDelegate extends SearchDelegate {
  final void Function({Article? modifiedArticle, Article? deletedArticle})
      setHistoryState;
  _SearchDelegate({required this.setHistoryState}) : super();

  @override
  List<Widget>? buildActions(BuildContext context) {
    // TODO: add bookmark filter button
    return [
      // clear button
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  Widget _articleList() {
    if (query.isEmpty) {
      return Container();
    }
    return FutureBuilder(
      future: LocalStorage().searchArticles(query),
      builder: (context, future) {
        switch (future.connectionState) {
          case ConnectionState.waiting || ConnectionState.active:
            return const Center(child: CircularProgressIndicator());
          case ConnectionState.done:
            if (!future.hasData || (future.data as List<Article>).isEmpty) {
              return const Center(child: Text('No articles'));
            }

            final articles = future.data as List<Article>;

            return StatefulBuilder(
              builder: (context, setState) {
                return ListView.builder(
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    onDismissed() {
                      LocalStorage().deleteArticle(article.id);
                      setState(() => articles.removeAt(index));
                      setHistoryState(deletedArticle: article);
                    }

                    final tile = _ArticleTile(
                        article: article,
                        onDismissed: onDismissed,
                        toggleBookmark: () async {
                          await LocalStorage().setArticleBookmark(
                              article.id, !(article.bookmarked ?? false));
                          setState(() => article.bookmarked =
                              !(article.bookmarked ?? false));
                          setHistoryState(modifiedArticle: article);
                        },
                        onTap: () => close(context, article));

                    if (index == articles.length - 1) {
                      return Column(
                        children: [
                          tile,
                          Padding(
                            padding: EdgeInsets.only(
                                top: 16.0,
                                bottom: max(8.0,
                                    MediaQuery.of(context).padding.bottom)),
                            child: const Text('No more articles'),
                          ),
                        ],
                      );
                    }
                    return tile;
                  },
                );
              },
            );
          default:
            return const Center(child: Text('Error, unable to read data'));
        }
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) => _articleList();

  // TODO: add a setting which controls if the database is searched while typing or only when search is submitted for performance reasons
  @override
  Widget buildSuggestions(BuildContext context) => _articleList();
}

class _ArticleTile extends StatelessWidget {
  final Article article;
  final VoidCallback onDismissed;
  final VoidCallback toggleBookmark;
  final VoidCallback onTap;
  const _ArticleTile({
    required this.article,
    required this.onDismissed,
    required this.toggleBookmark,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(article.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        dismissible: DismissiblePane(onDismissed: onDismissed),
        extentRatio: 1 / 4,
        children: [
          SlidableAction(
            backgroundColor: Colors.red,
            icon: Icons.delete,
            foregroundColor: Colors.white,
            autoClose: false,
            onPressed: (context) => Slidable.of(context)?.dismiss(ResizeRequest(
              const Duration(milliseconds: 300),
              onDismissed,
            )),
          ),
        ],
      ),
      child: ListTile(
        title: Text(article.title),
        subtitle: Text(article.dateAccessed.toString()),
        trailing: IconButton(
          icon: Icon(
            article.bookmarked ?? false
                ? Icons.bookmark
                : Icons.bookmark_outline,
          ),
          color: Theme.of(context).primaryColor,
          onPressed: toggleBookmark,
        ),
        onTap: onTap,
      ),
    );
  }
}

_closeAndLoadPage(BuildContext context, Uri uri) {
  final webViewController = Provider.of<WebViewController>(
    context,
    listen: false,
  );
  webViewController.loadRequest(uri);
  Navigator.of(context).pop();
}

typedef _PaginationFunction = Future<({List<Article> articles, bool hasNext})>
    Function([DateTime? after, int limit]);

enum HistoryView {
  bookmarks,
  history,
}

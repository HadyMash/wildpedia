import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wildpedia/data/article.dart';
import 'package:wildpedia/services/storage.dart';

class History extends StatelessWidget {
  final HistoryView initialView;
  final WebViewController webViewController;
  const History(this.webViewController,
      {this.initialView = HistoryView.history, super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: initialView.index,
      length: 2,
      child: Scaffold(
        // TODO: add search bar
        // TODO: convert to sliver app bar and hide bottom when scrolling
        appBar: AppBar(
          title: const Text('[insert search bar]'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'History'),
              Tab(text: 'Bookmarks'),
            ],
          ),
        ),
        // TODO: get history from storage and load it in
        body: TabBarView(
          children: [
            _PaginatedView(
                paginationFunction: LocalStorage().paginateArticles,
                onTap: (url) {
                  webViewController.loadRequest(Uri.parse(url));
                  Navigator.of(context).pop();
                }),
            const Center(
              child: Text('Bookmarks'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginatedView extends StatefulWidget {
  final _PaginationFunction paginationFunction;
  final void Function(String url) onTap;
  const _PaginatedView(
      {required this.paginationFunction, required this.onTap, super.key});

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
              // TODO: add loading indicator at bottom
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

                  final slidable = Slidable(
                    key: ValueKey(article.id),
                    startActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      dismissible: DismissiblePane(onDismissed: onDismissed),
                      children: [
                        SlidableAction(
                          backgroundColor: Colors.red,
                          icon: Icons.delete,
                          foregroundColor: Colors.white,
                          autoClose: false,
                          onPressed: (context) =>
                              Slidable.of(context)?.dismiss(ResizeRequest(
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
                        onPressed: () {},
                      ),
                      onTap: () => widget.onTap(article.url),
                    ),
                  );

                  if (index == articles.length - 1) {
                    return Column(
                      children: [
                        slidable,
                        Offstage(
                          offstage: !hasNext,
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        )
                      ],
                    );
                  }
                  return slidable;
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

typedef _PaginationFunction = Future<({List<Article> articles, bool hasNext})>
    Function([DateTime? after, int limit]);

enum HistoryView {
  history,
  bookmarks,
}

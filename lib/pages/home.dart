import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wildpedia/data/article.dart';
import 'package:wildpedia/services/storage.dart';
import 'package:wildpedia/services/wikipedia.dart';
import 'package:wildpedia/shared/snackbars.dart' as snackbars;

import 'history.dart';
import 'settings.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

// TODO: update colors to use theme colors
class _HomeState extends State<Home> {
  late final WebViewController _controller;
  int progress = 0;
  Future<int?>? pageIdFuture;
  bool canGoBack = false;
  bool canGoForward = false;

  // TODO: replace both with theme values
  // default padding is 16.0
  final double _cupertinoButtonPadding = 12;
  // default size is 24.0
  static const double _iconSize = 24.0;

  @override
  void initState() {
    super.initState();
    LocalStorage();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            debugPrint(progress.toString());
            setState(() => this.progress = progress);
            // debugPrint(this.progress.toString());
            // setState(() => this.progress += progress -
            //     (this.progress < 100 ? this.progress : this.progress - 100));
          },
          onPageStarted: (String url) async {
            debugPrint('started loading $url');
            pageIdFuture = null;
            pageIdFuture = Wikipedia.getPageId(Uri.parse(url).pathSegments[1]);
          },
          onPageFinished: (String url) async {
            debugPrint('finished loading $url');
            final Uri uri = Uri.parse(url);
            // TODO: update to work with wikiwand
            // TODO: update to work with other languages
            // TODO: run this in a separate isolate
            if (uri.host.contains('wikipedia') &&
                uri.path.startsWith('/wiki/')) {
              try {
                final title = uri.pathSegments[1];
                final pageId = await pageIdFuture;
                if (pageId == null) {
                  throw Exception('pageId is null');
                }
                LocalStorage().addArticleToHistory(Article(
                  id: pageId,
                  title: title.replaceAll('_', ' '),
                  dateAccessed: DateTime.now(),
                  url: url,
                ));
              } catch (e) {
                debugPrint('error adding page to history: $e');
                ScaffoldMessenger.of(context).showSnackBar(snackbars
                    .errorSnackBar(context, 'Error adding page to history'));
              }
            }
            List<bool> browserNavigation = await Future.wait([
              _controller.canGoBack(),
              _controller.canGoForward(),
            ]);

            setState(() {
              canGoBack = browserNavigation[0];
              canGoForward = browserNavigation[1];
            });
          },
        ),
      );
    _controller
        .loadRequest(_newUri('en', 'Physics', _randomIntBetween(1, max(1, 3))));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.setBackgroundColor(Theme.of(context).scaffoldBackgroundColor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  color: Theme.of(context).colorScheme.primary,
                  height: progress == 100 || progress < 0 ? 0 : 10,
                  width: MediaQuery.of(context).size.width *
                      (max(progress, 0) / 100),
                ),
              ),
              Expanded(
                child: WebViewWidget(controller: _controller),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            // TODO: update buttons to use theme data for colors
            children: [
              CupertinoButton(
                padding: EdgeInsets.all(_cupertinoButtonPadding),
                onPressed: canGoBack ? _controller.goBack : null,
                child: Icon(
                  Icons.arrow_back_ios,
                  size: _iconSize,
                  color: canGoBack ? Colors.black : Colors.grey,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.all(_cupertinoButtonPadding),
                onPressed: () => _controller.reload(),
                child: const Icon(
                  Icons.refresh,
                  size: _iconSize,
                  color: Colors.black,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.all(_cupertinoButtonPadding),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    clipBehavior: Clip.hardEdge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    builder: (context) => SafeArea(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Wrap(
                            children: [
                              // _ModalBottomSheetTile(
                              //   icon: Icons.refresh,
                              //   title: 'Reload',
                              //   onTap: () {
                              //     Navigator.of(context).pop();
                              //     _controller.reload();
                              //   },
                              // ),
                              _ModalBottomSheetTile(
                                icon: Icons.bookmark,
                                title: 'Bookmarks',
                                onTap: () {
                                  Navigator.of(context).pop();

                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => History(_controller,
                                          initialView: HistoryView.bookmarks),
                                    ),
                                  );
                                },
                              ),
                              _ModalBottomSheetTile(
                                icon: Icons.history,
                                title: 'History',
                                onTap: () {
                                  Navigator.of(context).pop();

                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          History(_controller),
                                    ),
                                  );
                                },
                              ),
                              // TODO: add bug report functionality
                              _ModalBottomSheetTile(
                                icon: Icons.bug_report,
                                title: 'Report Bug',
                                onTap: () {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      snackbars.warningSnackBar(context,
                                          'This feature is not yet implemented'));
                                },
                              ),
                              _ModalBottomSheetTile(
                                icon: Icons.settings,
                                title: 'Settings',
                                onTap: () {
                                  Navigator.of(context).pop();

                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const Settings(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Icon(
                  Icons.menu,
                  size: _iconSize,
                  color: Colors.black,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.all(_cupertinoButtonPadding),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      snackbars.warningSnackBar(
                          context, 'This feature is not yet implemented'));
                },
                child: const Icon(
                  Icons.bookmark_add_outlined,
                  size: _iconSize,
                  color: Colors.black,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.all(_cupertinoButtonPadding),
                onPressed: () => setState(() {
                  if (canGoForward) {
                    _controller.goForward();
                  } else {
                    // TODO: get language and category and depth from settings
                    // TODO: get random category
                    _controller.loadRequest(_newUri(
                        'en', 'Physics', _randomIntBetween(1, max(1, 3))));
                    // TODO: add page to history
                  }
                }),
                child: Icon(
                  canGoForward ? Icons.arrow_forward_ios : Icons.add,
                  size: _iconSize,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Uri _newUri(String language, String category, int depth) =>
    Uri.https('tools.wmflabs.org', '/magnustools/randomarticle.php', {
      'lang': language,
      'project': 'wikipedia',
      'categories': category,
      'd': depth.toString(),
    });

/// Generates a random number between [min] and [max] (inclusive).
int _randomIntBetween(int min, int max) {
  if (min > max) {
    int tempMin = min;
    min = max;
    max = tempMin;
  }

  return min + Random().nextInt(max - min + 1);
}

class _ModalBottomSheetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  // default size is 24.0
  static const double _iconSize = 24.0;

  const _ModalBottomSheetTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(
          icon,
          size: _iconSize,
          color: Colors.white,
        ),
      ),
      onTap: onTap,
    );
  }
}

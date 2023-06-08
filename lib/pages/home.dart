import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  bool canGoBack = false;
  bool canGoForward = false;

  bool _randomPage = true;

  // TODO: replace both with theme values
  // default padding is 16.0
  final double _cupertinoButtonPadding = 12;
  // default size is 24.0
  static const double _iconSize = 24.0;

  @override
  void initState() {
    super.initState();
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
          onPageStarted: (String url) {
            debugPrint('started loading $url');
            // Magnus tool random article uri.host: 'tools.wmflabs.org'
            // Wikipedia uri.host: 'en.wikipedia.org'
            // if (Uri.parse(url).host.contains('wmflabs.org')) {
            //   progress = 0;
            // }
          },
          onPageFinished: (String url) async {
            debugPrint('finished loading $url');
            final canGoBack = await _controller.canGoBack();
            final canGoForward = await _controller.canGoForward();
            setState(() {
              var uri = Uri.parse(url);
              // Magnus tool random article uri.host: 'tools.wmflabs.org'
              // Wikipedia ur.host: 'en.wikipedia.org'
              if (uri.host.contains('wikipedia.org') && _randomPage) {
                _randomPage = false;
                // TODO: add page to history
              }
              // if (!uri.host.contains('wmflabs.org')) {
              //   Future.delayed(const Duration(milliseconds: 250), () {
              //     if (!_loading) {
              //       setState(() => progress = -1);
              //       debugPrint('setting progress to -1');
              //     }
              //   });
              // }

              this.canGoBack = canGoBack;
              this.canGoForward = canGoForward;
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
                onPressed: () {
                  // TODO add menu with options
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
                              _ModalBottomSheetTile(
                                icon: Icons.refresh,
                                title: 'Reload',
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _controller.reload();
                                },
                              ),
                              _ModalBottomSheetTile(
                                icon: Icons.history,
                                title: 'History',
                                onTap: () {
                                  Navigator.of(context).pop();

                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const History(),
                                    ),
                                  );
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
                onPressed: () => setState(() {
                  if (canGoForward) {
                    _controller.goForward();
                  } else {
                    _randomPage = true;
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
    super.key,
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

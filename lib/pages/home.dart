import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

// TODO: check to see what happens if a page other than wmflabs or wikipedia is loaded
class _HomeState extends State<Home> {
  late final WebViewController _controller;
  int progress = 0;
  bool canGoBack = false;
  bool canGoForward = false;

  final Color _clickable = Colors.black;
  final Color _unclickable = Colors.grey;

  List<Uri> pages = [];
  int _pagesIndex = -1;
  bool _randomPage = true;
  bool _loading = false;

  // default padding is 16.0
  final double _cupertinoButtonPadding = 12;
  // default size is 24.0
  final double _iconSize = 24;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            debugPrint(this.progress.toString());
            setState(() => this.progress += progress -
                (this.progress < 100 ? this.progress : this.progress - 100));
          },
          onPageStarted: (String url) {
            _loading = true;
            // TODO: check to see if the tool still works
            // Magnus tool random article uri.host: 'tools.wmflabs.org'
            // Wikipedia ur.host: 'en.wikipedia.org'
            if (Uri.parse(url).host.contains('wmflabs.org')) {
              progress = 0;
            }
          },
          onPageFinished: (String url) async {
            _loading = false;
            final canGoBack = await _controller.canGoBack();
            final canGoForward = await _controller.canGoForward();
            setState(() {
              var uri = Uri.parse(url);
              // Magnus tool random article uri.host: 'tools.wmflabs.org'
              // Wikipedia ur.host: 'en.wikipedia.org'
              if (uri.host.contains('wikipedia.org') && _randomPage) {
                pages.add(uri);
                _pagesIndex++;
                _randomPage = false;
                Future.delayed(const Duration(milliseconds: 250), () {
                  if (!_loading) {
                    setState(() => progress = -1);
                    debugPrint('setting progress to -1');
                  }
                });
              }

              this.canGoBack = canGoBack;
              this.canGoForward = canGoForward;
            });
          },
        ),
      );
    _controller.loadRequest(Uri.parse(_url(category: 'Physics')));
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
                  height: progress == 200 || progress < 0 ? 0 : 10,
                  width: MediaQuery.of(context).size.width *
                      (max(progress, 0) / 200),
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
            children: [
              const Spacer(flex: 2),
              Expanded(
                flex: 16,
                child: ElevatedButton(
                  onPressed: max(0, _pagesIndex) == 0
                      ? null
                      : () => setState(() {
                            progress = 100;
                            _controller
                                .loadRequest(pages[max(--_pagesIndex, 0)]);
                          }),
                  child: const Text('Previous'),
                ),
              ),
              const Spacer(flex: 2),
              const VerticalDivider(
                color: Colors.grey,
                thickness: 1,
                width: 4,
                indent: 10,
                endIndent: 10,
              ),
              CupertinoButton(
                padding: EdgeInsets.all(_cupertinoButtonPadding),
                child: Icon(
                  CupertinoIcons.back,
                  size: _iconSize,
                  color: canGoBack ? _clickable : _unclickable,
                ),
                onPressed: () => _controller.goBack(),
              ),
              CupertinoButton(
                padding: EdgeInsets.all(_cupertinoButtonPadding),
                child: Icon(
                  Icons.settings,
                  size: _iconSize,
                  color: Colors.black,
                ),
                onPressed: () {
                  // TODO add dialog box with settings
                },
              ),
              CupertinoButton(
                padding: EdgeInsets.all(_cupertinoButtonPadding),
                child: Icon(
                  CupertinoIcons.forward,
                  size: _iconSize,
                  color: canGoForward ? _clickable : _unclickable,
                ),
                onPressed: () => _controller.goForward(),
              ),
              const VerticalDivider(
                color: Colors.grey,
                thickness: 1,
                width: 4,
                indent: 10,
                endIndent: 10,
              ),
              const Spacer(flex: 2),
              Expanded(
                flex: 16,
                child: ElevatedButton(
                  child: Text(pages.length - 1 > _pagesIndex ? 'Next' : 'New'),
                  onPressed: () => setState(() {
                    if (pages.length - 1 > _pagesIndex) {
                      progress = 100;
                      _controller.loadRequest(pages[max(0, ++_pagesIndex)]);
                    } else {
                      _randomPage = true;
                      _controller
                          .loadRequest(Uri.parse(_url(category: 'Physics')));
                    }
                  }),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

String _url(
        {String language = 'en', required String category, int depth = 3}) =>
    'https://tools.wmflabs.org/magnustools/randomarticle.php?lang=$language&project=wikipedia&categories=${category.replaceAll(' ', '+')}&d=${randomInt(1, max(1, depth))}';

int randomInt(int min, int max) {
  if (min > max) {
    int tempMin = min;
    min = max;
    max = tempMin;
  }

  return min + Random().nextInt(max - min);
}

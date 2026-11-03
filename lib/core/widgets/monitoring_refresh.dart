import 'dart:async';
import 'package:flutter/material.dart';

// Poll only while the screen is visible and the app is foregrounded.
class MonitoringRefresh extends StatefulWidget {
  final Future<void> Function() refresh;
  final WidgetBuilder builder;
  const MonitoringRefresh(
      {super.key, required this.refresh, required this.builder});
  @override
  State<MonitoringRefresh> createState() => _MonitoringRefreshState();
}

class _MonitoringRefreshState extends State<MonitoringRefresh>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _busy = false;
  bool _scrolling = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_visible && !_scrolling) unawaited(_refresh());
    });
  }

  bool get _visible =>
      mounted &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
      (ModalRoute.of(context)?.isCurrent ?? true);
  Future<void> _refresh() async {
    if (_busy || !_visible || _scrolling) return;
    _busy = true;
    try {
      await widget.refresh();
    } catch (_) {
      /* The owning provider displays the failed refresh. */
    } finally {
      _busy = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scrolling = false;
      unawaited(_refresh());
    } else {
      _scrolling = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis != Axis.vertical) return false;
          if (notification is ScrollStartNotification) _scrolling = true;
          if (notification is ScrollEndNotification) _scrolling = false;
          return false;
        },
        child: widget.builder(context),
      );
}

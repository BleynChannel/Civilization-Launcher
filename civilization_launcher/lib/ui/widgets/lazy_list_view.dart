import 'package:flutter/material.dart';

class LazyListView<T> extends StatefulWidget {
  final Future<List<T>> Function() fetch;
  final Widget Function(BuildContext context, int index, T element) itemBuilder;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final Widget Function(BuildContext context)? progressBuilder;

  const LazyListView({
    Key? key,
    required this.fetch,
    required this.itemBuilder,
    this.separatorBuilder,
    this.progressBuilder,
  }) : super(key: key);

  @override
  _LazyListViewState<T> createState() => _LazyListViewState<T>();
}

class _LazyListViewState<T> extends State<LazyListView<T>> {
  late ScrollController _controller;

  final _pairList = <T>[];

  bool _isLoading = true;
  bool _hasMore = true;

  late bool _isDispose;

  void _loadMore() {
    _isLoading = true;
    widget.fetch().then((List<T> fetchedList) {
      if (!_isDispose) {
        if (fetchedList.isEmpty) {
          setState(() {
            _isLoading = false;
            _hasMore = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _pairList.addAll(fetchedList);
          });
        }
      }
    });
  }

  void _scrollListener() {
    if (_controller.position.extentAfter <= 0 && !_isLoading) {
      _loadMore();
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = ScrollController()..addListener(_scrollListener);

    _isDispose = false;

    _isLoading = true;
    _hasMore = true;
    _loadMore();
  }

  @override
  void dispose() {
    _isDispose = true;
    _controller.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LazyListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fetch != oldWidget.fetch) {
      _pairList.clear();
      _isLoading = true;
      _hasMore = true;
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = _hasMore && widget.progressBuilder != null
        ? _pairList.length + 1
        : _pairList.length;
    Widget itemBuilder(BuildContext context, int index) {
      if (index >= _pairList.length && widget.progressBuilder != null) {
        return Center(child: widget.progressBuilder!(context));
      }

      return widget.itemBuilder(context, index, _pairList[index]);
    }

    return widget.separatorBuilder == null
        ? ListView.builder(
            controller: _controller,
            itemBuilder: itemBuilder,
            itemCount: itemCount,
          )
        : ListView.separated(
            controller: _controller,
            itemBuilder: itemBuilder,
            separatorBuilder: widget.separatorBuilder!,
            itemCount: itemCount,
          );
  }
}

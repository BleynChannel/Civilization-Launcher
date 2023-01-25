import 'dart:math';

class NewsRepository {
  // static const

  static const _itemsPerPage = 5;
  int _currentPage = 0;

  Future<List<String>> fetch() async {
    // final list = <String>[];
    // final n = min(_itemsPerPage,  - _currentPage * _itemsPerPage);

    // await Future.delayed(Duration(seconds: 1), () {
    //   for (int i = 0; i < n; i++) {
    //     list.add();
    //   }
    // });
    // _currentPage++;
    // return list;

    await Future.delayed(const Duration(seconds: 3));

    return List.filled(_itemsPerPage,
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.');
  }
}

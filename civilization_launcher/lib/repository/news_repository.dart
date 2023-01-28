import 'dart:math';

import 'package:civilization_launcher/core/installer/modpack/src/repo_controller.dart';
import 'package:civilization_launcher/keys.dart';
import 'package:civilization_launcher/model/card_model.dart';

class NewsRepository {
  final int total;
  int countRaw = 0;

  NewsRepository({this.total = 5});

  Future<List<CardModel>> fetch() async {
    final result = <CardModel>[];

    const repo = RepoController(
      githubToken: githubToken,
      githubUser: githubUser,
      githubRepo: githubRepo,
    );

    final news = await repo.getFilesFromDirectory(directoryPath: 'news');
    final count = min(total, news.length - countRaw);

    for (int i = countRaw + count; i > 0; i--) {
      final rawData = await repo.rawFile(path: 'news/$i.md');
      final data = rawData.split('\n');

      result.add(CardModel(title: data[0].substring(2), data: data.skip(1).join('\n')));
    }

    countRaw += count;

    return result;
  }
}

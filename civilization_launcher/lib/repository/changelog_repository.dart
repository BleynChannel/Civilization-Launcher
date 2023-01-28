import 'dart:math';

import 'package:civilization_launcher/const.dart';
import 'package:civilization_launcher/model/card_model.dart';

class ChangelogRepository {
  final int total;
  int countRaw = 0;

  ChangelogRepository({this.total = 5});

  Future<List<CardModel>> fetch() async {
    final result = <CardModel>[];

    final updateCount = await updater.getUpdateCount();
    final count = min(total, updateCount - countRaw);

    for (int i = countRaw + count; i > 0; i--) {
      final rawChangelog = await updater.getChangelogFromID(id: i);
      final changelog = rawChangelog?.split('\n');
      final info = await updater.getInfoFromID(id: i);
      result.add(CardModel(
        title: 'v.${info.modpackVersion}',
        data: changelog?.skip(1).join('\n'),
      ));
    }

    countRaw += count;

    return result;
  }
}

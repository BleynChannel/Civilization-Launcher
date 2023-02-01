import 'dart:convert';
import 'dart:io';

import 'package:civilization_launcher/core/installer/modpack/modpack_info.dart';
import 'package:civilization_launcher/core/installer/modpack/src/repo_controller.dart';
import 'package:civilization_launcher/core/installer/modpack/src/update_parser.dart';
import 'package:civilization_launcher/core/utils/callback/callback.dart';
import 'package:civilization_launcher/core/utils/error/network_exception.dart';
import 'package:dio/dio.dart';

class ModpackUpdater {
  final String githubToken;
  final String githubUser;
  final String githubRepo;

  int? currentID;
  int? _newID;

  int? get newID => _newID;

  final RepoController _repoController;

  ModpackUpdater({
    required this.githubToken,
    required this.githubUser,
    required this.githubRepo,
    this.currentID,
  }) : _repoController = RepoController(
          githubToken: githubToken,
          githubUser: githubUser,
          githubRepo: githubRepo,
        );

  //Проверяет на новое обновление
  Future<ModpackUpdateType> checkUpdate() async {
    //Если установленная версия такая же, как и в репозитории - false
    final raw = await _repoController.rawFile(path: 'pack.info');
    final json = jsonDecode(raw);
    _newID = json['modpackID'];

    if (currentID == null) {
      return ModpackUpdateType.install;
    } else if (currentID! == _newID!) {
      return ModpackUpdateType.normal;
    } else if (currentID! < _newID!) {
      return ModpackUpdateType.update;
    } else {
      return ModpackUpdateType.rollback;
    }
  }

  //Получаем информацию по конкретному обновлению
  Future<ModpackInfo> getInfoFromID({required int id}) async {
    final raw = await _repoController.rawFile(path: 'versions/$id/pack.info');
    final json = jsonDecode(raw);
    return ModpackInfo.fromJson(json);
  }

  //Получаем список изменений по конкретному обновлению
  Future<String?> getChangelogFromID({required int id}) async {
    final path = 'versions/$id/changelog.md';
    try {
      return await _repoController.rawFile(path: path);
    } on NetworkException catch (e) {
      if (e.code != 404) rethrow;
    }

    return null;
  }

  //Получаем кол-во всех имеющихся обновлений
  Future<int> getUpdateCount() async {
    const directoryPath = 'versions';
    final files = await _repoController.getFilesFromDirectory(
      directoryPath: directoryPath,
    );
    return files.length;
  }

  //Устанавливает новое обновление в необходимую деректорию
  Future installUpdate({
    required String instancePath,
    ProgressCallback? onBuildDeltaUpdateProgress,
    PathProgressCallback? onPreparingInstallUpdateProgress,
    PathProgressCallback? onInstallUpdateProgress,
    ActionCallback? onPreparingInstallProgress,
    ProgressCallback? onDownloadPackProgress,
    PathProgressCallback? onUnpackPackProgress,
    ActionCallback? onClearTmpProgress,
    ActionCallback? onInstallPackInfo,
  }) async {
    if (currentID != null && _newID != null) {
      if (currentID != _newID) {
        //Если уже установлина старая версия сборки - устанавливаем файлы новых обновлений
        final deltaUpdate = await _buildDeltaUpdate(
          onBuildDeltaUpdateProgress: onBuildDeltaUpdateProgress,
        );
        await _installDeltaUpdate(
          instancePath: instancePath,
          deltaUpdate: deltaUpdate,
          onPreparingInstallUpdateProgress: onPreparingInstallUpdateProgress,
          onInstallUpdateProgress: onInstallUpdateProgress,
        );

        //Скачиваем pack.info
        onInstallPackInfo?.start?.call();
        await _installPackInfo(instancePath: instancePath);
        onInstallPackInfo?.stop?.call();

        currentID = _newID;
      }
    } else {
      //Если ни разу не устанавливалась сборка - установим самую новую версию
      await _installMaster(
        instancePath: instancePath,
        onPreparingInstallProgress: onPreparingInstallProgress,
        onDownloadPackProgress: onDownloadPackProgress,
        onUnpackPackProgress: onUnpackPackProgress,
        onClearTmpProgress: onClearTmpProgress,
      );

      //Скачиваем pack.info
      onInstallPackInfo?.start?.call();
      await _installPackInfo(instancePath: instancePath);
      onInstallPackInfo?.stop?.call();

      currentID = _newID;
    }
  }

  static const totalProgress = 4;

  Future<List<UpdateField>> _buildDeltaUpdate({
    ProgressCallback? onBuildDeltaUpdateProgress,
  }) async {
    //Проверяем откат
    final isRollback = currentID! > _newID!;

    //Получаем информацию по всем изменениям каждой версии
    final raw = await _repoController.rawBigFile(path: 'update');
    final updateList = UpdateParser.fromUpdate(data: raw);

    onBuildDeltaUpdateProgress?.call(1, totalProgress);

    //Берем определенный диапозон изменений
    final finalyUpdateList = updateList.where((field) {
      if (isRollback) {
        //Если происходит откат меняем действия с изменениями местами
        field.type = field.type == UpdateChangeType.add
            ? UpdateChangeType.delete
            : (field.type == UpdateChangeType.delete
                ? UpdateChangeType.add
                : field.type);

        return field.id <= currentID! && field.id > _newID!;
      } else {
        return field.id > currentID! && field.id <= _newID!;
      }
    }).toList();
    finalyUpdateList.sort((a, b) {
      if (isRollback) {
        return a.id > b.id ? -1 : 1;
      } else {
        return a.id < b.id ? -1 : 1;
      }
    });

    onBuildDeltaUpdateProgress?.call(2, totalProgress);

    //Составляем новый список изменений
    final paths =
        finalyUpdateList.map<String>((field) => field.path).toSet().toList();

    onBuildDeltaUpdateProgress?.call(3, totalProgress);

    final result = <UpdateField>[];
    for (final path in paths) {
      //Берем последние изменения с файлом
      final field = finalyUpdateList.lastWhere((field) => field.path == path);
      result.add(field);
    }

    onBuildDeltaUpdateProgress?.call(4, totalProgress);

    return result;
  }

  Future _installDeltaUpdate({
    required String instancePath,
    required List<UpdateField> deltaUpdate,
    PathProgressCallback? onPreparingInstallUpdateProgress,
    PathProgressCallback? onInstallUpdateProgress,
  }) async {
    final preparingTotalProgress = deltaUpdate.length;
    int preparingProgress = 0;

    //Отслеживаем каждый тип изменения и предпринимаем по нему какие либо действия
    final editFiles = <String>[];
    for (final field in deltaUpdate) {
      final file = File('$instancePath/${field.path}');

      if (await file.exists()) {
        await file.delete();
      }

      switch (field.type) {
        case UpdateChangeType.add:
        case UpdateChangeType.edit:
          editFiles.add(field.path);
          break;
        default:
      }

      onPreparingInstallUpdateProgress?.call(
        ++preparingProgress,
        preparingTotalProgress,
        file.path,
      );
    }

    final installTotalProgress = editFiles.length;
    int installProgress = 0;

    //Получаем sha ключи к всем изменяемым файлам
    await for (final pathAndSha in _repoController.getSHAFromFiles(
      files: editFiles,
      branch: 'pack',
    )) {
      final filePath = '$instancePath/${pathAndSha.key}';

      //Устанавливаем файл
      await _repoController.downloadFile(
        sha: pathAndSha.value,
        filePath: filePath,
      );

      onInstallUpdateProgress?.call(
        ++installProgress,
        installTotalProgress,
        filePath,
      );
    }
  }

  Future _installPackInfo({required String instancePath}) async {
    //Устанавливаем pack.info в готовую сборку
    final file = await File('$instancePath/pack.info').create(recursive: true);
    final raw = await _repoController.rawFile(path: 'pack.info');
    await file.writeAsString(raw);
  }

  Future _installMaster({
    required String instancePath,
    ActionCallback? onPreparingInstallProgress,
    ProgressCallback? onDownloadPackProgress,
    PathProgressCallback? onUnpackPackProgress,
    ActionCallback? onClearTmpProgress,
  }) async {
    onPreparingInstallProgress?.start?.call();

    //Подготовливаем папку очищая ее
    final directory = Directory(instancePath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }

    await directory.create(recursive: true);

    onPreparingInstallProgress?.stop?.call();

    //Скачиваем и устанавливаем все файлы с последнего релиза
    await _repoController.downloadReleaseFromTag(
      tag: newID!.toString(),
      directoryPath: instancePath,
      onDownloadBranchProgress: onDownloadPackProgress,
      onUnpackBranchProgress: onUnpackPackProgress,
      onClearTmpProgress: onClearTmpProgress,
    );
  }
}

enum ModpackUpdateType {
  normal,
  update,
  rollback,
  install,
}

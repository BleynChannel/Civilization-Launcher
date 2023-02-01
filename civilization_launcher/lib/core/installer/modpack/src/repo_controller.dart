import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:civilization_launcher/core/utils/callback/callback.dart';
import 'package:civilization_launcher/core/utils/error/network_exception.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class RepoController {
  static const githubApi = 'https://api.github.com';

  final String githubToken;
  final String githubUser;
  final String githubRepo;

  const RepoController({
    required this.githubToken,
    required this.githubUser,
    required this.githubRepo,
  });

  //Выдает файлы в конкретной директории в репозитории
  Future<List<Map<String, dynamic>>> getFilesFromDirectory({
    required String directoryPath,
    String branch = 'master',
  }) async {
    final url =
        '$githubApi/repos/$githubUser/$githubRepo/contents/$directoryPath?ref=$branch';

    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $githubToken',
    });
    final json = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final result = <Map<String, dynamic>>[];
      for (Map<String, dynamic> file in json as List<dynamic>) {
        result.add(file);
      }
      return result;
    } else {
      throw NetworkException(
          code: response.statusCode, message: json['message']);
    }
  }

  //Читаем файл в репозитории
  Future<String> rawFile({
    required String path,
    String branch = 'master',
  }) async {
    final url =
        '$githubApi/repos/$githubUser/$githubRepo/contents/$path?ref=$branch';

    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $githubToken',
      'Accept': 'application/vnd.github.v3.raw',
    });

    if (response.statusCode == 200) {
      return response.body;
    } else {
      final json = jsonDecode(response.body);
      throw NetworkException(
          code: response.statusCode, message: json['message']);
    }
  }

  //Читаем крупный файл размером до 100 мб
  Future<String> rawBigFile({
    required String path,
    String branch = 'master',
  }) async {
    await for (final sha in getSHAFromFiles(files: [path], branch: branch)) {
      final url = '$githubApi/repos/$githubUser/$githubRepo/git/blobs/$sha';

      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $githubToken',
        'Accept': 'application/vnd.github.v3.raw',
      });

      if (response.statusCode == 200) {
        return response.body;
      } else {
        final json = jsonDecode(response.body);
        throw NetworkException(
            code: response.statusCode, message: json['message']);
      }
    }

    throw NetworkException(code: 404, message: 'Not found');
  }

  //Получаем все ключи SHA для каждого файла из репозитория
  Stream<MapEntry<String, String>> getSHAFromFiles({
    required Iterable<String> files,
    String branch = 'master',
  }) async* {
    final relativeFiles = <String, List<String>>{};

    //Для уменьшения кол-ва запросов подбираем несколько файлов
    //для поиска в конкретной директории
    for (final filePath in files) {
      final relativePath = p.dirname(filePath);
      if (!relativeFiles.containsKey(relativePath)) {
        relativeFiles[relativePath] = <String>[];
      }

      relativeFiles[relativePath]!.add(filePath.replaceAll('\\', '/'));
    }

    //Получаем все файлы в конкретной директории
    for (final relative in relativeFiles.entries) {
      final url =
          '$githubApi/repos/$githubUser/$githubRepo/contents/${relative.key}?ref=$branch';

      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $githubToken',
      });

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        for (Map<String, dynamic> file in json as List<dynamic>) {
          if (relative.value.contains(file['path'] as String)) {
            yield MapEntry(file['path'] as String, file['sha'] as String);
          }
        }
      } else {
        throw NetworkException(
            code: response.statusCode, message: json['message']);
      }
    }
  }

  //Скачиваем файл из репозитория
  Future downloadFile({
    required String sha,
    required String filePath,
    ProgressCallback? onProgress,
  }) async {
    final url = '$githubApi/repos/$githubUser/$githubRepo/git/blobs/$sha';

    try {
      await Dio().download(
        url,
        filePath,
        options: Options(headers: {
          'Authorization': 'Bearer $githubToken',
          'Accept': 'application/vnd.github.v3.raw'
        }),
        onReceiveProgress: onProgress,
      );
    } on DioError catch (e) {
      if (e.response != null) {
        throw NetworkException(
          code: e.response?.statusCode ?? 0,
          message: e.response?.statusMessage ?? '',
        );
      }
    }
  }

  //Скачиваем ветку из репозитория
  Future downloadReleaseFromTag({
    required String tag,
    required String directoryPath,
    ProgressCallback? onDownloadBranchProgress,
    PathProgressCallback? onUnpackBranchProgress,
    ActionCallback? onClearTmpProgress,
  }) async {
    final archivePath = '$directoryPath/.archive.zip';

    //Скачиваем архив ветки
    await _downloadArchive(
      archivePath: archivePath,
      tag: tag,
      onDownloadArchiveProgress: onDownloadBranchProgress,
    );

    //Разархивироваем ветку
    await _unpackArchive(
      archivePath: archivePath,
      relativePath: '$githubRepo-$tag',
      directoryPath: directoryPath,
      onUnpackArchiveProgress: onUnpackBranchProgress,
    );

    //Удаляем архив
    onClearTmpProgress?.start?.call();
    await File(archivePath).delete(recursive: true);
    onClearTmpProgress?.stop?.call();
  }

  Future _downloadArchive({
    required String tag,
    required String archivePath,
    ProgressCallback? onDownloadArchiveProgress,
  }) async {
    final url =
        'https://github.com/$githubUser/$githubRepo/archive/refs/tags/$tag.zip';

    try {
      await Dio().download(
        url,
        archivePath,
        options: Options(headers: {'Authorization': 'Bearer $githubToken'}),
        onReceiveProgress: onDownloadArchiveProgress,
      );
    } on DioError catch (e) {
      if (e.response != null) {
        throw NetworkException(
          code: e.response?.statusCode ?? 0,
          message: e.response?.statusMessage ?? '',
        );
      }
    }
  }

  Future _unpackArchive({
    required String archivePath,
    required String relativePath,
    required String directoryPath,
    PathProgressCallback? onUnpackArchiveProgress,
  }) async {
    final input = InputFileStream(archivePath);
    final archive = ZipDecoder().decodeBuffer(input);

    final totalProgress = archive.files.length;
    int progress = 0;

    for (final archiveFile in archive.files) {
      final filePath = p.relative(archiveFile.name, from: relativePath);

      if (archiveFile.isFile) {
        final instanceFilePath = '$directoryPath/$filePath';
        await File(instanceFilePath).create(recursive: true);

        final out = OutputFileStream(instanceFilePath);
        archiveFile.writeContent(out);
        out.close();
      }

      onUnpackArchiveProgress?.call(
        ++progress,
        totalProgress,
        filePath,
      );
    }

    await input.close();
  }
}

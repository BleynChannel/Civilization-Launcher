import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:civilization_launcher/const.dart';
import 'package:civilization_launcher/core/civilization_lib.dart';
import 'package:civilization_launcher/ui/widgets/updater_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

InputDecoration getTextFieldDecoration() {
  return InputDecoration(
    hintStyle: GoogleFonts.nunitoSans(
      color: Colors.white54,
      fontWeight: FontWeight.bold,
    ),
    fillColor: Colors.black.withOpacity(0.1),
    filled: true,
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(
        color: Colors.white60,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(
        color: Colors.white,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
  );
}

Stream<UpdaterDialogMessage> loadUpdate(String instancePath) {
  final controller = StreamController<UpdaterDialogMessage>();

  const totalField = 8;
  int countField = -1;

  updater.installUpdate(
    instancePath: instancePath,
    onBuildDeltaUpdateProgress: (count, total) {
      if (countField < 0) countField++;

      try {
        controller.add(UpdaterDialogMessage.push(
          message: 'Строим список изменений',
          countField: countField,
          totalField: totalField,
          countPoint: count,
          totalPoint: total,
        ));
      } catch (e) {
        controller.add(UpdaterDialogMessage.error(message: e.toString()));
      }
    },
    onPreparingInstallUpdateProgress: (count, total, path) {
      if (countField < 1) countField++;

      try {
        controller.add(UpdaterDialogMessage.push(
          message: 'Подготавливаем файлы к обновлению: "$path"',
          countField: countField,
          totalField: totalField,
          countPoint: count,
          totalPoint: total,
        ));
      } catch (e) {
        controller.add(UpdaterDialogMessage.error(message: e.toString()));
      }
    },
    onInstallUpdateProgress: (count, total, path) {
      if (countField < 2) countField++;

      try {
        controller.add(UpdaterDialogMessage.push(
          message: 'Устанавливаем обновление: "$path"',
          countField: countField,
          totalField: totalField,
          countPoint: count,
          totalPoint: total,
        ));
      } catch (e) {
        controller.add(UpdaterDialogMessage.error(message: e.toString()));
      }
    },
    onPreparingInstallProgress: ActionCallback(
      start: () {
        if (countField < 3) countField++;

        try {
          controller.add(UpdaterDialogMessage.push(
            message: 'Подготавливаемся к установки сборки...',
            countField: countField,
            totalField: totalField,
            countPoint: 0,
            totalPoint: 1,
          ));
        } catch (e) {
          controller.add(UpdaterDialogMessage.error(message: e.toString()));
        }
      },
      stop: () {
        try {
          controller.add(UpdaterDialogMessage.push(
            message: 'Подготовка выполнена успешна!',
            countField: countField,
            totalField: totalField,
            countPoint: 1,
            totalPoint: 1,
          ));
        } catch (e) {
          controller.add(UpdaterDialogMessage.error(message: e.toString()));
        }
      },
    ),
    onDownloadPackProgress: (count, total) {
      if (countField < 4) countField++;

      try {
        controller.add(UpdaterDialogMessage.push(
          message: 'Загружаем сборку',
          countField: countField,
          totalField: totalField,
          countPoint: count,
          totalPoint: total,
        ));
      } catch (e) {
        controller.add(UpdaterDialogMessage.error(message: e.toString()));
      }
    },
    onUnpackPackProgress: (count, total, path) {
      if (countField < 5) countField++;

      try {
        controller.add(UpdaterDialogMessage.push(
          message: 'Распаковываем сборку: "$path"',
          countField: countField,
          totalField: totalField,
          countPoint: count,
          totalPoint: total,
        ));
      } catch (e) {
        controller.add(UpdaterDialogMessage.error(message: e.toString()));
      }
    },
    onClearTmpProgress: ActionCallback(
      start: () {
        if (countField < 6) countField++;

        try {
          controller.add(UpdaterDialogMessage.push(
            message: 'Очищаем временные файлы...',
            countField: countField,
            totalField: totalField,
            countPoint: 0,
            totalPoint: 1,
          ));
        } catch (e) {
          controller.add(UpdaterDialogMessage.error(message: e.toString()));
        }
      },
      stop: () {
        try {
          controller.add(UpdaterDialogMessage.push(
            message: 'Очистка прошла успешна!',
            countField: countField,
            totalField: totalField,
            countPoint: 1,
            totalPoint: 1,
          ));
        } catch (e) {
          controller.add(UpdaterDialogMessage.error(message: e.toString()));
        }
      },
    ),
    onInstallPackInfo: ActionCallback(
      start: () {
        if (countField < 7) countField++;

        try {
          controller.add(UpdaterDialogMessage.push(
            message: 'Добавляем информацию о сборке...',
            countField: countField,
            totalField: totalField,
            countPoint: 0,
            totalPoint: 1,
          ));
        } catch (e) {
          controller.add(UpdaterDialogMessage.error(message: e.toString()));
        }
      },
      stop: () {
        try {
          controller.add(UpdaterDialogMessage.push(
            message: 'Информация о сборке успешна добавлена!',
            countField: countField,
            totalField: totalField,
            countPoint: 0,
            totalPoint: 1,
          ));
        } catch (e) {
          controller.add(UpdaterDialogMessage.error(message: e.toString()));
        }

        controller.add(UpdaterDialogMessage.complete());
      },
    ),
  );

  return controller.stream;
}

Future<int?> getModpackID(String instancePath) async {
  final file = File('$instancePath/pack.info');
  if (await file.parent.exists() && await file.exists()) {
    final json = jsonDecode(await file.readAsString());
    return json['modpackID'] as int;
  }

  return null;
}

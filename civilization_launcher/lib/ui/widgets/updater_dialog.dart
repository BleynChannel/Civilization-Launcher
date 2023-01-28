import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdaterDialog extends StatelessWidget {
  final Stream<UpdaterDialogMessage> update;
  final void Function() onCloseClick;

  const UpdaterDialog({
    Key? key,
    required this.onCloseClick,
    required this.update,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: update,
      builder: (context, snapshot) {
        late String title;
        late String description;
        double? progressField;
        double? progressPoint;

        if (!snapshot.hasData) {
          title = 'Загрузка обновления...';
          description = '';
        } else {
          if (snapshot.data!.complete) {
            title = 'Загрузка завершена!';
            description = 'Можете закрыть это диалоговое окно';
          } else if (snapshot.data!.error) {
            title = 'Произошла ошибка!';
            description = snapshot.data!.message!;
          } else {
            title = 'Загрузка обновления...';
            description = snapshot.data!.message!;
            progressField = snapshot.data!.countField!.toDouble() /
                snapshot.data!.totalField!.toDouble();
            progressPoint = snapshot.data!.countPoint!.toDouble() /
                snapshot.data!.totalPoint!.toDouble();
          }
        }

        return Theme(
          data: ThemeData.light(),
          child: AlertDialog(
            title: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .headline4!
                  .copyWith(color: Colors.black),
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width / 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    description,
                    style: Theme.of(context)
                        .textTheme
                        .headline5!
                        .copyWith(color: Colors.black87),
                  ),
                  ...(snapshot.hasData &&
                          !snapshot.data!.complete &&
                          !snapshot.data!.error
                      ? <Widget>[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                snapshot.data?.countPoint.toString() ?? '',
                                style: GoogleFonts.nunitoSans(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: LinearProgressIndicator(
                                    value: progressPoint),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                snapshot.data?.totalPoint.toString() ?? '',
                                style: GoogleFonts.nunitoSans(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                snapshot.data?.countField.toString() ?? '',
                                style: GoogleFonts.nunitoSans(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: LinearProgressIndicator(
                                    value: progressField),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                snapshot.data?.totalField.toString() ?? '',
                                style: GoogleFonts.nunitoSans(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ]
                      : <Widget>[]),
                ],
              ),
            ),
            actions: snapshot.hasData &&
                    (snapshot.data!.complete || snapshot.data!.error)
                ? <Widget>[
                    ElevatedButton(
                      onPressed: onCloseClick,
                      child: Text(
                        'Close',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                    ),
                  ]
                : <Widget>[],
          ),
        );
      },
    );
  }
}

class UpdaterDialogMessage {
  final String? message;
  final int? countField;
  final int? totalField;
  final int? countPoint;
  final int? totalPoint;

  final bool complete;
  final bool error;

  UpdaterDialogMessage({
    this.message,
    this.countField,
    this.totalField,
    this.countPoint,
    this.totalPoint,
    required this.complete,
    required this.error,
  });

  factory UpdaterDialogMessage.push({
    required String message,
    required int countField,
    required int totalField,
    required int countPoint,
    required int totalPoint,
  }) =>
      UpdaterDialogMessage(
        message: message,
        countField: countField,
        totalField: totalField,
        countPoint: countPoint,
        totalPoint: totalPoint,
        complete: false,
        error: false,
      );

  factory UpdaterDialogMessage.complete() =>
      UpdaterDialogMessage(complete: true, error: false);

  factory UpdaterDialogMessage.error({required String message}) =>
      UpdaterDialogMessage(message: message, complete: false, error: true);
}

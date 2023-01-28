import 'dart:ui';

import 'package:civilization_launcher/const.dart';
import 'package:civilization_launcher/core/civilization_lib.dart';
import 'package:civilization_launcher/ui/widgets/background_view.dart';
import 'package:civilization_launcher/ui/widgets/navigator_view.dart';
import 'package:civilization_launcher/ui/widgets/path_field.dart';
import 'package:civilization_launcher/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _windowPadding = 40.0;

  _SettingsField? _currentSettings;

  late String _minecraftPath;
  late String _modpackPath;

  bool _isCheckLoading = false;

  late ModpackInfo? _modpackInfo;

  void _onDoneClick(BuildContext context) async {
    await prefs.setString(prefsMinecraftPath, _minecraftPath);
    await prefs.setString(prefsModpackPath, _modpackPath);

    // ignore: use_build_context_synchronously
    NavigatorView.back(context);
  }

  Future<String> _onCheckUpdate(BuildContext context) async {
    updater.currentID =
        await getModpackID(prefs.getString(prefsModpackPath) ?? '');
    final updateStatus = await updater.checkUpdate();

    switch (updateStatus) {
      case ModpackUpdateType.normal:
        return 'У вас уже установлена актуальная версия сборки';
      case ModpackUpdateType.update:
        return 'Есть обновление!';
      case ModpackUpdateType.install:
        return 'Сперва необходимо установить сборку!';
      case ModpackUpdateType.rollback:
        return 'Необходимо откатить сборку!';
    }
  }

  void _initSettings() {
    _minecraftPath = prefs.getString(prefsMinecraftPath) ?? '';
    _modpackPath = prefs.getString(prefsModpackPath) ?? '';
  }

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  List<_SettingsField> _buildSettings(BuildContext context) {
    final settings = [
      _SettingsField(
        title: 'Сборка',
        description: 'Настройки сборки модов',
        fields: [
          _buildCategory(
            context,
            title: 'Расположение',
            children: [
              _buildField(
                context,
                title: 'Путь к сборке модов',
                content: Row(
                  children: [
                    Expanded(
                      child: PathField(
                        path: _modpackPath,
                        onChangePath: (path) => _modpackPath = path,
                        onPathPick: (oldPath) async {
                          return await FilePicker.platform.getDirectoryPath(
                              initialDirectory: p.dirname(oldPath));
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    InkWell(
                      onTap: () async {
                        try {
                          await launchUrl(Uri.parse('file:$_modpackPath'));
                        } catch (_) {}
                      },
                      child: Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(child: Icon(Icons.folder)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          updater.currentID != null
              ? FutureBuilder(
                  future: updater.getInfoFromID(id: updater.currentID!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return _buildCategory(
                      context,
                      title: 'Информация',
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            border: Border.all(color: Colors.white),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10, right: 20),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: SvgPicture.asset(
                                        'assets/svg/minecraft-logo.svg',
                                        width: 64,
                                        height: 64,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: {
                                        'Версия сборки модов':
                                            snapshot.data!.modpackVersion,
                                        'Версия Minecraft':
                                            snapshot.data!.minecraftVersion,
                                        'Версия Forge':
                                            snapshot.data!.forgeVersion,
                                      }
                                          .entries
                                          .map<Widget>((e) => Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    e.key,
                                                    style:
                                                        GoogleFonts.nunitoSans(
                                                      color: Colors.white70,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    e.value,
                                                    style:
                                                        GoogleFonts.nunitoSans(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 30,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => setState(() {
                                          _isCheckLoading = true;
                                        }),
                                        child: Text(
                                          'Проверить обновление',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline6!
                                              .copyWith(
                                                  fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    _isCheckLoading
                                        ? FutureBuilder(
                                            future: _onCheckUpdate(context),
                                            builder: (context, snapshot) {
                                              if (!snapshot.hasData) {
                                                return const AspectRatio(
                                                  aspectRatio: 1,
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              }

                                              _isCheckLoading = false;

                                              return Text(
                                                snapshot.data!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline5!
                                                    .copyWith(
                                                        fontWeight:
                                                            FontWeight.bold),
                                              );
                                            },
                                          )
                                        : const SizedBox(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                )
              : const SizedBox(),
        ],
      ),
      _SettingsField(
        title: 'Minecraft',
        description: 'Настройки Minecraft',
        fields: [
          _buildCategory(
            context,
            title: 'Запуск',
            children: [
              _buildField(
                context,
                title: 'Путь к лаунчеру',
                content: Row(
                  children: [
                    Expanded(
                      child: PathField(
                        path: _minecraftPath,
                        onChangePath: (path) => _minecraftPath = path,
                        onPathPick: (oldPath) async {
                          final result = await FilePicker.platform.pickFiles(
                            initialDirectory: p.dirname(oldPath),
                            type: FileType.custom,
                            allowedExtensions: ['exe'],
                          );
                          return result?.paths.first;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    InkWell(
                      onTap: () async {
                        try {
                          await launchUrl(Uri.parse('file:$_minecraftPath'));
                        } catch (_) {}
                      },
                      child: Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(child: Icon(Icons.folder)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ];

    _currentSettings = _currentSettings ?? settings.first;

    return settings;
  }

  Widget _buildCategory(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headline4),
        const Divider(color: Colors.white),
        ...children,
      ],
    );
  }

  Widget _buildField(
    BuildContext context, {
    required String title,
    required Widget? content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headline4),
        SizedBox(height: content != null ? 4 : 0),
        content ?? const SizedBox(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _buildSettings(context);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: MediaQuery.of(context).size.width / 4,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: _windowPadding,
                    top: _windowPadding,
                    bottom: _windowPadding),
                child: _buildTabs(context, settings),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    right: _windowPadding, top: _windowPadding),
                child: _buildContent(context, settings),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, List<_SettingsField> settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Настройки',
          style: Theme.of(context)
              .textTheme
              .headline4!
              .copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        Expanded(
          child: ListView.separated(
            itemBuilder: (context, index) => TextButton(
              style: Theme.of(context)
                  .textButtonTheme
                  .style!
                  .copyWith(alignment: Alignment.centerLeft),
              onPressed: () =>
                  setState(() => _currentSettings = settings[index]),
              child: Text(
                settings[index].title,
                style: Theme.of(context).textTheme.headline5!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _currentSettings!.title == settings[index].title
                          ? Colors.white
                          : Colors.white60,
                    ),
              ),
            ),
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemCount: settings.length,
          ),
        ),
        const SizedBox(height: 4),
        const SizedBox(
          width: 160,
          child: Divider(color: Colors.white),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            style: Theme.of(context)
                .textButtonTheme
                .style!
                .copyWith(alignment: Alignment.centerLeft),
            onPressed: () => _onDoneClick(context),
            child: Text(
              'Готово',
              style: Theme.of(context)
                  .textTheme
                  .headline5!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, List<_SettingsField> settings) {
    return IndexedStack(
      index: settings
          .map((s) => s.title)
          .toList()
          .indexOf(_currentSettings!.title),
      children: settings.map<Widget>((s) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.description,
              style: Theme.of(context)
                  .textTheme
                  .headline4!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ...s.fields
                .expand((element) => [element, const SizedBox(height: 10)]),
          ],
        );
      }).toList(),
    );
  }
}

class _SettingsField {
  final String title;
  final String description;
  final List<Widget> fields;

  _SettingsField({
    required this.title,
    required this.description,
    required this.fields,
  });
}

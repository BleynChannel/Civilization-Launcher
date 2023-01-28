import 'package:civilization_launcher/const.dart';
import 'package:civilization_launcher/core/civilization_lib.dart';
import 'package:civilization_launcher/model/card_model.dart';
import 'package:civilization_launcher/repository/changelog_repository.dart';
import 'package:civilization_launcher/repository/news_repository.dart';
import 'package:civilization_launcher/utils.dart';
import 'package:civilization_launcher/ui/widgets/background_view.dart';
import 'package:civilization_launcher/ui/widgets/lazy_list_view.dart';
import 'package:civilization_launcher/ui/widgets/navigator_view.dart';
import 'package:civilization_launcher/ui/widgets/updater_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  void _onSettingsClick(BuildContext context) {
    NavigatorView.push(context, 'settings');
  }

  Future<String> _onCheckUpdate() async {
    final modpackPath = prefs.getString(prefsModpackPath);

    if (modpackPath == null || modpackPath.isEmpty) {
      return 'Настройте сборку модов';
    } else {
      updater.currentID =
          await getModpackID(prefs.getString(prefsModpackPath) ?? '');
      final updateStatus = await updater.checkUpdate();

      switch (updateStatus) {
        case ModpackUpdateType.normal:
          final minecraftPath = prefs.getString(prefsMinecraftPath);

          if (minecraftPath == null || minecraftPath.isEmpty) {
            return 'Настройте Minecraft';
          } else {
            return 'Играть';
          }
        case ModpackUpdateType.update:
          return 'Обновить';
        case ModpackUpdateType.install:
          return 'Установить';
        case ModpackUpdateType.rollback:
          return 'Откатить';
      }
    }
  }

  void _onPlayClick(BuildContext context, String? title) {
    if (title == null) return;

    if (title == 'Настройте сборку модов' || title == 'Настройте Minecraft') {
      _onSettingsClick(context);
    } else {
      final snackBar = ScaffoldMessenger.of(context)..hideCurrentSnackBar();

      if (title == 'Обновить' || title == 'Установить' || title == 'Откатить') {
        final path = prefs.getString(prefsModpackPath);

        snackBar.showSnackBar(SnackBar(
          content: UpdaterDialog(
            update: loadUpdate(path!),
            onCloseClick: () => setState(() => snackBar.hideCurrentSnackBar()),
          ),
          dismissDirection: DismissDirection.none,
          backgroundColor: Colors.transparent,
          duration: const Duration(days: 1),
        ));
      } else {
        final path = prefs.getString(prefsMinecraftPath);

        Launch.launchMinecraft(path: path!);

        snackBar.showSnackBar(SnackBar(
          content: Theme(
            data: ThemeData.light(),
            child: AlertDialog(
              title: const Text('Лаунчер запущен'),
              content: Text(
                'Можете закрыть это диалоговое окно',
                style: GoogleFonts.nunitoSans(fontWeight: FontWeight.bold),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => snackBar.hideCurrentSnackBar(),
                  child: Text(
                    'Закрыть',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          duration: const Duration(seconds: 8),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Expanded(
            child: _MainNewsWidget(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _buildProfile(context)),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 195,
                      minHeight: 45,
                      maxHeight: 45,
                    ),
                    child: FutureBuilder(
                      future: _onCheckUpdate(),
                      builder: (context, snapshot) {
                        late Widget child;

                        if (!snapshot.hasData) {
                          child = const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        } else {
                          child = Text(
                            snapshot.data ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .headline4!
                                .copyWith(fontWeight: FontWeight.bold),
                          );
                        }

                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 20,
                          ),
                          onPressed: () => _onPlayClick(context, snapshot.data),
                          child: child,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(BuildContext context) {
    final social = <String, String>{
      'assets/svg/discord.svg': 'https://discord.gg/AVdDw6fNsq',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: SvgPicture.asset('assets/svg/minecraft-logo.svg'),
          ),
        ),
        const SizedBox(height: 30),
        Column(children: [
          IconButton(
            iconSize: 32,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _onSettingsClick(context),
          ),
          const SizedBox(width: 32, child: Divider(color: Colors.white)),
          ...social.entries.map(
            (e) => IconButton(
              icon: SvgPicture.asset(
                e.key,
                width: 32,
                height: 32,
              ),
              onPressed: () async => await launchUrl(Uri.parse(e.value)),
            ),
          )
        ]),
      ],
    );
  }
}

class _MainNewsWidget extends StatefulWidget {
  const _MainNewsWidget({Key? key}) : super(key: key);

  @override
  _MainNewsState createState() => _MainNewsState();
}

typedef FetchCallback = Future<List<CardModel>> Function();

class _MainNewsState extends State<_MainNewsWidget> {
  static const totalElements = 5;

  late Map<String, FetchCallback> _tabs;

  late NewsRepository _newsRepo;
  late ChangelogRepository _changelogRepo;
  late String _currentTab;

  Future<List<CardModel>> _newsFetch() async {
    return await _newsRepo.fetch();
  }

  Future<List<CardModel>> _changelogFetch() async {
    return await _changelogRepo.fetch();
  }

  void _onMarkdownFullScreen(BuildContext context, String data) {
    final snackBar = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    snackBar.showSnackBar(SnackBar(
      content: Dialog(
        child: Theme(
          data: ThemeData.light(),
          child: Container(
            width: MediaQuery.of(context).size.width / 1.4,
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Markdown(
                    data: data,
                    selectable: true,
                    shrinkWrap: true,
                  ),
                ),
                const Divider(color: Colors.black54),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, right: 16),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: () => snackBar.hideCurrentSnackBar(),
                      child: const Text('Закрыть'),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      duration: const Duration(days: 1),
    ));
  }

  @override
  void initState() {
    super.initState();

    _tabs = <String, FetchCallback>{
      'Новости': _newsFetch,
      'Список изменений': _changelogFetch,
    };

    _newsRepo = NewsRepository(total: totalElements);
    _changelogRepo = ChangelogRepository(total: totalElements);

    _currentTab = _tabs.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _tabs.entries.map<Widget>((tab) {
            return TextButton(
              onPressed: () => setState(() => _currentTab = tab.key),
              child: Text(
                tab.key.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headline4!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _currentTab == tab.key
                          ? Colors.white
                          : Colors.white70,
                    ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: IndexedStack(
            index: _tabs.entries
                .map<String>((tab) => tab.key)
                .toList()
                .indexOf(_currentTab),
            children: _tabs.entries
                .map((tab) => _buildList(context, tab.key, tab.value))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    String tab,
    FetchCallback fetch,
  ) {
    return LazyListView(
      count: totalElements,
      fetch: fetch,
      itemBuilder: (context, index, card) {
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            ListTile(
              title: Text(
                card.title,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headline4!.copyWith(
                      color: Colors.black.withOpacity(0.85),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              trailing: Text(
                card.date != null
                    ? '${card.date!.day}.${card.date!.month}.${card.date!.year}'
                    : '',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headline6!.copyWith(
                      color: Colors.black.withOpacity(0.85),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(color: Colors.black),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Theme(
                  data: ThemeData.light(),
                  child: Markdown(
                    data: card.data ?? '# Данных нет',
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: primaryColor),
                  onPressed: () => _onMarkdownFullScreen(
                      context, card.data ?? '# Данных нет'),
                  child: const Text('Открыть на весь экран'),
                ),
              ),
            )
          ]),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      progressBuilder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

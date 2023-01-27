import 'package:civilization_launcher/repository/news_repository.dart';
import 'package:civilization_launcher/ui/widgets/background_view.dart';
import 'package:civilization_launcher/ui/widgets/lazy_list_view.dart';
import 'package:civilization_launcher/ui/widgets/navigator_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  void _onPlayClick(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundView(
        child: Padding(
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
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 20,
                          ),
                          child: Text(
                            'Играть',
                            style: Theme.of(context)
                                .textTheme
                                .headline4!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _onPlayClick(context),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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

typedef FetchCallback = Future<List<String>> Function();

class _MainNewsState extends State<_MainNewsWidget> {
  late Map<String, FetchCallback> _tabs;

  late NewsRepository _repo;
  late String _currentTab;

  Future<List<String>> newsFetch() async {
    return await _repo.fetch();
  }

  Future<List<String>> changelogFetch() async {
    return await _repo.fetch();
  }

  @override
  void initState() {
    super.initState();

    _tabs = <String, FetchCallback>{
      'Новости': newsFetch,
      'Список изменений': changelogFetch,
    };

    _repo = NewsRepository();
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
      fetch: fetch,
      itemBuilder: (context, index, element) {
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            ListTile(
              title: Text(
                "${tab == 'Новости' ? tab : 'Изменение'} №${index + 1}",
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headline4!.copyWith(
                      color: Colors.black.withOpacity(0.85),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              trailing: Text(
                '21.02.2023',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headline6!.copyWith(
                      color: Colors.black.withOpacity(0.85),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(color: Colors.black),
            ListTile(title: MarkdownBody(data: element)),
            const SizedBox(height: 10),
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

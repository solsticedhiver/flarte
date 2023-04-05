import 'package:flarte/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

class FlarteSettings extends StatefulWidget {
  const FlarteSettings({
    super.key,
  });

  @override
  State<FlarteSettings> createState() => _FlarteSettingsState();
}

class _FlarteSettingsState extends State<FlarteSettings> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode =
        Provider.of<ThemeModeProvider>(context, listen: false).themeMode;
    String tm = '';
    if (themeMode == ThemeMode.dark) {
      tm = 'Dark';
    } else if (themeMode == ThemeMode.light) {
      tm = 'Light';
    } else {
      tm = 'System';
    }

    final Map<String, String> localeName = {
      'fr': 'French',
      'de': 'German',
      'en': 'English',
    };
    Locale? locale = Provider.of<LocaleModel>(context, listen: false).locale;

    debugPrint(AppLocalizations.supportedLocales.toString());
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.strSettings)),
      body: SettingsList(sections: [
        SettingsSection(title: const Text('Interface'), tiles: [
          SettingsTile.navigation(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            value:
                locale != null && localeName.keys.contains(locale.languageCode)
                    ? Text(localeName[locale.languageCode]!)
                    : const Text('System'),
            onPressed: (context) async {
              // test
              await showDialog<ThemeMode>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                        content: StatefulBuilder(builder: (context, setState) {
                      return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: AppLocalizations.supportedLocales.map((l) {
                            return ListTile(
                                title: Text(l.languageCode),
                                leading: Radio<Locale>(
                                  value: l,
                                  groupValue: locale,
                                  onChanged: (value) {
                                    setState(() {
                                      locale = value!;
                                    });
                                  },
                                ));
                          }).toList());
                    }));
                  });
              Provider.of<LocaleModel>(context, listen: false)
                  .changeLocale(locale);
            },
          ),
          SettingsTile.navigation(
            leading: const Icon(Icons.nightlight),
            title: const Text('Theme'),
            value: Text(tm),
            onPressed: (context) async {
              ThemeMode themeMode =
                  Provider.of<ThemeModeProvider>(context, listen: false)
                      .themeMode;
              await showDialog<ThemeMode>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                        content: StatefulBuilder(builder: (context, setState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                              title: const Text('Dark'),
                              leading: Radio<ThemeMode>(
                                value: ThemeMode.dark,
                                groupValue: themeMode,
                                onChanged: (value) {
                                  setState(() {
                                    themeMode = value!;
                                  });
                                },
                              )),
                          ListTile(
                              title: const Text('Light'),
                              leading: Radio<ThemeMode>(
                                value: ThemeMode.light,
                                groupValue: themeMode,
                                onChanged: (value) {
                                  setState(() {
                                    themeMode = value!;
                                  });
                                },
                              )),
                          ListTile(
                              title: const Text('System'),
                              leading: Radio<ThemeMode>(
                                value: ThemeMode.system,
                                groupValue: themeMode,
                                onChanged: (value) {
                                  setState(() {
                                    themeMode = value!;
                                  });
                                },
                              )),
                        ],
                      );
                    }));
                  });
              Provider.of<ThemeModeProvider>(context, listen: false)
                  .changeTheme(themeMode);
            },
          )
        ]),
        SettingsSection(title: const Text('Playback'), tiles: [
          SettingsTile.navigation(
              leading: const Icon(Icons.width_normal),
              title: const Text('Default resolution'),
              value: const Text('432p')),
          SettingsTile.navigation(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Player'),
              value: const Text('Embedded')),
        ]),
        SettingsSection(title: const Text('Downloads'), tiles: [
          SettingsTile(
              leading: const Icon(Icons.download),
              title: const Text('Directory')),
        ])
      ]),
    );
  }
}

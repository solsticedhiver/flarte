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
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.strSettings)),
      body: SettingsList(sections: [
        SettingsSection(title: const Text('Interface'), tiles: [
          SettingsTile.navigation(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            value: const Text('English'),
            onPressed: (context) {
              // test
              Provider.of<LocaleModel>(context, listen: false)
                  .changeLocale(const Locale('en'));
            },
          ),
          SettingsTile.navigation(
              leading: const Icon(Icons.nightlight),
              title: const Text('Theme'),
              value: const Text('Dark'))
        ]),
        SettingsSection(title: const Text('Playback'), tiles: [
          SettingsTile.navigation(
              leading: const Icon(Icons.width_normal),
              title: const Text('Default resolution'),
              value: const Text('432p')),
          SettingsTile.navigation(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Player'),
              value: const Text('Embedded'))
        ]),
      ]),
    );
  }
}

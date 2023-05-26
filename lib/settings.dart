import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flarte/helpers.dart';
import 'package:flarte/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:path/path.dart' as path;

class FlarteSettings extends StatefulWidget {
  const FlarteSettings({
    super.key,
  });

  @override
  State<FlarteSettings> createState() => _FlarteSettingsState();
}

class _FlarteSettingsState extends State<FlarteSettings> {
  PlayerTypeName _playerTypeName = AppConfig.player;
  late String _playerString;
  late String _qualityString;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode =
        Provider.of<ThemeModeProvider>(context, listen: false).themeMode;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> localeName = {
      'fr': AppLocalizations.of(context)!.strFrench,
      'de': AppLocalizations.of(context)!.strGerman,
      'en': AppLocalizations.of(context)!.strEnglish,
      'it': AppLocalizations.of(context)!.strItalian,
      'es': AppLocalizations.of(context)!.strSpanish,
      'pl': AppLocalizations.of(context)!.strPolish,
    };
    final notImplementedLocales = ['it', 'es', 'pl'];
    Locale? locale = Provider.of<LocaleModel>(context, listen: false).locale;

    final Map<ThemeMode, String> themeModeString = {
      ThemeMode.dark: AppLocalizations.of(context)!.strDark,
      ThemeMode.light: AppLocalizations.of(context)!.strLight,
      ThemeMode.system: AppLocalizations.of(context)!.strSystem,
    };

    final Map<PlayerTypeName, String> playerString = {
      PlayerTypeName.custom: AppLocalizations.of(context)!.strCustom,
      PlayerTypeName.vlc: 'VLC',
      PlayerTypeName.embedded: AppLocalizations.of(context)!.strEmbedded,
    };
    _playerString = playerString[_playerTypeName]!;

    final qualityStringList = ['216p', '360p', '432p', '720p', '1080p'];
    int qualityIndex = AppConfig.playerIndexQuality;
    _qualityString = qualityStringList[qualityIndex];

    debugPrint(AppLocalizations.supportedLocales.toString());
    return Scaffold(
      appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              Map<String, dynamic> settings = {
                'locale': Provider.of<LocaleModel>(context, listen: false)
                    .getCurrentLocale(context),
                'theme': _themeMode,
                'quality': qualityIndex,
                'player': _playerTypeName,
              };
              Navigator.of(context).pop(settings);
            },
          ),
          title: Text(AppLocalizations.of(context)!.strSettings)),
      body: SettingsList(sections: [
        SettingsSection(
            title: Text(AppLocalizations.of(context)!.strInterface),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.language),
                title: Text(AppLocalizations.of(context)!.strLanguage),
                value: locale != null &&
                        localeName.keys.contains(locale.languageCode)
                    ? Text(localeName[locale.languageCode]!)
                    : Text(AppLocalizations.of(context)!.strSystem),
                onPressed: (context) async {
                  // test
                  await showDialog<ThemeMode>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(content:
                            StatefulBuilder(builder: (context, setState) {
                          final supportedLocales = AppLocalizations
                                  .supportedLocales +
                              [
                                const Locale.fromSubtags(languageCode: 'it'),
                                const Locale.fromSubtags(languageCode: 'es'),
                                const Locale.fromSubtags(languageCode: 'pl')
                              ];
                          return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: supportedLocales.map((l) {
                                final isSupported = !notImplementedLocales
                                    .contains(l.languageCode);
                                return ListTile(
                                    enabled: isSupported,
                                    title: Text(localeName[l.languageCode]!),
                                    leading: Radio<Locale>(
                                      toggleable: isSupported,
                                      value: l,
                                      groupValue: locale,
                                      onChanged: isSupported
                                          ? (value) {
                                              setState(() {
                                                locale = value!;
                                              });
                                            }
                                          : null,
                                    ));
                              }).toList());
                        }));
                      });
                  if (!context.mounted) return;
                  Provider.of<LocaleModel>(context, listen: false)
                      .changeLocale(locale);
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.nightlight),
                title: Text(AppLocalizations.of(context)!.strTheme),
                value: Text(themeModeString[_themeMode]!),
                onPressed: (context) async {
                  ThemeMode themeMode = _themeMode;
                  await showDialog<ThemeMode>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(content:
                            StatefulBuilder(builder: (context, setState) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                  title: Text(
                                      AppLocalizations.of(context)!.strDark),
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
                                  title: Text(
                                      AppLocalizations.of(context)!.strLight),
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
                                  title: Text(
                                      AppLocalizations.of(context)!.strSystem),
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
                  if (!context.mounted) return;
                  Provider.of<ThemeModeProvider>(context, listen: false)
                      .changeTheme(themeMode);
                  setState(() {
                    _themeMode = themeMode;
                  });
                },
              ),
              SettingsTile.switchTile(
                initialValue: AppConfig.textMode,
                activeSwitchColor: Colors.deepOrange,
                leading: const Icon(Icons.text_fields),
                title: Text(AppLocalizations.of(context)!.strTextMode),
                onToggle: (value) {
                  setState(() {
                    AppConfig.textMode = value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        AppLocalizations.of(context)!
                            .strYouNeedToChangeCategory,
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onInverseSurface)),
                    // showCloseIcon: true,
                    duration: const Duration(seconds: 30),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor:
                        Theme.of(context).colorScheme.inverseSurface,
                    showCloseIcon: true,
                    closeIconColor:
                        Theme.of(context).colorScheme.onInverseSurface,
                  ));
                },
              ),
            ]),
        SettingsSection(
            title: Text(AppLocalizations.of(context)!.strPlayback),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.width_normal),
                title: Text(AppLocalizations.of(context)!.strDefRes),
                value: Text(_qualityString.split(' ').last),
                onPressed: (context) async {
                  await showDialog<int>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(content:
                            StatefulBuilder(builder: (context, setState) {
                          return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: qualityStringList.map((p) {
                                return ListTile(
                                    title: Text(p),
                                    leading: Radio<int>(
                                      value: qualityStringList.indexOf(p),
                                      groupValue: qualityIndex,
                                      onChanged: (value) {
                                        setState(() {
                                          qualityIndex = value!;
                                        });
                                      },
                                    ));
                              }).toList());
                        }));
                      });
                  setState(() {
                    _qualityString = qualityStringList[qualityIndex];
                  });
                  AppConfig.playerIndexQuality = qualityIndex;
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.play_arrow),
                title: Text(AppLocalizations.of(context)!.strPlayer),
                value: Text(_playerString),
                onPressed: (context) async {
                  await showDialog<PlayerTypeName>(
                      context: context,
                      builder: (context) {
                        final Map<PlayerTypeName, Map<String, dynamic>> ptn = {
                          PlayerTypeName.embedded: {
                            'str': AppLocalizations.of(context)!.strEmbedded,
                            'disabled': false
                          },
                          PlayerTypeName.vlc: {
                            'str': 'VLC',
                            // disable VLC choice when in flatpak/snap or android
                            'disabled':
                                Platform.environment['FLATPAK_ID'] != null ||
                                    Platform.environment['SNAP'] != null ||
                                    Platform.isAndroid
                          },
                          PlayerTypeName.custom: {
                            'str': AppLocalizations.of(context)!.strCustom,
                            'disabled': true
                            //Platform.environment['FLATPAK_ID'] != null
                          },
                        };
                        return AlertDialog(content:
                            StatefulBuilder(builder: (context, setState) {
                          return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: ptn.entries.map((p) {
                                return ListTile(
                                    enabled: !p.value['disabled'],
                                    title: Text(p.value['str']),
                                    leading: Radio<PlayerTypeName>(
                                      value: p.key,
                                      groupValue: _playerTypeName,
                                      onChanged: (!p.value['disabled'])
                                          ? (value) {
                                              setState(() {
                                                _playerTypeName = value!;
                                              });
                                            }
                                          : null,
                                    ));
                              }).toList());
                        }));
                      });
                  setState(() {
                    _playerString = playerString[_playerTypeName]!;
                  });
                  AppConfig.player = _playerTypeName;
                },
              ),
            ]),
        SettingsSection(
            title: Text(AppLocalizations.of(context)!.strDownloads),
            tiles: [
              SettingsTile(
                leading: const Icon(Icons.download),
                title: Text(AppLocalizations.of(context)!.strFolder),
                value: Text(AppConfig.dlDirectory),
                enabled: Platform.isLinux || Platform.isWindows,
                onPressed: (context) async {
                  String home = '';
                  if (Platform.isLinux) {
                    home = Platform.environment['HOME'] ??
                        Platform.environment['TMP']!;
                    if (Platform.environment['SNAP'] != null) {
                      home = Platform.environment['SNAP_REAL_HOME']!;
                    }
                  } else if (Platform.isWindows) {
                    home = Platform.environment['USERPROFILE'] ??
                        path.join(Platform.environment['SYSTEMDRIVE']!,
                            'Windows', 'Temp');
                  }
                  if (!mounted) return;
                  String? dlDir = await FilePicker.platform.getDirectoryPath(
                      initialDirectory: home,
                      dialogTitle:
                          AppLocalizations.of(context)!.strChooseDirectory);

                  if (dlDir != null) {
                    setState(() {
                      AppConfig.dlDirectory = dlDir;
                    });
                  }
                },
              ),
            ]),
        SettingsSection(
            title: Text(
                '${AppLocalizations.of(context)!.strAbout} ${AppConfig.name}'),
            tiles: [
              SettingsTile(
                leading: const Icon(Icons.info),
                title: const Text(
                    'version ${AppConfig.version} (${AppConfig.commit})'),
                onPressed: (context) async {
                  // ignore: non_constant_identifier_names
                  String GPL3 =
                      await PlatformAssetBundle().loadString('assets/GPL3.txt');
                  if (!context.mounted) return;
                  showAboutDialog(
                    context: context,
                    applicationIcon: Image.asset('assets/flarte.png',
                        width: 128, height: 128),
                    applicationName: AppConfig.name,
                    applicationVersion:
                        '${AppConfig.version} (${AppConfig.commit})',
                    applicationLegalese:
                        "Copyright © 2023\nsolsTiCe d'Hiver <solstice.dhiver@gmail.com>\nGPL-3+",
                    children: [
                      const SizedBox(height: 10),
                      // ignore: sized_box_for_whitespace
                      Container(width: 600, child: Text(GPL3))
                    ],
                  );
                },
              ),
            ])
      ]),
    );
  }
}

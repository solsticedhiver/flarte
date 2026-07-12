/*
Copyright (C) 2026 solsTiCe d'Hiver

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
*/

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flarte/helpers.dart';
import 'package:flarte/config.dart';
import 'package:flarte/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:path/path.dart' as path;

class FlarteSettings extends StatefulWidget {
  const FlarteSettings({super.key});

  @override
  State<FlarteSettings> createState() => _FlarteSettingsState();
}

class _FlarteSettingsState extends State<FlarteSettings> {
  PlayerTypeName _playerTypeName = AppConfig.player;
  late String _playerString;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = Provider.of<ThemeModeProvider>(
      context,
      listen: false,
    ).themeMode;
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
      'ro': AppLocalizations.of(context)!.strRomanian,
    };
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

    PlayerQuality playerQuality = AppConfig.playerQuality;

    debugPrint(AppLocalizations.supportedLocales.toString());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        leading: BackButton(
          onPressed: () {
            Map<String, dynamic> settings = {
              'locale': Provider.of<LocaleModel>(
                context,
                listen: false,
              ).getCurrentLocale(context),
              'theme': _themeMode,
              'quality': playerQuality,
              'player': _playerTypeName,
            };
            Navigator.of(context).pop(settings);
          },
        ),
        title: Text(AppLocalizations.of(context)!.strSettings),
      ),
      body: SettingsList(
        applicationType: ApplicationType.material,
        sections: [
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
                      return AlertDialog(
                        content: StatefulBuilder(
                          builder: (context, setState) {
                            return RadioGroup<Locale>(
                              groupValue: locale,
                              onChanged: (value) {
                                setState(() {
                                  locale = value!;
                                });
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: AppLocalizations.supportedLocales.map(
                                  (l) {
                                    return RadioListTile<Locale>(
                                      title: Text(localeName[l.languageCode]!),
                                      value: l,
                                    );
                                  },
                                ).toList(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                  if (!context.mounted) return;
                  Provider.of<LocaleModel>(
                    context,
                    listen: false,
                  ).changeLocale(locale);
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
                      return AlertDialog(
                        content: StatefulBuilder(
                          builder: (context, setState) {
                            return RadioGroup<ThemeMode>(
                              groupValue: themeMode,
                              onChanged: (ThemeMode? value) {
                                setState(() {
                                  themeMode = value!;
                                });
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RadioListTile<ThemeMode>(
                                    title: Text(
                                      AppLocalizations.of(context)!.strDark,
                                    ),
                                    value: ThemeMode.dark,
                                  ),
                                  RadioListTile<ThemeMode>(
                                    title: Text(
                                      AppLocalizations.of(context)!.strLight,
                                    ),
                                    value: ThemeMode.light,
                                  ),
                                  RadioListTile<ThemeMode>(
                                    title: Text(
                                      AppLocalizations.of(context)!.strSystem,
                                    ),
                                    value: ThemeMode.system,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                  if (!context.mounted) return;
                  Provider.of<ThemeModeProvider>(
                    context,
                    listen: false,
                  ).changeTheme(themeMode);
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        )!
                            .strYouNeedToChangeCategory,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                        ),
                      ),
                      // showCloseIcon: true,
                      duration: const Duration(seconds: 30),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inverseSurface,
                      showCloseIcon: true,
                      closeIconColor: Theme.of(
                        context,
                      ).colorScheme.onInverseSurface,
                    ),
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text(AppLocalizations.of(context)!.strPlayback),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.width_normal),
                title: Text(AppLocalizations.of(context)!.strDefRes),
                value: Text(playerQuality.name),
                onPressed: (context) async {
                  await showDialog<int>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: StatefulBuilder(
                          builder: (context, setState) {
                            return RadioGroup<PlayerQuality>(
                              groupValue: playerQuality,
                              onChanged: (value) {
                                setState(() {
                                  playerQuality = value!;
                                });
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: PlayerQuality.values.map((p) {
                                  return RadioListTile<PlayerQuality>(
                                    title: Text(p.name),
                                    value: p,
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                  setState(() {
                    AppConfig.playerQuality = playerQuality;
                  });
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
                          'disabled': false,
                        },
                        PlayerTypeName.vlc: {
                          'str': 'VLC',
                          // disable VLC choice when in flatpak/snap or android
                          'disabled': kIsWeb ||
                              Platform.environment['FLATPAK_ID'] != null ||
                              Platform.environment['SNAP'] != null ||
                              Platform.isAndroid,
                        },
                        /*
                          PlayerTypeName.custom: {
                            'str': AppLocalizations.of(context)!.strCustom,
                            'disabled': true
                            //Platform.environment['FLATPAK_ID'] != null
                          },
                          */
                      };
                      return AlertDialog(
                        content: StatefulBuilder(
                          builder: (context, setState) {
                            return RadioGroup<PlayerTypeName>(
                              groupValue: _playerTypeName,
                              onChanged: (value) {
                                setState(() {
                                  _playerTypeName = value!;
                                });
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: ptn.entries.map((p) {
                                  return RadioListTile<PlayerTypeName>(
                                    enabled: !p.value['disabled'],
                                    title: Text(p.value['str']),
                                    value: p.key,
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                  setState(() {
                    _playerString = playerString[_playerTypeName]!;
                  });
                  AppConfig.player = _playerTypeName;
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text(AppLocalizations.of(context)!.strDownloads),
            tiles: [
              SettingsTile(
                leading: const Icon(Icons.download),
                title: Text(AppLocalizations.of(context)!.strFolder),
                value: Text(AppConfig.dlDirectory),
                enabled: !kIsWeb && (Platform.isLinux || Platform.isWindows),
                onPressed: (context) async {
                  String home = '';
                  if (kIsWeb) return;
                  if (Platform.isLinux) {
                    home = Platform.environment['HOME'] ??
                        Platform.environment['TMP']!;
                    if (Platform.environment['SNAP'] != null) {
                      home = Platform.environment['SNAP_REAL_HOME']!;
                    }
                  } else if (Platform.isWindows) {
                    home = Platform.environment['USERPROFILE'] ??
                        path.join(
                          Platform.environment['SYSTEMDRIVE']!,
                          'Windows',
                          'Temp',
                        );
                  }
                  if (!mounted) return;
                  String? dlDir = await FilePicker.getDirectoryPath(
                    initialDirectory: home,
                    dialogTitle: AppLocalizations.of(
                      context,
                    )!
                        .strChooseDirectory,
                  );

                  if (dlDir != null) {
                    setState(() {
                      AppConfig.dlDirectory = dlDir;
                    });
                  }
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text(AppLocalizations.of(context)!.strCache),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.cached),
                title: Text(AppLocalizations.of(context)!.strClearCache),
                onPressed: (context) async {
                  await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                          AppLocalizations.of(context)!.strClearTheCacheNow,
                        ),
                        content: Text(
                          AppLocalizations.of(context)!.strClearingTheCache,
                        ),
                        actions: [
                          TextButton(
                            child: Text(AppLocalizations.of(context)!.strYes),
                            onPressed: () {
                              final cache = Provider.of<Cache>(
                                context,
                                listen: false,
                              );
                              for (var key in cache.data.keys) {
                                final k = key.split('-')[0];
                                if (CategoriesList.codes.contains(k)) {
                                  cache.set(key, null, notify: true);
                                }
                              }
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text(AppLocalizations.of(context)!.strNo),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text(
              '${AppLocalizations.of(context)!.strAbout} ${AppConfig.name}',
            ),
            tiles: [
              SettingsTile(
                leading: const Icon(Icons.info),
                title: const Text(
                  'version ${AppConfig.version} (${AppConfig.commit})',
                ),
                onPressed: (context) async {
                  // ignore: non_constant_identifier_names
                  String GPL3 = await PlatformAssetBundle().loadString(
                    'assets/GPL3.txt',
                  );
                  if (!context.mounted) return;
                  showAboutDialog(
                    context: context,
                    applicationIcon: Image.asset(
                      'assets/flarte.png',
                      width: 128,
                      height: 128,
                    ),
                    applicationName: AppConfig.name,
                    applicationVersion:
                        '${AppConfig.version} (${AppConfig.commit})',
                    applicationLegalese:
                        "Copyright © 2023\nsolsTiCe d'Hiver <solstice.dhiver@gmail.com>\nGPL-3+",
                    children: [
                      const SizedBox(height: 10),
                      // ignore: sized_box_for_whitespace
                      Container(width: 600, child: Text(GPL3)),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

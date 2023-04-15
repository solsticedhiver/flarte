import 'dart:io';

import 'package:flarte/helpers.dart';
import 'package:flarte/config.dart';
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
                          return Column(
                              mainAxisSize: MainAxisSize.min,
                              children:
                                  AppLocalizations.supportedLocales.map((l) {
                                return ListTile(
                                    title: Text(localeName[l.languageCode]!),
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
                  Provider.of<ThemeModeProvider>(context, listen: false)
                      .changeTheme(themeMode);
                  setState(() {
                    _themeMode = themeMode;
                  });
                },
              )
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
                            // disable VLC choice when in flatpak
                            'disabled':
                                Platform.environment['FLATPAK_ID'] != null
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
                title: Text(AppLocalizations.of(context)!.strDirectory),
                value: Text(AppConfig.dlDirectory),
              ),
            ])
      ]),
    );
  }
}

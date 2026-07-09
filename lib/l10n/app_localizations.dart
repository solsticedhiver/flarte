import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_ro.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pl'),
    Locale('ro')
  ];

  /// No description provided for @strHOME.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get strHOME;

  /// No description provided for @strDOR.
  ///
  /// In en, this message translates to:
  /// **'Documentaries'**
  String get strDOR;

  /// No description provided for @strSER.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get strSER;

  /// No description provided for @strCIN.
  ///
  /// In en, this message translates to:
  /// **'Cinema'**
  String get strCIN;

  /// No description provided for @strEMI.
  ///
  /// In en, this message translates to:
  /// **'Magazines and Shows'**
  String get strEMI;

  /// No description provided for @strHIS.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get strHIS;

  /// No description provided for @strDEC.
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get strDEC;

  /// No description provided for @strSCI.
  ///
  /// In en, this message translates to:
  /// **'Sciences'**
  String get strSCI;

  /// No description provided for @strACT.
  ///
  /// In en, this message translates to:
  /// **'Politics and Society'**
  String get strACT;

  /// No description provided for @strCPO.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get strCPO;

  /// No description provided for @strSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get strSettings;

  /// No description provided for @strFetching.
  ///
  /// In en, this message translates to:
  /// **'Fetching data ...'**
  String get strFetching;

  /// No description provided for @strEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get strEpisodes;

  /// No description provided for @strClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get strClose;

  /// No description provided for @strInterface.
  ///
  /// In en, this message translates to:
  /// **'Interface'**
  String get strInterface;

  /// No description provided for @strLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get strLanguage;

  /// No description provided for @strSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get strSystem;

  /// No description provided for @strTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get strTheme;

  /// No description provided for @strDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get strDark;

  /// No description provided for @strLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get strLight;

  /// No description provided for @strPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get strPlayback;

  /// No description provided for @strDefRes.
  ///
  /// In en, this message translates to:
  /// **'Preferred resolution'**
  String get strDefRes;

  /// No description provided for @strPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get strPlayer;

  /// No description provided for @strDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get strDownloads;

  /// No description provided for @strDirectory.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get strDirectory;

  /// No description provided for @strFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get strFolder;

  /// No description provided for @strEmbedded.
  ///
  /// In en, this message translates to:
  /// **'Embedded'**
  String get strEmbedded;

  /// No description provided for @strFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get strFrench;

  /// No description provided for @strEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get strEnglish;

  /// No description provided for @strGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get strGerman;

  /// No description provided for @strCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get strCustom;

  /// No description provided for @strCopiedClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get strCopiedClipboard;

  /// No description provided for @strDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get strDuration;

  /// No description provided for @strAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get strAvailability;

  /// No description provided for @strGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get strGenre;

  /// No description provided for @strDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get strDetails;

  /// No description provided for @strFrom.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get strFrom;

  /// No description provided for @strTo.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get strTo;

  /// No description provided for @strFirstBroadcastDate.
  ///
  /// In en, this message translates to:
  /// **'First broadcast date'**
  String get strFirstBroadcastDate;

  /// No description provided for @strNothingDisplay.
  ///
  /// In en, this message translates to:
  /// **'Nothing to display'**
  String get strNothingDisplay;

  /// No description provided for @strSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get strSearch;

  /// No description provided for @strNotImpl.
  ///
  /// In en, this message translates to:
  /// **'Not implemented yet'**
  String get strNotImpl;

  /// No description provided for @strSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get strSubmit;

  /// No description provided for @strSearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Search terms'**
  String get strSearchTerms;

  /// No description provided for @strResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get strResults;

  /// No description provided for @strItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get strItalian;

  /// No description provided for @strSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get strSpanish;

  /// No description provided for @strPolish.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get strPolish;

  /// No description provided for @strNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get strNoResults;

  /// No description provided for @strAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get strAbout;

  /// No description provided for @strError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get strError;

  /// No description provided for @strTextMode.
  ///
  /// In en, this message translates to:
  /// **'Text Mode'**
  String get strTextMode;

  /// No description provided for @strYouNeedToChangeCategory.
  ///
  /// In en, this message translates to:
  /// **'You will need to navigate to a new category for the change to be visible'**
  String get strYouNeedToChangeCategory;

  /// No description provided for @strDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get strDownload;

  /// No description provided for @strPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get strPlay;

  /// No description provided for @strURL.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get strURL;

  /// No description provided for @strMore.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get strMore;

  /// No description provided for @strChooseDirectory.
  ///
  /// In en, this message translates to:
  /// **'Choose a directory where to save videos'**
  String get strChooseDirectory;

  /// No description provided for @strInitStream.
  ///
  /// In en, this message translates to:
  /// **'Initializing stream'**
  String get strInitStream;

  /// No description provided for @strCache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get strCache;

  /// No description provided for @strClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear the cache'**
  String get strClearCache;

  /// No description provided for @strClearTheCacheNow.
  ///
  /// In en, this message translates to:
  /// **'Do you want to clear the cache now?'**
  String get strClearTheCacheNow;

  /// No description provided for @strClearingTheCache.
  ///
  /// In en, this message translates to:
  /// **'Clearing the cache will force to refresh each screen section (or tab)\nThis does not include the images or the details about a program'**
  String get strClearingTheCache;

  /// No description provided for @strYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get strYes;

  /// No description provided for @strNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get strNo;

  /// No description provided for @strAgeRating.
  ///
  /// In en, this message translates to:
  /// **'Age Rating'**
  String get strAgeRating;

  /// No description provided for @strViewable.
  ///
  /// In en, this message translates to:
  /// **'Viewable'**
  String get strViewable;

  /// No description provided for @strYouAreAboutToWatch.
  ///
  /// In en, this message translates to:
  /// **'The program you are about to watch contains scenes not recommended for young or sensitive audiences.'**
  String get strYouAreAboutToWatch;

  /// No description provided for @strCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get strCancel;

  /// No description provided for @strContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get strContinue;

  /// No description provided for @strWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get strWarning;

  /// No description provided for @strNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get strNone;

  /// No description provided for @strRomanian.
  ///
  /// In en, this message translates to:
  /// **'Romanian'**
  String get strRomanian;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'it',
        'pl',
        'ro'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pl':
      return AppLocalizationsPl();
    case 'ro':
      return AppLocalizationsRo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

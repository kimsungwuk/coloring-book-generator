import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

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
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'My Coloring Book'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'My Coloring Book'**
  String get homeTitle;

  /// No description provided for @coloringTitle.
  ///
  /// In en, this message translates to:
  /// **'Coloring Fun'**
  String get coloringTitle;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get splashLoading;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved!'**
  String get saved;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get saveError;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @exitTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitTitle;

  /// No description provided for @exitMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to exit the app?'**
  String get exitMessage;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required to save images'**
  String get storagePermissionRequired;

  /// No description provided for @colorPalette.
  ///
  /// In en, this message translates to:
  /// **'Color Palette'**
  String get colorPalette;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select a color'**
  String get selectColor;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get zoomOut;

  /// No description provided for @tapToColor.
  ///
  /// In en, this message translates to:
  /// **'Tap to color!'**
  String get tapToColor;

  /// No description provided for @imageSavedToGallery.
  ///
  /// In en, this message translates to:
  /// **'Image saved to gallery!'**
  String get imageSavedToGallery;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Color!'**
  String get welcomeMessage;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a category and start your creative journey'**
  String get welcomeSubtitle;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @categoryForest.
  ///
  /// In en, this message translates to:
  /// **'Forest Friends'**
  String get categoryForest;

  /// No description provided for @categoryOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean Adventure'**
  String get categoryOcean;

  /// No description provided for @categoryFairy.
  ///
  /// In en, this message translates to:
  /// **'Fairyland'**
  String get categoryFairy;

  /// No description provided for @categoryVehicles.
  ///
  /// In en, this message translates to:
  /// **'Move & Zoom'**
  String get categoryVehicles;

  /// No description provided for @categoryDinosaurs.
  ///
  /// In en, this message translates to:
  /// **'Dino World'**
  String get categoryDinosaurs;

  /// No description provided for @categoryDesserts.
  ///
  /// In en, this message translates to:
  /// **'Sweet Treats'**
  String get categoryDesserts;

  /// No description provided for @continueDrawing.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueDrawing;

  /// No description provided for @noPages.
  ///
  /// In en, this message translates to:
  /// **'No pages found'**
  String get noPages;

  /// No description provided for @saveProgress.
  ///
  /// In en, this message translates to:
  /// **'Save Progress'**
  String get saveProgress;

  /// No description provided for @saveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to Gallery'**
  String get saveToGallery;

  /// No description provided for @saveProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Progress?'**
  String get saveProgressTitle;

  /// No description provided for @saveProgressMessage.
  ///
  /// In en, this message translates to:
  /// **'Would you like to save your progress before leaving?'**
  String get saveProgressMessage;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @progressSaved.
  ///
  /// In en, this message translates to:
  /// **'Progress saved!'**
  String get progressSaved;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get selectLanguage;

  /// No description provided for @lockedPage.
  ///
  /// In en, this message translates to:
  /// **'Locked Page'**
  String get lockedPage;

  /// No description provided for @watchAdToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Watch a short video to unlock this coloring page!'**
  String get watchAdToUnlock;

  /// No description provided for @adDuration.
  ///
  /// In en, this message translates to:
  /// **'About 30 seconds · Unlock forever'**
  String get adDuration;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get watchAd;

  /// No description provided for @setAsWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Set as Wallpaper'**
  String get setAsWallpaper;

  /// No description provided for @settingWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Setting wallpaper...'**
  String get settingWallpaper;

  /// No description provided for @wallpaperSetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper set successfully!'**
  String get wallpaperSetSuccess;

  /// No description provided for @wallpaperSetError.
  ///
  /// In en, this message translates to:
  /// **'Failed to set wallpaper'**
  String get wallpaperSetError;

  /// No description provided for @wallpaperAdTitle.
  ///
  /// In en, this message translates to:
  /// **'Set as Wallpaper'**
  String get wallpaperAdTitle;

  /// No description provided for @wallpaperAdMessage.
  ///
  /// In en, this message translates to:
  /// **'Would you like to watch a short video to set this masterpiece as your wallpaper?'**
  String get wallpaperAdMessage;

  /// No description provided for @pickColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a Color'**
  String get pickColor;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Plant Health';

  @override
  String get home => 'Home';

  @override
  String get weather => 'Weather';

  @override
  String get diagnosis => 'Diagnosis';

  @override
  String get map => 'Map';

  @override
  String get settings => 'Settings';

  @override
  String get info => 'Info';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get gallery => 'Gallery';

  @override
  String get riskHigh => 'High Risk';

  @override
  String get riskMedium => 'Medium Risk';

  @override
  String get riskLow => 'Low Risk';

  @override
  String get loading => 'Loading...';

  @override
  String get theme => 'Dark Theme';

  @override
  String get language => 'Language';

  @override
  String get notRecognized =>
      'Plant could not be recognized. Please take a clearer, closer photo of a single leaf.';

  @override
  String get predictionError =>
      'Image could not be analyzed. Please try again.';
}

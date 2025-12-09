import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// A custom localizations delegate to override the month format in Cupertino pickers.
class _NumericMonthCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const _NumericMonthCupertinoLocalizations();

  @override
  String datePickerMonth(int monthIndex) {
    // Return numeric month, e.g., "1月", "2月", ...
    return '$monthIndex月';
  }
}

class NumericMonthCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const NumericMonthCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'zh';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(const _NumericMonthCupertinoLocalizations());

  @override
  bool shouldReload(NumericMonthCupertinoLocalizationsDelegate old) => false;
}

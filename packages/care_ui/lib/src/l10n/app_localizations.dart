import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

/// Localised strings for the two apps.
///
/// The English copy stays in the widgets as the source text. [t] looks that
/// text up in the Bahasa Indonesia dictionary, so a missing entry falls back to
/// English instead of showing a technical key. Entries containing `{name}`
/// placeholders are matched as templates so interpolated sentences are
/// translated too. (FR-CS-3, FR-CM-3)
class AppLocalizations {
  AppLocalizations._(this.languageCode, this._messages, this._templates);

  static const delegate = _AppLocalizationsDelegate();

  /// The languages the apps offer. English is the P1 default.
  static const supportedLocales = <Locale>[Locale('en'), Locale('id')];

  static AppLocalizations? _indonesian;

  final String languageCode;
  final Map<String, String> _messages;
  final List<_TranslationTemplate> _templates;

  static AppLocalizations? maybeOf(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static AppLocalizations of(BuildContext context) {
    return maybeOf(context) ?? english;
  }

  static final AppLocalizations english =
      AppLocalizations._('en', const <String, String>{}, const []);

  static Future<AppLocalizations> load(Locale locale) async {
    if (locale.languageCode != 'id') {
      return english;
    }
    final cached = _indonesian;
    if (cached != null) {
      return cached;
    }
    final raw = await rootBundle
        .loadString('packages/care_ui/assets/i18n/id.json');
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final messages = <String, String>{
      for (final entry in decoded.entries)
        if (entry.value is String) entry.key: entry.value as String,
    };
    final templates = <_TranslationTemplate>[];
    for (final entry in messages.entries) {
      if (!entry.key.contains('{')) {
        continue;
      }
      final template = _TranslationTemplate.tryBuild(entry.key, entry.value);
      if (template != null) {
        templates.add(template);
      }
    }
    // Longer literals win, so "Photo 2" is not caught by a shorter pattern.
    templates.sort((a, b) => b.literalLength.compareTo(a.literalLength));
    return _indonesian =
        AppLocalizations._('id', messages, List.unmodifiable(templates));
  }

  String t(String source) {
    if (languageCode != 'id' || source.isEmpty) {
      return source;
    }
    final direct = _messages[source];
    if (direct != null) {
      return direct;
    }
    for (final template in _templates) {
      final match = template.pattern.firstMatch(source);
      if (match != null) {
        var group = 1;
        final translated = template.translation.replaceAllMapped(
          RegExp(r'\{[^}]+\}'),
          (placeholder) {
            if (group > match.groupCount) {
              return placeholder.group(0)!;
            }
            return match.group(group++) ?? '';
          },
        );
        // A captured value can be a status or a date, for example
        // "Ongoing: Completed", so run the dynamic pass over the result too.
        return _translateDynamic(translated);
      }
    }
    return _translateDynamic(source);
  }

  /// Last resort for sentences built around a status label or a date, for
  /// example "Completed · 12 Oct 2026". Whole phrases only, so a person's
  /// name is never rewritten.
  String _translateDynamic(String source) {
    var result = source;
    for (final phrase in _phrases.entries) {
      final pattern = RegExp(
        '(?<![A-Za-z])${RegExp.escape(phrase.key)}(?![A-Za-z])',
      );
      result = result.replaceAll(pattern, phrase.value);
    }
    // Dates are built as "12 Oct 2026", so only translate a month when it sits
    // between a day and a year. This keeps words like "May" untouched.
    return result.replaceAllMapped(_datePattern, (match) {
      final month = _months[match.group(2)];
      return month == null
          ? match.group(0)!
          : '${match.group(1)}$month${match.group(3)}';
    });
  }

  static final RegExp _datePattern = RegExp(
    r'(\d{1,2} )(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)( \d{4}\b)',
  );

  static const Map<String, String> _months = <String, String>{
    'Jan': 'Jan',
    'Feb': 'Feb',
    'Mar': 'Mar',
    'Apr': 'Apr',
    'May': 'Mei',
    'Jun': 'Jun',
    'Jul': 'Jul',
    'Aug': 'Agu',
    'Sep': 'Sep',
    'Oct': 'Okt',
    'Nov': 'Nov',
    'Dec': 'Des',
  };

  static const Map<String, String> _phrases = <String, String>{
    'Care seeker': 'Pencari layanan',
    'care seeker': 'pencari layanan',
    'Caregiver': 'Pendamping',
    'caregiver': 'pendamping',
    'Completed': 'Selesai',
    'Accepted': 'Diterima',
    'Declined': 'Ditolak',
    'Cancelled': 'Dibatalkan',
    'Pending': 'Tertunda',
    'Paid': 'Dibayar',
    'Refunded': 'Dana dikembalikan',
    'On the way': 'Dalam perjalanan',
    'Arrived': 'Tiba',
    'In progress': 'Berlangsung',
    'Available': 'Tersedia',
    'Unavailable': 'Tidak tersedia',
  };
}

/// Translates copy that is not rendered by [AppText], for example an input
/// hint or a tooltip. Falls back to English when no delegate is installed.
String trText(BuildContext context, String source) {
  return AppLocalizations.maybeOf(context)?.t(source) ?? source;
}

class _TranslationTemplate {
  _TranslationTemplate(this.pattern, this.translation, this.literalLength);

  final RegExp pattern;
  final String translation;
  final int literalLength;

  static final RegExp _placeholder = RegExp(r'\{[^}]+\}');

  static _TranslationTemplate? tryBuild(String source, String translation) {
    final matches = _placeholder.allMatches(source).toList();
    if (matches.isEmpty) {
      return null;
    }
    final buffer = StringBuffer('^');
    var cursor = 0;
    var literalLength = 0;
    for (final match in matches) {
      final literal = source.substring(cursor, match.start);
      buffer
        ..write(RegExp.escape(literal))
        ..write('(.+?)');
      literalLength += literal.length;
      cursor = match.end;
    }
    buffer
      ..write(RegExp.escape(source.substring(cursor)))
      ..write(r'$');
    return _TranslationTemplate(
      RegExp(buffer.toString(), dotAll: true),
      translation,
      literalLength,
    );
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any(
        (supported) => supported.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) {
    if (locale.languageCode == 'en') {
      return SynchronousFuture(AppLocalizations.english);
    }
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}

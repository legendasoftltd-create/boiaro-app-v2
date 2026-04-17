import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class FFLocalizations {
  FFLocalizations(this.locale);

  final Locale locale;

  static FFLocalizations of(BuildContext context) {
    return Localizations.of<FFLocalizations>(context, FFLocalizations)!;
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'profile_title': 'Profile',
      'name_default': 'Name',
      'my_profile': 'My profile',
      'favourite': 'Favourite',
      'my_books': 'My Books',
      'download': 'Download',
      'subscription': 'Subscription',
      'dark_mode': 'Dark Mode',
      'settings': 'Settings',
      'log_out': 'Log out',
      'sign_in': 'Sign in',
      'coming_soon': 'Coming soon!',
      'message': 'Message',
      'change_password': 'Change password',
      'privacy_policy': 'Privacy policy',
      'terms_condition': 'Terms & condition',
      'about_us': 'About us',
      'delete_account': 'Delete account',
      'language': 'Language',
      'nav_home': 'Home',
      'nav_categories': 'Categories',
      'nav_latest': 'Latest',
      'nav_author': 'Author',
      'nav_publisher': 'Publisher',
      'nav_profile': 'Profile',
      'search_hint': 'Search',
      'continue_reading': 'Continue Reading',
      'continue_reading_desc': 'Pick up where you left off',
      'continue_reading_signin_hint':
          'Sign in to sync your reading progress across devices.',
      'page': 'Page',
      'of': 'of',
      'categories_title': 'Browse by category',
      'view_all': 'View all',
      'new_books_title': 'New on BoiAro',
      'trending_books_title': 'Trending',
      'best_authors_title': 'Author Spotlight',
      'popular_books_title': 'Popular Books',
      'featured_narrators_title': 'Featured Narrators',
      'home_app_promo_title': 'Your library, always with you',
      'home_app_promo_body':
          'Read offline, sync progress, and enjoy premium audiobooks — same spirit as boiarov2.blocknots.com.',
    },
    'bn': {
      'profile_title': 'প্রোফাইল',
      'name_default': 'নাম',
      'my_profile': 'আমার প্রোফাইল',
      'favourite': 'প্রিয়',
      'my_books': 'আমার বই',
      'download': 'ডাউনলোড',
      'subscription': 'সাবস্ক্রিপশন',
      'dark_mode': 'ডার্ক মোড',
      'settings': 'সেটিংস',
      'log_out': 'লগ আউট',
      'sign_in': 'সাইন ইন',
      'coming_soon': 'শীঘ্রই আসছে!',
      'message': 'বার্তা',
      'change_password': 'পাসওয়ার্ড পরিবর্তন',
      'privacy_policy': 'গোপনীয়তা নীতি',
      'terms_condition': 'শর্তাবলী',
      'about_us': 'আমাদের সম্পর্কে',
      'delete_account': 'অ্যাকাউন্ট মুছুন',
      'language': 'ভাষা',
      'nav_home': 'হোম',
      'nav_categories': 'ক্যাটাগরি',
      'nav_latest': 'সর্বশেষ',
      'nav_author': 'লেখক',
      'nav_publisher': 'প্রকাশক',
      'nav_profile': 'প্রোফাইল',
      'search_hint': 'অনুসন্ধান করুন',
      'continue_reading': 'পড়া চালিয়ে যান',
      'continue_reading_desc': 'যেখানে থেমেছিলেন সেখান থেকে শুরু করুন',
      'continue_reading_signin_hint':
          'ডিভাইস জুড়ে পড়ার অগ্রগতি সিঙ্ক করতে সাইন ইন করুন।',
      'page': 'পৃষ্ঠা',
      'of': 'এর',
      'categories_title': 'ক্যাটাগরি অনুসারে ব্রাউজ',
      'view_all': 'সব দেখুন',
      'new_books_title': 'নতুন প্রকাশ',
      'trending_books_title': 'ট্রেন্ডিং',
      'best_authors_title': 'লেখক স্পটলাইট',
      'popular_books_title': 'জনপ্রিয় বই',
      'featured_narrators_title': 'বাছাইকৃত বর্ণনাকারী',
      'home_app_promo_title': 'আপনার লাইব্রেরি, সবসময় সাথে',
      'home_app_promo_body':
          'অফলাইনে পড়ুন, অগ্রগতি সিঙ্ক করুন এবং প্রিমিয়াম অডিওবুক উপভোগ করুন।',
    },
  };

  String getText(String key) {
    return _localizedValues[locale.languageCode]![key] ?? key;
  }

  String getVariableText({
    String? enText = '',
    String? bnText = '',
  }) {
    return locale.languageCode == 'bn' ? bnText ?? '' : enText ?? '';
  }
}

class FFLocalizationsDelegate extends LocalizationsDelegate<FFLocalizations> {
  const FFLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'bn'].contains(locale.languageCode);

  @override
  Future<FFLocalizations> load(Locale locale) =>
      SynchronousFuture<FFLocalizations>(FFLocalizations(locale));

  @override
  bool shouldReload(FFLocalizationsDelegate old) => false;
}

Locale createLocale(String language) => language.contains('_')
    ? Locale.fromSubtags(
        languageCode: language.split('_').first,
        scriptCode: language.split('_').last,
      )
    : Locale(language);

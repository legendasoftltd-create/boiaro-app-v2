import 'package:a_i_ebook_app/custom_code/widgets/app_update.dart';
import 'package:a_i_ebook_app/pages/audiobook_pages/audiobook_page/audiobook_page_widget.dart';
import 'package:a_i_ebook_app/services/presence_tracking_service.dart';

import '/custom_code/actions/index.dart' as actions;
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:device_preview/device_preview.dart';
import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import 'index.dart';
import '/providers/cart_provider.dart';
import '/providers/pdf_viewer_provider.dart';
import 'custom_code/ad_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  final appState = FFAppState(); // Initialize FFAppState
  await appState.initilizePrefs();
  await AdManager.initialize();
  usePathUrlStrategy();

  await initFirebase();

  // Start initial custom actions code
  await actions.connected();
  await actions.firebaseInit();
  await actions.notificationPermission();
  await actions.notificationInit();
  // End initial custom actions code

  await appState.initializePersistedState();
  AppUpdateUtils.checkForUpdate();


  runApp(
    DevicePreview(
      enabled: kDebugMode,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => appState),
          ChangeNotifierProvider(create: (context) => CartProvider()),
          ChangeNotifierProvider(create: (context) => PdfViewerProvider()),
        ],
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class MyAppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e as RouteMatch?))
          .toList();

  @override
  void initState() {
    super.initState();
    PresenceTrackingService.instance.init();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_language');
    if (savedLang != null) {
      safeSetState(() => _locale = createLocale(savedLang));
    }
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
      });

  void setLocale(String language) async {
    safeSetState(() => _locale = createLocale(language));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', language);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // Use DevicePreview's locale and builder in debug mode
      locale: DevicePreview.locale(context) ?? _locale,
      builder: (context, child) {
        return Listener(
          onPointerDown: (_) {
            PresenceTrackingService.instance.recordInteraction();
          },
          behavior: HitTestBehavior.translucent,
          child: DevicePreview.appBuilder(context, child),
        );
      },
      debugShowCheckedModeBanner: false,
      title: 'Boi Aro',
      scrollBehavior: MyAppScrollBehavior(),
      localizationsDelegates: [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('bn', ''),
      ],
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}

class NavBarPage extends StatefulWidget {
  NavBarPage({
    Key? key,
    this.initialPage,
    this.page,
    this.disableResizeToAvoidBottomInset = false,
  }) : super(key: key);

  final String? initialPage;
  final Widget? page;
  final bool disableResizeToAvoidBottomInset;

  @override
  _NavBarPageState createState() => _NavBarPageState();
}

/// This is the private State class that goes with NavBarPage.
class _NavBarPageState extends State<NavBarPage> {
  String _currentPageName = 'HomePage';
  late Widget? _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = {
      'HomePage': HomePageWidget(),
      'CategoriesScreen': CategoriesScreenWidget(),
      'AudiobookPage': AudiobookPageWidget(),
      'LibraryPage': PurchaseHistoryPageWidget(),
      'ProfilePage': ProfilePageWidget(),
    };
    final currentIndex = tabs.keys.toList().indexOf(_currentPageName);

    return Scaffold(
      resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
      body: _currentPage ?? tabs[_currentPageName],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => safeSetState(() {
          _currentPage = null;
          _currentPageName = tabs.keys.toList()[i];
        }),
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        selectedItemColor: FlutterFlowTheme.of(context).primary,
        unselectedItemColor: FlutterFlowTheme.of(context).secondaryText,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),

        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              FFIcons.kgroup26086143,
              size: 24.0,
            ),
            activeIcon: Icon(
              FFIcons.kicon7,
              size: 24.0,
            ),
            label: FFLocalizations.of(context).getText('nav_home'),
            tooltip: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              FFIcons.kgroup260861433,
              size: 24.0,
            ),
            activeIcon: Icon(
              FFIcons.kicon5,
              size: 24.0,
            ),
            label: FFLocalizations.of(context).getText('nav_categories'),
            tooltip: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.headphones_outlined,
              size: 24.0,
            ),
            activeIcon: Icon(
              Icons.headphones_rounded,
              size: 24.0,
            ),
            label: 'AudioBooks',
            tooltip: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.local_library_outlined,
              size: 24.0,
            ),
            activeIcon: Icon(
              Icons.local_library_rounded,
              size: 24.0,
            ),
            label: 'Library',
            tooltip: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.menu_rounded,
              size: 24.0,
            ),
            activeIcon: Icon(
              Icons.menu_open_rounded,
              size: 24.0,
            ),
            label: 'More',
            tooltip: '',
          ),
        ],
      ),
    );
  }
}

// - `auto_size_text`


// - `currency_symbols`

// - `easy_debounce`

// - `equatable`

// - `fluttertoast`

// - `from_css_color`

// - `json_path`

// - `mime_type`

// - `page_transition`

// - `percent_indicator`

// - `readmore`

// - `smooth_page_indicator`

// - `timeago` (can be replaced by `intl` which is already there)

// - `flutter_rating_bar` (can be custom built)

// - `pin_code_fields` (can be custom built)

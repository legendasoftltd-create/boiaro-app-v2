import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';

import '/main.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  bool showSplashImage = true;

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) => SplashPageWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => SplashPageWidget(),
        ),
        FFRoute(
          name: HomePageWidget.routeName,
          path: HomePageWidget.routePath,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'HomePage')
              : HomePageWidget(),
        ),
        FFRoute(
          name: SplashPageWidget.routeName,
          path: SplashPageWidget.routePath,
          builder: (context, params) => SplashPageWidget(),
        ),
        FFRoute(
          name: OnboardingPageWidget.routeName,
          path: OnboardingPageWidget.routePath,
          builder: (context, params) => OnboardingPageWidget(),
        ),
        FFRoute(
          name: SignInPageWidget.routeName,
          path: SignInPageWidget.routePath,
          builder: (context, params) => SignInPageWidget(),
        ),
        FFRoute(
          name: SignUpPageWidget.routeName,
          path: SignUpPageWidget.routePath,
          builder: (context, params) => SignUpPageWidget(),
        ),
        FFRoute(
          name: CategoriesScreenWidget.routeName,
          path: CategoriesScreenWidget.routePath,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'CategoriesScreen')
              : CategoriesScreenWidget(),
        ),
        FFRoute(
          name: SubCategoriesScreenWidget.routeName,
          path: SubCategoriesScreenWidget.routePath,
          builder: (context, params) => SubCategoriesScreenWidget(
            id: params.getParam(
              'id',
              ParamType.String,
            ),
            name: params.getParam(
              'name',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: HistoryDetailsPageWidget.routeName,
          path: HistoryDetailsPageWidget.routePath,
          builder: (context, params) => HistoryDetailsPageWidget(
            name: params.getParam(
              'name',
              ParamType.String,
            ),
            id: params.getParam(
              'id',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: TrendingBooksPageWidget.routeName,
          path: TrendingBooksPageWidget.routePath,
          builder: (context, params) => TrendingBooksPageWidget(),
        ),
        FFRoute(
          name: FilterPageWidget.routeName,
          path: FilterPageWidget.routePath,
          builder: (context, params) => FilterPageWidget(),
        ),
        FFRoute(
          name: BestAuthorPageWidget.routeName,
          path: BestAuthorPageWidget.routePath,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'BestAuthorPage')
              : BestAuthorPageWidget(),
        ),
        FFRoute(
          name: PopularBooksPageWidget.routeName,
          path: PopularBooksPageWidget.routePath,
          builder: (context, params) => PopularBooksPageWidget(),
        ),
        FFRoute(
          name: RecentReviewsPageWidget.routeName,
          path: RecentReviewsPageWidget.routePath,
          builder: (context, params) => RecentReviewsPageWidget(
            reviewId: params.getParam(
              'reviewId',
              ParamType.String,
            ),
            bookId: params.getParam(
              'bookId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: AboutAuthorPageWidget.routeName,
          path: AboutAuthorPageWidget.routePath,
          builder: (context, params) => AboutAuthorPageWidget(
            name: params.getParam(
              'name',
              ParamType.String,
            ),
            authorImage: params.getParam(
              'authorImage',
              ParamType.String,
            ),
            authorId: params.getParam(
              'authorId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ReadBookPageWidget.routeName,
          path: ReadBookPageWidget.routePath,
          builder: (context, params) => ReadBookPageWidget(
            pdf: params.getParam(
              'pdf',
              ParamType.String,
            ),
            id: params.getParam(
              'id',
              ParamType.String,
            ),
            name: params.getParam(
              'name',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: SearchPageWidget.routeName,
          path: SearchPageWidget.routePath,
          builder: (context, params) => SearchPageWidget(),
        ),
        FFRoute(
          name: NotificationsPageWidget.routeName,
          path: NotificationsPageWidget.routePath,
          builder: (context, params) => NotificationsPageWidget(),
        ),
        FFRoute(
          name: LatestPageWidget.routeName,
          path: LatestPageWidget.routePath,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'LatestPage')
              : LatestPageWidget(),
        ),
        FFRoute(
          name: FavouritePageWidget.routeName,
          path: FavouritePageWidget.routePath,
          builder: (context, params) => FavouritePageWidget(),
        ),
        FFRoute(
          name: ProfilePageWidget.routeName,
          path: ProfilePageWidget.routePath,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'ProfilePage')
              : ProfilePageWidget(),
        ),
        FFRoute(
          name: MyProfilePageWidget.routeName,
          path: MyProfilePageWidget.routePath,
          builder: (context, params) => MyProfilePageWidget(),
        ),
        FFRoute(
          name: EditProfilePageWidget.routeName,
          path: EditProfilePageWidget.routePath,
          builder: (context, params) => EditProfilePageWidget(),
        ),
        FFRoute(
          name: DownloadPageWidget.routeName,
          path: DownloadPageWidget.routePath,
          builder: (context, params) => DownloadPageWidget(),
        ),
        FFRoute(
          name: SettingsPageWidget.routeName,
          path: SettingsPageWidget.routePath,
          builder: (context, params) => SettingsPageWidget(),
        ),
        FFRoute(
          name: ChangePasswordPageWidget.routeName,
          path: ChangePasswordPageWidget.routePath,
          builder: (context, params) => ChangePasswordPageWidget(),
        ),
        FFRoute(
          name: PrivacyPolicyPageWidget.routeName,
          path: PrivacyPolicyPageWidget.routePath,
          builder: (context, params) => PrivacyPolicyPageWidget(),
        ),
        FFRoute(
          name: TermsConditionsPageWidget.routeName,
          path: TermsConditionsPageWidget.routePath,
          builder: (context, params) => TermsConditionsPageWidget(),
        ),
        FFRoute(
          name: AboutUsPageWidget.routeName,
          path: AboutUsPageWidget.routePath,
          builder: (context, params) => AboutUsPageWidget(),
        ),
        FFRoute(
          name: BookDetailspageWidget.routeName,
          path: BookDetailspageWidget.routePath,
          builder: (context, params) => BookDetailspageWidget(
            name: params.getParam(
              'name',
              ParamType.String,
            ),
            image: params.getParam(
              'image',
              ParamType.String,
            ),
            id: params.getParam(
              'id',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ForgotpasswordPageWidget.routeName,
          path: ForgotpasswordPageWidget.routePath,
          builder: (context, params) => ForgotpasswordPageWidget(),
        ),
        FFRoute(
          name: VerificationPageWidget.routeName,
          path: VerificationPageWidget.routePath,
          builder: (context, params) => VerificationPageWidget(
            email: params.getParam(
              'email',
              ParamType.String,
            ),
            firstname: params.getParam(
              'firstname',
              ParamType.String,
            ),
            lastname: params.getParam(
              'lastname',
              ParamType.String,
            ),
            username: params.getParam(
              'username',
              ParamType.String,
            ),
            password: params.getParam(
              'password',
              ParamType.String,
            ),
            phone: params.getParam(
              'phone',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ResetPasswordPageWidget.routeName,
          path: ResetPasswordPageWidget.routePath,
          builder: (context, params) => ResetPasswordPageWidget(
            email: params.getParam(
              'email',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ForgotVerificationPageWidget.routeName,
          path: ForgotVerificationPageWidget.routePath,
          builder: (context, params) => ForgotVerificationPageWidget(
            email: params.getParam(
              'email',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: DeleteAccountInstructionPageWidget.routeName,
          path: DeleteAccountInstructionPageWidget.routePath,
          builder: (context, params) => DeleteAccountInstructionPageWidget(),
        ),
        FFRoute(
          name: GetBookByCategoryPageWidget.routeName,
          path: GetBookByCategoryPageWidget.routePath,
          builder: (context, params) => GetBookByCategoryPageWidget(
            name: params.getParam(
              'name',
              ParamType.String,
            ),
            id: params.getParam(
              'id',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: SubscriptionPageWidget.routeName,
          path: SubscriptionPageWidget.routePath,
          builder: (context, params) => SubscriptionPageWidget(),
        ),
        FFRoute(
          name: ReadBookCustomPageWidget.routeName,
          path: ReadBookCustomPageWidget.routePath,
          builder: (context, params) => ReadBookCustomPageWidget(
            pdf: params.getParam(
              'pdf',
              ParamType.String,
            ),
            id: params.getParam(
              'id',
              ParamType.String,
            ),
            name: params.getParam(
              'name',
              ParamType.String,
            ),
            image: params.getParam(
              'image',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: FilterResultPageWidget.routeName,
          path: FilterResultPageWidget.routePath,
          builder: (context, params) => FilterResultPageWidget(),
        ),
        FFRoute(
          name: ReviewsummaryPageWidget.routeName,
          path: ReviewsummaryPageWidget.routePath,
          builder: (context, params) => ReviewsummaryPageWidget(
            paymentName: params.getParam(
              'paymentName',
              ParamType.String,
            ),
            subscriptionPlanId: params.getParam(
              'subscriptionPlanId',
              ParamType.String,
            ),
            subscriptionPlanName: params.getParam(
              'subscriptionPlanName',
              ParamType.String,
            ),
            subscriptionPlanDuration: params.getParam(
              'subscriptionPlanDuration',
              ParamType.String,
            ),
            subscriptionPlanDurationInTerms: params.getParam(
              'subscriptionPlanDurationInTerms',
              ParamType.String,
            ),
            subscriptionPlanPrice: params.getParam(
              'subscriptionPlanPrice',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: PaymentMethodPageWidget.routeName,
          path: PaymentMethodPageWidget.routePath,
          builder: (context, params) => PaymentMethodPageWidget(
            subscriptionJson: params.getParam(
              'subscriptionJson',
              ParamType.JSON,
            ),
          ),
        ),
        FFRoute(
          name: BookDetailspageCopyWidget.routeName,
          path: BookDetailspageCopyWidget.routePath,
          builder: (context, params) => BookDetailspageCopyWidget(
            name: params.getParam(
              'name',
              ParamType.String,
            ),
            image: params.getParam(
              'image',
              ParamType.String,
            ),
            id: params.getParam(
              'id',
              ParamType.String,
            ),
          ),
        )
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    List<String>? collectionNamePath,
    StructBuilder<T>? structBuilder,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      collectionNamePath: collectionNamePath,
      structBuilder: structBuilder,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(key: state.pageKey, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}

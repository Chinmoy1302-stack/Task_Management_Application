import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import 'firebase_options.dart';
import 'core/env/env.dart';
import 'core/network/network.dart';
import 'core/services/objectbox_service.dart';
import 'core/widgets/app_lifecycle_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/navigation_helper.dart';
import 'core/theme/app_theme_type.dart';

import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'core/theme/theme_controller.dart';
import 'core/services/theme_service.dart';
import 'core/language/language_controller.dart';
import 'core/services/language_service.dart';
import 'core/services/google_sign_in_service.dart';
import 'core/services/notification_service.dart';
import 'i18n/strings.g.dart';

//add all services here
late ObjectBoxService objectBox;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await GoogleSignInService.initialize();

  // Note: Firebase Auth persistence is automatic on mobile (iOS/Android)
  // Only web requires setPersistence() call

  // Initialize Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Set up Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );

  // Initialize ObjectBox
  objectBox = await ObjectBoxService.create();

  // Initialize local notifications & request permissions
  await NotificationService().initialize();

  // Initialize Network Layer
  DioClient.initialize(
    config: NetworkConfig(baseUrl: Env.baseUrl, enableLogging: true),
  );

  // Load theme before creating controller
  final themeService = ThemeService();
  final savedTheme = await themeService.getTheme();

  // Load language before creating controller
  final languageService = LanguageService();
  final savedLanguage = await languageService.getLanguage();

  // Inject Controllers globally (GetX for state management only)
  Get.put(AuthController());
  Get.lazyPut(() => OnboardingController());
  Get.put(ThemeController(initialTheme: savedTheme));
  Get.put(LanguageController(initialLanguage: savedLanguage));

  runApp(MyApp(database: objectBox));
}

class MyApp extends StatelessWidget {
  final ObjectBoxService database;

  const MyApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final themeController = Get.find<ThemeController>();

    return ToastificationWrapper(
      child: AppLifecycleHandler(
        child: TranslationProvider(
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Obx(() {
              final theme = themeController.currentTheme;
              final isDark =
                  theme == AppThemeMode.dark ||
                  (theme == AppThemeMode.system &&
                      MediaQuery.platformBrightnessOf(context) ==
                          Brightness.dark);

              return GetBuilder<LanguageController>(
                builder: (languageController) {
                  return MaterialApp.router(
                    title: 'TaskFlow',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.getTheme(isDarkMode: isDark),
                    darkTheme: AppTheme.getTheme(isDarkMode: true),
                    themeMode: theme == AppThemeMode.system
                        ? ThemeMode.system
                        : (theme == AppThemeMode.dark
                              ? ThemeMode.dark
                              : ThemeMode.light),
                    routerConfig: AppRouter.router,
                    locale: languageController.currentAppLocale.flutterLocale,
                    supportedLocales: AppLocaleUtils.instance.supportedLocales,
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    builder: (context, child) {
                      // Auth state redirect
                      return Obx(() {
                        final user = authController.firebaseUser.value;
                        final currentRoute = AppRouter
                            .router
                            .routerDelegate
                            .currentConfiguration
                            .uri
                            .path;

                        // Redirect authenticated users from login to tasks
                        if (user != null && currentRoute == '/login') {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            NavigationHelper.toTasks();
                          });
                        }

                        return Directionality(
                          textDirection: languageController.isRTL
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          child: child!,
                        );
                      });
                    },
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

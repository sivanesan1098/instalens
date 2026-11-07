import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/extraction_provider.dart';
import 'screens/error_screen.dart';
import 'screens/home_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/results_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InstaLensApp());
}

class InstaLensApp extends StatelessWidget {
  const InstaLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExtractionProvider()),
      ],
      child: MaterialApp(
        title: 'InstaLens',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const RootNavigationRouter(),
      ),
    );
  }
}

/// Dynamic router switching between the Stitch-designed flow states.
class RootNavigationRouter extends StatelessWidget {
  const RootNavigationRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<ExtractionProvider, ExtractionStatus>(
      (provider) => provider.status,
    );

    switch (status) {
      case ExtractionStatus.idle:
        return const HomeScreen();
      case ExtractionStatus.loading:
        return const LoadingScreen();
      case ExtractionStatus.success:
        return const ResultsScreen();
      case ExtractionStatus.error:
        return const ErrorScreen();
    }
  }
}

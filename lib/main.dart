import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'data/models/user.dart';
import 'presentation/providers/hive_viewmodel.dart';
import 'presentation/providers/shared_preferences_viewmodel.dart';
import 'presentation/views/home_screen.dart';

void main() async {
  // FLOW: Step 1 - Ensure Flutter engine binding is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // FLOW: Step 2 - Initialize Hive database engine.
  await Hive.initFlutter();

  // Register the User adapter so Hive knows how to encode/decode the custom User object.
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserAdapter());
  }

  // FLOW: Step 3 - Start the application.
  runApp(const LocalStorageApp());
}

class LocalStorageApp extends StatelessWidget {
  const LocalStorageApp({super.key});

  @override
  Widget build(BuildContext context) {
    // FLOW: Step 4 - Wrap app in MultiProvider to enable dependency injection and state management.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SharedPreferencesViewModel>(
          create: (context) => SharedPreferencesViewModel()..initialize(),
        ),
        ChangeNotifierProvider<HiveViewModel>(
          create: (context) => HiveViewModel()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'Local Storage Module',
        debugShowCheckedModeBanner: false,
        // FLOW: Step 5 - Design a gorgeous, modern Light theme (using vibrant seed teal).
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.light, // Configured for vibrant light mode
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7F9FB), // elegant warm light background
          appBarTheme: const AppBarTheme(
            elevation: 0,
            scrolledUnderElevation: 1,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            centerTitle: true,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

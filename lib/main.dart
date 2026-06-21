import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/robot_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';
import 'screens/connection_screen.dart';
import 'screens/control_screen.dart';
import 'screens/keyframe_screen.dart';

import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RobotService()),
        ChangeNotifierProvider(create: (_) => SettingsService()),
      ],
      child: const OgarmApp(),
    ),
  );
}

class OgarmApp extends StatelessWidget {
  const OgarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final isDark = settingsService.isDarkMode;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark ? const Color(0xFF0D1127) : Colors.white,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      title: 'OGARM',
      debugShowCheckedModeBanner: false,
      theme: OgarmTheme.lightTheme,
      darkTheme: OgarmTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const ConnectionScreen(),
        '/home': (context) => const HomeShell(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}


class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    ControlScreen(),
    KeyframeScreen(),

    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1127) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark 
                  ? OgarmColors.glassBorder.withValues(alpha: 0.15) 
                  : Colors.black.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: isDark ? OgarmColors.orange : OgarmColors.orangeDark,
          unselectedItemColor: isDark ? OgarmColors.textMuted : const Color(0xFF8A8A9E),
          selectedLabelStyle: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
          unselectedLabelStyle: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            letterSpacing: 1,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.gamepad_outlined),
              activeIcon: Icon(Icons.gamepad),
              label: 'CONTROL',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.motion_photos_auto_outlined),
              activeIcon: Icon(Icons.motion_photos_auto),
              label: 'KEYFRAMES',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}

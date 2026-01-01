import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'comp_src/pages/drawing_scanner_page.dart';
import 'comp_src/services/drawing_service.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const DrawingScannerApp());
}

class DrawingScannerApp extends StatefulWidget {
  const DrawingScannerApp({super.key});

  @override
  State<DrawingScannerApp> createState() => _DrawingScannerAppState();

  /// 静态方法访问状态，用于切换语言和主题
  // ignore: library_private_types_in_public_api
  static _DrawingScannerAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_DrawingScannerAppState>();
  }
}

class _DrawingScannerAppState extends State<DrawingScannerApp> {
  /// 当前语言
  Locale _locale = const Locale('zh');

  /// 是否深色模式
  bool _isDarkMode = false;

  /// 核心业务逻辑层
  final DrawingService _drawingService = DrawingService();

  @override
  void initState() {
    super.initState();
    // 初始化服务 - 创建 AI 图片存储文件夹
    _initializeService();
  }

  /// 初始化服务
  Future<void> _initializeService() async {
    // 先初始化服务（会请求权限并创建文件夹）
    await _drawingService.initialize();
  }

  /// 切换语言
  void changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  /// 切换深色模式
  void toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 提供 DrawingService 给整个应用
        Provider<DrawingService>.value(value: _drawingService),
      ],
      child: MaterialApp(
        title: '机械图纸归档助手',
        debugShowCheckedModeBanner: false,

        // 国际化配置
        theme: _buildTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: _locale,

        home: DrawingScannerPage(
          drawingService: _drawingService,
        ),
      ),
    );
  }

  /// 浅色主题
  static ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.light(
        primary: const Color(0xFF2563EB),
        secondary: const Color(0xFFF59E0B),
        surface: const Color(0xFFFAFAFA),
        error: const Color(0xFFDC2626),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF0F172A),
        onSurfaceVariant: const Color(0xFF64748B),
      ),

      scaffoldBackgroundColor: const Color(0xFFF8FAFC),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFAFAFA),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFF2563EB)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 15,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
          letterSpacing: -1,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: Color(0xFF334155),
        ),
      ),

      iconTheme: const IconThemeData(
        color: Color(0xFF2563EB),
        size: 22,
      ),
    );
  }

  /// 深色主题
  static ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF60A5FA),
        secondary: const Color(0xFFFBBF24),
        surface: const Color(0xFF1E293B),
        error: const Color(0xFFEF4444),
        onPrimary: const Color(0xFF0F172A),
        onSecondary: const Color(0xFF0F172A),
        onSurface: const Color(0xFFF1F5F9),
        onSurfaceVariant: const Color(0xFF94A3B8),
      ),

      scaffoldBackgroundColor: const Color(0xFF0F172A),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF1F5F9),
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFF60A5FA)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF334155),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF475569), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF475569), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 15,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF60A5FA),
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF1F5F9),
          letterSpacing: -1,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF1F5F9),
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: Color(0xFFCBD5E1),
        ),
      ),

      iconTheme: const IconThemeData(
        color: Color(0xFF60A5FA),
        size: 22,
      ),
    );
  }
}

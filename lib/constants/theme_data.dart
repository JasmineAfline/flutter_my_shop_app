import 'package:my_shop/constants/app_colors.dart';
import 'package:flutter/material.dart';

class Styles {

  static ThemeData themeData ({required bool isDarkTheme, required BuildContext context}){

    return ThemeData(
      useMaterial3: true,
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDarkTheme ? AppColors.darkScaffoldColor : AppColors.lightScaffoldColor,
      
      // Primary Color Theme
      primaryColor: isDarkTheme ? AppColors.darkPrimaryColor : AppColors.lightPrimaryColor,
      
      // Icon theme
      iconTheme: IconThemeData(
        color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      
      // AppBar theme - Modern flat design with subtle elevation
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkTheme ? AppColors.darkScaffoldColor : AppColors.lightScaffoldColor,
        foregroundColor: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      
      // Bottom Navigation Bar - Modern with smooth indicator
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDarkTheme ? AppColors.darkScaffoldColor : Colors.white,
        elevation: 0,
        height: 70,
        indicatorColor: isDarkTheme 
            ? AppColors.darkPrimaryColor.withOpacity(0.2) 
            : AppColors.lightPrimaryColor.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: isDarkTheme ? AppColors.darkPrimaryColor : AppColors.lightPrimaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: isDarkTheme ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isDarkTheme ? AppColors.darkPrimaryColor : AppColors.lightPrimaryColor,
              size: 24,
            );
          }
          return IconThemeData(
            color: isDarkTheme ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            size: 24,
          );
        }),
      ),
      
      // Text Theme - Modern typography
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: isDarkTheme ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),

      // Elevated Button - Modern with rounded corners
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: isDarkTheme ? AppColors.darkPrimaryColor : AppColors.lightPrimaryColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDarkTheme ? AppColors.darkPrimaryColor : AppColors.lightPrimaryColor,
          side: BorderSide(
            color: isDarkTheme ? AppColors.darkPrimaryColor : AppColors.lightPrimaryColor,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDarkTheme ? AppColors.darkPrimaryColor : AppColors.lightPrimaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration - Modern with floating labels
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDarkTheme 
            ? AppColors.darkCardColor 
            : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkTheme ? AppColors.darkBorderColor : AppColors.lightBorderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkTheme ? AppColors.darkBorderColor : AppColors.lightBorderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkTheme ? AppColors.darkPrimaryColor : AppColors.lightPrimaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.errorColor,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.errorColor,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: isDarkTheme ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        hintStyle: TextStyle(
          color: isDarkTheme ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDarkTheme ? AppColors.darkPrimaryColor : AppColors.lightPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Snackbars - Modern floating style
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDarkTheme 
            ? AppColors.darkCardColor 
            : AppColors.lightTextPrimary,
        contentTextStyle: TextStyle(
          color: isDarkTheme ? AppColors.darkTextPrimary : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Dialogs - Modern rounded
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isDarkTheme ? AppColors.darkCardColor : Colors.white,
        titleTextStyle: TextStyle(
          color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDarkTheme ? AppColors.darkCardColor : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      
      // Card Theme - Modern with subtle shadow
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: isDarkTheme ? 0 : 2,
        color: isDarkTheme ? AppColors.darkCardColor : AppColors.lightCardColor,
        shadowColor: isDarkTheme 
            ? Colors.black.withOpacity(0.3) 
            : Colors.black.withOpacity(0.08),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: isDarkTheme 
            ? AppColors.darkCardColor 
            : Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide.none,
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: isDarkTheme ? AppColors.darkBorderColor : AppColors.lightBorderColor,
        thickness: 1,
        space: 1,
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDarkTheme ? AppColors.darkPrimaryColor : AppColors.lightPrimaryColor,
        circularTrackColor: isDarkTheme 
            ? AppColors.darkPrimaryColor.withOpacity(0.2) 
            : AppColors.lightPrimaryColor.withOpacity(0.2),
      ),
      
      // Color Scheme
      colorScheme: ColorScheme(
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
        primary: isDarkTheme ? AppColors.darkPrimaryColor : AppColors.lightPrimaryColor,
        onPrimary: Colors.white,
        secondary: isDarkTheme ? AppColors.accentColorLight : AppColors.accentColor,
        onSecondary: Colors.white,
        error: AppColors.errorColor,
        onError: Colors.white,
        surface: isDarkTheme ? AppColors.darkCardColor : Colors.white,
        onSurface: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      
      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

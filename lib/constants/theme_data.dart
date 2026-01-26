import 'package:my_shop/constants/app_colors.dart';
import 'package:flutter/material.dart';

class Styles {

  static ThemeData themeData ({required bool isDarkTheme,required BuildContext context}){


    return ThemeData(
      scaffoldBackgroundColor: isDarkTheme ? AppColors.darkScaffoldColor:AppColors.lightScaffoldColor,
      cardColor: isDarkTheme?const Color.fromARGB(100, 78, 89, 67):AppColors.lightCardColor,
      
      // Icon theme for better visibility
      iconTheme: IconThemeData(
        color: isDarkTheme ? Colors.white : Colors.black87,
      ),
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkTheme ? AppColors.darkScaffoldColor : AppColors.lightScaffoldColor,
        foregroundColor: isDarkTheme ? Colors.white : Colors.black87,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkTheme ? Colors.white : Colors.black87,
        ),
      ),
      
      // Bottom Navigation Bar theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDarkTheme ? AppColors.darkScaffoldColor : AppColors.lightScaffoldColor,
        indicatorColor: isDarkTheme ? AppColors.lightPrimaryColor.withOpacity(0.3) : AppColors.lightPrimaryColor.withOpacity(0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isDarkTheme ? Colors.white : AppColors.lightPrimaryColor,
            );
          }
          return IconThemeData(
            color: isDarkTheme ? Colors.white70 : Colors.black54,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: isDarkTheme ? Colors.white : AppColors.lightPrimaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: isDarkTheme ? Colors.white70 : Colors.black54,
            fontSize: 12,
          );
        }),
      ),
      
      // Text theme
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: isDarkTheme ? Colors.white : Colors.black87),
        bodyMedium: TextStyle(color: isDarkTheme ? Colors.white : Colors.black87),
        bodySmall: TextStyle(color: isDarkTheme ? Colors.white70 : Colors.black54),
        titleLarge: TextStyle(color: isDarkTheme ? Colors.white : Colors.black87),
        titleMedium: TextStyle(color: isDarkTheme ? Colors.white : Colors.black87),
        titleSmall: TextStyle(color: isDarkTheme ? Colors.white : Colors.black87),
      ),
      
      // Color scheme
      colorScheme: ColorScheme(
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
        primary: isDarkTheme ? AppColors.darkPrimaryColor : AppColors.lightPrimaryColor,
        onPrimary: isDarkTheme ? Colors.black : Colors.white,
        secondary: isDarkTheme ? Colors.tealAccent : Colors.teal,
        onSecondary: isDarkTheme ? Colors.black : Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: isDarkTheme ? AppColors.darkScaffoldColor : Colors.white,
        onSurface: isDarkTheme ? Colors.white : Colors.black87,
      ),
    );
  }
}

import 'package:my_shop/constants/app_colors.dart';
import 'package:my_shop/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkTheme
          ? AppColors.darkScaffoldColor
          : AppColors.lightScaffoldColor,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome to My Shop",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkTheme ? Colors.white : Colors.black,
              ),
            ),

            SizedBox(height: 50),

            ElevatedButton(onPressed: () {}, child: Text("Buy Now")),

            SwitchListTile(
              title: Text(
                "Dark Mode",
                style: TextStyle(
                  color: themeProvider.isDarkTheme
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              value: themeProvider.isDarkTheme,
              onChanged: (value) {
                themeProvider.setDarkTheme(value);
                print('Theme State: ${themeProvider.isDarkTheme}');
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:my_shop/constants/theme_data.dart';
import 'package:my_shop/providers/theme_provider.dart';
import 'package:my_shop/screens/home_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),   
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: Styles.themeData(
            isDarkTheme: themeProvider.isDarkTheme,
            context: context,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}

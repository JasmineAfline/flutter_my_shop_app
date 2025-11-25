import 'package:flutter/material.dart';
import 'package:my_shop/screens/home_screen.dart';

void main() {
  runApp(
    MaterialApp(
    theme: ThemeData(scaffoldBackgroundColor: Colors.blue),



	home: Scaffold(body: HomeScreen(),),
  ));
}
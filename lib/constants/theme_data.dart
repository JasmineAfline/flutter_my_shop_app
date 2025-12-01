import 'package:my_shop/constants/app_colors.dart';
import 'package:flutter/material.dart';

class Styles {

  static ThemeData themeData ({required bool isDarkTheme,required BuildContext context}){


    return ThemeData(
      scaffoldBackgroundColor: isDarkTheme ? AppColors.darkScaffoldColor:AppColors.lightScaffoldColor,

      cardColor: isDarkTheme?const Color.fromARGB(100, 78, 89, 67):AppColors.lightCardColor








    );




  }






}
import 'package:flutter/material.dart';
import 'package:my_shop/constants/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightScaffoldColor,
      body: Center(
        child: Center(
          child: Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
              
              children: [
            
            
                Text(
                  'Welcome to My Shop!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 20),

                
            
                ElevatedButton(onPressed: (){}, child: Text('Shop Now')),
            
              ],
              
              ),
          ),
        ),
      ),
    );
  }
}
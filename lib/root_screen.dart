import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:my_shop/screens/home_screen.dart';
import 'package:my_shop/screens/profile_screen.dart';

class RootScreen extends StatefulWidget {
  static const routeName = "/RootScreen";
  const RootScreen({super.key});


  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  late List<Widget> screens;
  int currentScreen = 0;

  late PageController controller;

  @override
  void initState() {
    screens = [
      const HomeScreen(),
      const SearchScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    controller = PageController(initialPage: currentScreen);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: NeverScrollableScrollPhysics(),
        controller: controller,
        children: screens,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentScreen,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        height: kBottomNavigationBarHeight,
        onDestinationSelected: (index) {
          setState(() {
            currentScreen = index;
          });

          controller.jumpToPage(currentScreen);
        },

        destinations: [
          NavigationDestination(
            selectedIcon: Icon(IconlyBold.activity),
            icon: Icon(IconlyLight.home),
            label: 'Home',
          ),
            NavigationDestination(
            selectedIcon: Icon(IconlyBold.search),
            icon: Icon(IconlyLight.search),
            label: 'Search',
          ),
            NavigationDestination(
            selectedIcon: Icon(IconlyBold.bag_2),
            icon: Icon(IconlyLight.bag_2),
            label: 'Cart',
          ),

            NavigationDestination(
            selectedIcon: Icon(IconlyBold.profile),
            icon: Icon(IconlyLight.profile),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: const Center(child: Text('Cart Screen - Coming Soon')),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: const Center(child: Text('Search Screen - Coming Soon')),
    );
  }
}
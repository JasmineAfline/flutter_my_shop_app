import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import 'package:my_shop/screens/home_screen.dart';
import 'package:my_shop/screens/profile_screen.dart';
import 'package:my_shop/screens/checkout_screen.dart';
import 'package:my_shop/providers/user_provider.dart';
import 'package:my_shop/providers/cart_provider.dart';
import 'package:my_shop/utils/route_guard.dart';

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
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final cartItems = cartProvider.cartItems;
        final total = cartProvider.total;

        return Scaffold(
          appBar: AppBar(title: const Text('Shopping Cart')),
          body: cartItems.isEmpty
              ? const Center(child: Text('Your cart is empty'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade200,
                                child: item['imageUrl'].toString().isNotEmpty
                                    ? Image.network(item['imageUrl'], fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image))
                                    : const Icon(Icons.image),
                              ),
                              title: Text(item['name']),
                              subtitle: Text('KSH ${item['price']}'),
                              trailing: SizedBox(
                                width: 100,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        if (item['quantity'] > 1) {
                                          cartProvider.updateQuantity(index, item['quantity'] - 1);
                                        } else {
                                          cartProvider.removeFromCart(index);
                                        }
                                      },
                                    ),
                                    Text('${item['quantity']}'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        cartProvider.updateQuantity(index, item['quantity'] + 1);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide()),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('KSH ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: cartItems.isEmpty
                                  ? null
                                  : () {
                                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                                      if (!RouteGuard.isLoggedIn(userProvider)) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to checkout')));
                                        return;
                                      }
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) => CheckoutScreen(cartItems: cartItems, total: total),
                                      ));
                                    },
                              child: const Text('Checkout'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    if (!RouteGuard.isLoggedIn(userProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 72, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Sign in to see your orders', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Error loading orders: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please try again later')),
                    ),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }
          
          // Filter orders by current user and sort by date
          final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
          final allOrders = snapshot.data?.docs ?? [];
          final userOrders = allOrders
              .where((doc) => (doc.data() as Map<String, dynamic>)['userId'] == currentUserId)
              .toList();
          
          // No data state
          if (userOrders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }
          
          // Orders list
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userOrders.length,
            itemBuilder: (context, index) {
              try {
                final order = userOrders[index].data() as Map<String, dynamic>;
                final orderId = userOrders[index].id;
                final status = order['status'] ?? 'pending';
                final total = (order['total'] ?? 0).toDouble();
                
                // Safe extraction of createdAt timestamp
                String createdAt = '';
                final createdAtValue = order['createdAt'];
                if (createdAtValue is Timestamp) {
                  createdAt = createdAtValue.toDate().toString().split('.')[0];
                } else if (createdAtValue != null) {
                  createdAt = createdAtValue.toString();
                }
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text('Order #${orderId.substring(0, 8)}'),
                    subtitle: Text('Status: $status | Total: \$${total.toStringAsFixed(2)}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (createdAt.isNotEmpty)
                              Text('Date: $createdAt'),
                            if (createdAt.isNotEmpty)
                              const SizedBox(height: 8),
                            Text('Status: ${_statusBadge(status)}'),
                            const SizedBox(height: 8),
                            Text('Total: \$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text('Order #${userOrders[index].id.substring(0, 8)}'),
                    subtitle: const Text('Error loading order details'),
                    trailing: const Icon(Icons.error, color: Colors.red),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  String _statusBadge(String status) {
    switch (status) {
      case 'completed':
        return '✓ Completed';
      case 'processing':
        return '⧗ Processing';
      case 'cancelled':
        return '✗ Cancelled';
      default:
        return '○ Pending';
    }
  }
}
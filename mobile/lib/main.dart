import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'firebase_options.dart';

// ======================================================
// TECHFORGE THEME
// ======================================================

const Color navy = Color(0xFF080D16);
const Color background = Color(0xFF0B1220);
const Color panel = Color(0xFF121C2B);
const Color panelLight = Color(0xFF1A2739);
const Color blue = Color(0xFF3478F6);
const Color lightBlue = Color(0xFF66A5FF);
const Color muted = Color(0xFF8B9BB0);
const Color success = Color(0xFF32D399);
const Color danger = Color(0xFFFB7185);

final NumberFormat peso = NumberFormat.currency(
  locale: 'en_PH',
  symbol: '₱',
  decimalDigits: 2,
);

final FirebaseFirestore db = FirebaseFirestore.instance;
final FirebaseAuth auth = FirebaseAuth.instance;

// ======================================================
// MAIN
// ======================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TechForgeApp());
}

class TechForgeApp extends StatelessWidget {
  const TechForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TechForge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          brightness: Brightness.dark,
          surface: panel,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel,
          hintStyle: const TextStyle(color: muted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: blue, width: 1.3),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: panelLight,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// ======================================================
// SHARED UI HELPERS
// ======================================================

void showAppMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
}

Widget sectionTitle(String title, {String? subtitle}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.4,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: muted,
            fontSize: 12,
          ),
        ),
      ],
    ],
  );
}

Widget imagePlaceholder({double iconSize = 48}) {
  return Center(
    child: Icon(
      Icons.memory_rounded,
      size: iconSize,
      color: lightBlue.withValues(alpha: 0.65),
    ),
  );
}

Widget productImage(
  String url, {
  BoxFit fit = BoxFit.contain,
  double iconSize = 48,
}) {
  if (url.trim().isEmpty) {
    return imagePlaceholder(iconSize: iconSize);
  }

  return Image.network(
    url,
    fit: fit,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;

      return const Center(
        child: SizedBox(
          width: 25,
          height: 25,
          child: CircularProgressIndicator(
            color: lightBlue,
            strokeWidth: 2,
          ),
        ),
      );
    },
    errorBuilder: (context, error, stackTrace) {
      return imagePlaceholder(iconSize: iconSize);
    },
  );
}

Widget loadingIndicator() {
  return const Center(
    child: CircularProgressIndicator(
      color: lightBlue,
      strokeWidth: 2.5,
    ),
  );
}

// ======================================================
// AUTHENTICATION GATE
// ======================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasData) {
          return const StoreShell();
        }

        return const LoginPage();
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: navy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.memory_rounded,
              color: lightBlue,
              size: 65,
            ),
            SizedBox(height: 18),
            Text(
              'TECHFORGE',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// LOGIN AND REGISTRATION
// ======================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  bool isRegistering = false;
  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> authenticate() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showAppMessage(context, 'Please complete the required fields.');
      return;
    }

    if (isRegistering && name.isEmpty) {
      showAppMessage(context, 'Please enter your full name.');
      return;
    }

    if (password.length < 6) {
      showAppMessage(context, 'Password must be at least 6 characters.');
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isRegistering) {
        final credential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = credential.user;

        if (user != null) {
          await user.updateDisplayName(name);

          await db.collection('users').doc(user.uid).set({
            'fullName': name,
            'email': email,
            'phoneNumber': '',
            'role': 'customer',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        showAppMessage(context, e.message ?? 'Authentication failed.');
      }
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Something went wrong: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF101F36),
              background,
              navy,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 25),

                    // Brand logo
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        color: blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.memory_rounded,
                        color: lightBlue,
                        size: 50,
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'TECHFORGE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'BUILD YOUR DREAM PC.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        letterSpacing: 2.5,
                      ),
                    ),

                    const SizedBox(height: 45),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        isRegistering ? 'Create your account' : 'Welcome back',
                        key: ValueKey(isRegistering),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      isRegistering
                          ? 'Join TechForge and start building your setup.'
                          : 'Sign in to continue shopping.',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 25),

                    if (isRegistering) ...[
                      TextField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      height: 53,
                      child: FilledButton(
                        onPressed: isLoading ? null : authenticate,
                        style: FilledButton.styleFrom(
                          backgroundColor: blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isRegistering ? 'CREATE ACCOUNT' : 'SIGN IN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              setState(() {
                                isRegistering = !isRegistering;
                              });
                            },
                      child: Text(
                        isRegistering
                            ? 'Already have an account? Sign in'
                            : "Don't have an account? Register",
                        style: const TextStyle(color: lightBlue),
                      ),
                    ),

                    const SizedBox(height: 35),

                    const Text(
                      'POWER YOUR NEXT BUILD.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================
// MAIN STORE SHELL
// ======================================================

class StoreShell extends StatefulWidget {
  const StoreShell({super.key});

  @override
  State<StoreShell> createState() => _StoreShellState();
}

class _StoreShellState extends State<StoreShell> {
  int selectedIndex = 0;

  final Map<String, int> cart = {};

  void addToCart(String productId) {
    setState(() {
      cart[productId] = (cart[productId] ?? 0) + 1;
    });

    showAppMessage(context, 'Added to your cart.');
  }

  void changeQuantity(String productId, int change) {
    setState(() {
      final quantity = (cart[productId] ?? 0) + change;

      if (quantity <= 0) {
        cart.remove(productId);
      } else {
        cart[productId] = quantity;
      }
    });
  }

  void clearCart() {
    setState(() => cart.clear());
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = cart.values.fold<int>(
      0,
      (total, quantity) => total + quantity,
    );

    final pages = [
      ProductPage(onAdd: addToCart),
      CartPage(
        cart: cart,
        onQuantityChanged: changeQuantity,
        onClearCart: clearCart,
      ),
      const OrdersPage(),
      AccountPage(
        onViewOrders: () {
          setState(() => selectedIndex = 2);
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.memory_rounded,
                color: lightBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TECHFORGE',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'PC COMPONENTS STORE',
                  style: TextStyle(
                    fontSize: 8,
                    color: muted,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await auth.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.025, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(selectedIndex),
          child: pages[selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: panel,
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
        child: NavigationBar(
          height: 72,
          backgroundColor: panel,
          indicatorColor: blue.withValues(alpha: 0.18),
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            setState(() => selectedIndex = index);
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: 'Shop',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text(cartCount.toString()),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: const Icon(Icons.shopping_bag_rounded),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// SHOP PAGE
// ======================================================

class ProductPage extends StatefulWidget {
  final Function(String) onAdd;

  const ProductPage({
    super.key,
    required this.onAdd,
  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  String category = 'All';
  String search = '';

  final List<String> categories = [
    'All',
    'Processors',
    'Graphics Cards',
    'Motherboards',
    'Memory',
    'Storage',
    'Power Supply',
    'Cases',
    'Peripherals',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // Hero banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  child: Container(
                    height: 155,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF164B9D),
                          Color(0xFF102747),
                          Color(0xFF17253B),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: lightBlue.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: 5,
                          bottom: -18,
                          child: Icon(
                            Icons.memory_rounded,
                            size: 145,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(19),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'TECHFORGE COLLECTION',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'BUILD YOUR\nDREAM PC.',
                                style: TextStyle(
                                  fontSize: 25,
                                  height: 1.08,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Find the right components for your setup.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        search = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search products, brands...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: search.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() => search = '');
                              },
                              icon: const Icon(Icons.close),
                            )
                          : const Icon(
                              Icons.tune_rounded,
                              color: muted,
                            ),
                    ),
                  ),
                ),
              ),

              // Categories
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 58,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 5),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final value = categories[index];
                      final selected = category == value;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(value),
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) {
                            setState(() => category = value);
                          },
                          backgroundColor: panel,
                          selectedColor: blue,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: selected ? Colors.white : muted,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: selected
                                  ? blue
                                  : Colors.white.withValues(alpha: 0.07),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Section heading
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      sectionTitle(
                        'Explore Products',
                        subtitle: 'Find components for your next build',
                      ),
                      const Icon(
                        Icons.grid_view_rounded,
                        color: muted,
                        size: 19,
                      ),
                    ],
                  ),
                ),
              ),

              // Product stream
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: db.collection('products').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Unable to load products.\nPlease check your internet connection and Firestore rules.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: muted),
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(color: blue),
                      ),
                    );
                  }

                  final docs = (snapshot.data?.docs ?? []).where((doc) {
                    final p = doc.data();

                    final name =
                        (p['productName'] ?? '').toString().toLowerCase();

                    final brand = (p['brand'] ?? '').toString().toLowerCase();

                    final description =
                        (p['description'] ?? '').toString().toLowerCase();

                    final productCategory = (p['category'] ?? '').toString();

                    final matchesSearch = name.contains(search) ||
                        brand.contains(search) ||
                        description.contains(search);

                    final matchesCategory =
                        category == 'All' || productCategory == category;

                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (docs.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(25),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 65,
                                color: Colors.white24,
                              ),
                              const SizedBox(height: 15),
                              Text(
                                search.isNotEmpty || category != 'All'
                                    ? 'No matching products'
                                    : 'No products available yet',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Products added through the TechForge Admin Dashboard will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 25),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.crossAxisExtent;
                        final columns = width >= 600 ? 3 : 2;

                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            childAspectRatio: width >= 600 ? 0.67 : 0.56,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 13,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final doc = docs[index];

                              return ProductCard(
                                key: ValueKey(doc.id),
                                productId: doc.id,
                                product: doc.data(),
                                animationIndex: index,
                                onAdd: widget.onAdd,
                              );
                            },
                            childCount: docs.length,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ======================================================
// MY ACCOUNT PAGE
// ======================================================

class AccountPage extends StatefulWidget {
  final VoidCallback onViewOrders;

  const AccountPage({
    super.key,
    required this.onViewOrders,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool isSaving = false;

  Future<void> editProfile(Map<String, dynamic> userData) async {
    final user = auth.currentUser;

    if (user == null) return;

    final nameController = TextEditingController(
      text: (userData['fullName'] ?? user.displayName ?? '').toString(),
    );

    final phoneController = TextEditingController(
      text: (userData['phoneNumber'] ?? '').toString(),
    );

    final formKey = GlobalKey<FormState>();

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: panel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Edit Profile',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name.';
                        }

                        if (value.trim().length < 2) {
                          return 'Name is too short.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '09XXXXXXXXX',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number.';
                        }

                        final phone = value.trim();

                        if (!RegExp(r'^[0-9+\-\s()]{7,20}$').hasMatch(phone)) {
                          return 'Enter a valid phone number.';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(dialogContext, true);
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) return;

      setState(() => isSaving = true);

      final fullName = nameController.text.trim();
      final phoneNumber = phoneController.text.trim();

      await db.collection('users').doc(user.uid).set({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': user.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.updateDisplayName(fullName);

      if (!mounted) return;

      showAppMessage(context, 'Profile updated successfully.');
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Unable to update profile: $e');
      }
    } finally {
      nameController.dispose();
      phoneController.dispose();

      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> changePassword() async {
    final user = auth.currentUser;

    if (user == null || user.email == null) {
      showAppMessage(context, 'Please sign in again.');
      return;
    }

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: panel,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  'Change Password',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: obscureCurrent,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  obscureCurrent = !obscureCurrent;
                                });
                              },
                              icon: Icon(
                                obscureCurrent
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your current password.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 13),
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: obscureNew,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  obscureNew = !obscureNew;
                                });
                              },
                              icon: Icon(
                                obscureNew
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter a new password.';
                            }

                            if (value.length < 6) {
                              return 'Use at least 6 characters.';
                            }

                            if (value == currentPasswordController.text) {
                              return 'Choose a different password.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 13),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            prefixIcon:
                                const Icon(Icons.verified_user_outlined),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  obscureConfirm = !obscureConfirm;
                                });
                              },
                              icon: Icon(
                                obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirm your new password.';
                            }

                            if (value != newPasswordController.text) {
                              return 'Passwords do not match.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your new password must contain at least 6 characters.',
                          style: TextStyle(
                            color: muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(dialogContext, true);
                      }
                    },
                    child: const Text('Update Password'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed != true || !mounted) return;

      setState(() => isSaving = true);

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text,
      );

      // Verify the current password before changing it.
      await user.reauthenticateWithCredential(credential);

      // Update Firebase Authentication password.
      await user.updatePassword(
        newPasswordController.text,
      );

      if (!mounted) return;

      showAppMessage(context, 'Password changed successfully.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Your current password is incorrect.';
          break;

        case 'weak-password':
          message = 'Please choose a stronger password.';
          break;

        case 'requires-recent-login':
          message = 'Please sign in again before changing your password.';
          break;

        case 'network-request-failed':
          message = 'Network error. Check your internet connection.';
          break;

        default:
          message = e.message ?? 'Unable to change password.';
      }

      showAppMessage(context, message);
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Unable to change password: $e');
      }
    } finally {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();

      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Sign Out'),
          content: const Text(
            'Are you sure you want to sign out of your TechForge account?',
            style: TextStyle(color: muted),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: danger,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await auth.signOut();
    }
  }

  Widget accountOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = lightBlue,
    bool showArrow = true,
  }) {
    return Material(
      color: panel,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: isSaving ? null : onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                height: 43,
                width: 43,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (showArrow)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: muted,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;

    if (user == null) {
      return const EmptyState(
        icon: Icons.person_outline,
        title: 'Login required',
        message: 'Please sign in to view your account.',
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Unable to load your account information.',
              style: TextStyle(color: muted),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingIndicator();
        }

        final userData = snapshot.data?.data() ?? {};

        final fullName =
            (userData['fullName'] ?? user.displayName ?? 'TechForge Customer')
                .toString();

        final email = (userData['email'] ?? user.email ?? '').toString();

        final phoneNumber = (userData['phoneNumber'] ?? '').toString();

        final initial =
            fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : 'T';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            sectionTitle(
              'My Account',
              subtitle: 'Manage your personal information and security',
            ),
            const SizedBox(height: 20),

            // Profile card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF164B9D),
                    Color(0xFF102747),
                    Color(0xFF17253B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: lightBlue.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 37,
                    backgroundColor: Colors.white.withValues(alpha: 0.13),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'TECHFORGE CUSTOMER',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 23),

            sectionTitle('Personal Information'),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                children: [
                  _AccountInfoRow(
                    icon: Icons.person_outline,
                    label: 'Full Name',
                    value: fullName,
                  ),
                  const Divider(height: 25, color: Colors.white12),
                  _AccountInfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email Address',
                    value: email.isEmpty ? 'Not available' : email,
                  ),
                  const Divider(height: 25, color: Colors.white12),
                  _AccountInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    value: phoneNumber.isEmpty ? 'Not provided' : phoneNumber,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            accountOption(
              icon: Icons.edit_outlined,
              title: 'Edit Profile',
              subtitle: 'Update your name and phone number',
              onTap: () => editProfile(userData),
            ),

            const SizedBox(height: 23),

            sectionTitle('Orders and Security'),
            const SizedBox(height: 12),

            accountOption(
              icon: Icons.receipt_long_outlined,
              title: 'My Orders',
              subtitle: 'View purchases and track order status',
              onTap: widget.onViewOrders,
            ),

            const SizedBox(height: 10),

            accountOption(
              icon: Icons.lock_outline_rounded,
              title: 'Change Password',
              subtitle: 'Update your account password securely',
              onTap: changePassword,
            ),

            const SizedBox(height: 10),

            accountOption(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              subtitle: 'Sign out of your TechForge account',
              iconColor: danger,
              onTap: confirmSignOut,
            ),

            if (isSaving) ...[
              const SizedBox(height: 18),
              const Center(
                child: CircularProgressIndicator(
                  color: lightBlue,
                  strokeWidth: 2,
                ),
              ),
            ],

            const SizedBox(height: 25),

            const Center(
              child: Text(
                'TECHFORGE • BUILD YOUR DREAM PC.',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 9,
                  letterSpacing: 1.3,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ======================================================
// ACCOUNT INFORMATION ROW
// ======================================================

class _AccountInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AccountInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: lightBlue,
          size: 19,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: muted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ======================================================
// PRODUCT CARD
// ======================================================

class ProductCard extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> product;
  final int animationIndex;
  final Function(String) onAdd;

  const ProductCard({
    super.key,
    required this.productId,
    required this.product,
    required this.animationIndex,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final name = (product['productName'] ?? 'Unnamed Product').toString();

    final brand = (product['brand'] ?? '').toString();

    final description =
        (product['description'] ?? 'No description available.').toString();

    final category = (product['category'] ?? '').toString();

    final imageUrl = (product['imageUrl'] ?? '').toString();

    final price = num.tryParse(
          (product['price'] ?? 0).toString(),
        ) ??
        0;

    final stock = num.tryParse(
          (product['stock'] ?? 0).toString(),
        ) ??
        0;

    final available = stock > 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
        milliseconds: 350 + (animationIndex % 5) * 65,
      ),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Material(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: panel,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              builder: (_) => ProductDetailsSheet(
                product: product,
                productId: productId,
                onAdd: onAdd,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image area
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: const Color(0xFF1A2637),
                        padding: const EdgeInsets.all(11),
                        child: Hero(
                          tag: 'product_$productId',
                          child: productImage(
                            imageUrl,
                            fit: BoxFit.contain,
                            iconSize: 55,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 9,
                        right: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: available
                                ? success.withValues(alpha: 0.15)
                                : danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            available ? 'IN STOCK' : 'SOLD OUT',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: available ? success : danger,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Details
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brand.isEmpty ? category : brand.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: lightBlue,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Expanded(
                          child: Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: muted,
                              fontSize: 10,
                              height: 1.35,
                            ),
                          ),
                        ),
                        Text(
                          peso.format(price),
                          style: const TextStyle(
                            color: lightBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 34,
                          child: FilledButton(
                            onPressed:
                                available ? () => onAdd(productId) : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: blue,
                              disabledBackgroundColor: panelLight,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_shopping_cart_rounded,
                                  size: 14,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Add to Cart',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================
// PRODUCT DETAILS BOTTOM SHEET
// ======================================================

class ProductDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> product;
  final String productId;
  final Function(String) onAdd;

  const ProductDetailsSheet({
    super.key,
    required this.product,
    required this.productId,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final name = (product['productName'] ?? 'Product').toString();
    final brand = (product['brand'] ?? '').toString();
    final description =
        (product['description'] ?? 'No description available.').toString();
    final imageUrl = (product['imageUrl'] ?? '').toString();

    final price = num.tryParse(
          (product['price'] ?? 0).toString(),
        ) ??
        0;

    final stock = num.tryParse(
          (product['stock'] ?? 0).toString(),
        ) ??
        0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 230,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: panelLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(15),
                child: Hero(
                  tag: 'product_$productId',
                  child: productImage(imageUrl),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                brand.toUpperCase(),
                style: const TextStyle(
                  color: lightBlue,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                peso.format(price),
                style: const TextStyle(
                  color: lightBlue,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'PRODUCT DESCRIPTION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: muted,
                  height: 1.6,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: muted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stock > 0
                        ? '$stock units available'
                        : 'Currently out of stock',
                    style: TextStyle(
                      color: stock > 0 ? success : danger,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: stock > 0
                      ? () {
                          onAdd(productId);
                          Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('ADD TO CART'),
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    disabledBackgroundColor: panelLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// SHOPPING CART
// ======================================================

class CartPage extends StatefulWidget {
  final Map<String, int> cart;
  final Function(String, int) onQuantityChanged;
  final VoidCallback onClearCart;

  const CartPage({
    super.key,
    required this.cart,
    required this.onQuantityChanged,
    required this.onClearCart,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool isCheckingOut = false;

  Future<void> checkout(
    List<Map<String, dynamic>> items,
    double total,
  ) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    String paymentMethod = 'Cash on Delivery';

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: panel,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  'Checkout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your number.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: addressController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Address',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: paymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Payment Method',
                            prefixIcon: Icon(Icons.payment_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Cash on Delivery',
                              child: Text('Cash on Delivery'),
                            ),
                            DropdownMenuItem(
                              value: 'GCash',
                              child: Text('GCash'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                paymentMethod = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: blue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount'),
                              Text(
                                peso.format(total),
                                style: const TextStyle(
                                  color: lightBlue,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(dialogContext, true);
                      }
                    },
                    child: const Text('Place Order'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed != true || !mounted) return;

      setState(() => isCheckingOut = true);

      final user = auth.currentUser;

      if (user == null) {
        throw Exception('Please log in again.');
      }

      // Recheck stock before creating the order.
      for (final item in items) {
        final productId = item['productId'].toString();

        final productDoc = await db.collection('products').doc(productId).get();

        if (!productDoc.exists) {
          throw Exception('A product in your cart is no longer available.');
        }

        final stock = num.tryParse(
              (productDoc.data()?['stock'] ?? 0).toString(),
            ) ??
            0;

        final quantity = item['quantity'] as int;

        if (stock < quantity) {
          throw Exception(
            'Not enough stock for ${item['productName']}.',
          );
        }
      }

      await db.collection('orders').add({
        'userId': user.uid,
        'customerName': nameController.text.trim(),
        'contactNumber': phoneController.text.trim(),
        'deliveryAddress': addressController.text.trim(),
        'items': items,
        'totalAmount': total,
        'paymentMethod': paymentMethod,
        'orderStatus': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      widget.onClearCart();

      if (!mounted) return;

      showAppMessage(context, 'Your order was submitted successfully!');
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Checkout failed: $e');
      }
    } finally {
      nameController.dispose();
      phoneController.dispose();
      addressController.dispose();

      if (mounted) {
        setState(() => isCheckingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cart.isEmpty) {
      return const EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Your cart is empty',
        message: 'Explore our products and add something to your build.',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Unable to load your cart.'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingIndicator();
        }

        final productMap = {
          for (final doc in snapshot.data?.docs ?? []) doc.id: doc.data(),
        };

        double total = 0;
        final List<Map<String, dynamic>> orderItems = [];

        for (final entry in widget.cart.entries) {
          final product = productMap[entry.key];

          if (product == null) continue;

          final price = num.tryParse(
                (product['price'] ?? 0).toString(),
              ) ??
              0;

          final quantity = entry.value;

          total += price * quantity;

          orderItems.add({
            'productId': entry.key,
            'productName': product['productName'] ?? 'Product',
            'quantity': quantity,
            'price': price,
          });
        }

        if (orderItems.isEmpty) {
          return const EmptyState(
            icon: Icons.remove_shopping_cart_outlined,
            title: 'Products unavailable',
            message: 'Some products in your cart may have been removed.',
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  sectionTitle(
                    'Shopping Cart',
                    subtitle: 'Review your selected components',
                  ),
                  const SizedBox(height: 18),
                  ...widget.cart.entries.map((entry) {
                    final product = productMap[entry.key];

                    if (product == null) {
                      return const SizedBox.shrink();
                    }

                    final price = num.tryParse(
                          (product['price'] ?? 0).toString(),
                        ) ??
                        0;

                    final quantity = entry.value;

                    final stock = num.tryParse(
                          (product['stock'] ?? 0).toString(),
                        ) ??
                        0;

                    final imageUrl = (product['imageUrl'] ?? '').toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: panel,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 85,
                              width: 85,
                              color: panelLight,
                              padding: const EdgeInsets.all(6),
                              child: productImage(imageUrl),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${product['brand'] ?? ''}',
                                  style: const TextStyle(
                                    color: lightBlue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${product['productName'] ?? 'Product'}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  peso.format(price),
                                  style: const TextStyle(
                                    color: lightBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        widget.onQuantityChanged(
                                          entry.key,
                                          -1,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 21,
                                      ),
                                    ),
                                    Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: quantity < stock
                                          ? () {
                                              widget.onQuantityChanged(
                                                entry.key,
                                                1,
                                              );
                                            }
                                          : null,
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        size: 21,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Checkout summary
            Container(
              padding: const EdgeInsets.fromLTRB(18, 17, 18, 20),
              decoration: BoxDecoration(
                color: panel,
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          color: muted,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        peso.format(total),
                        style: const TextStyle(
                          color: lightBlue,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: isCheckingOut
                          ? null
                          : () => checkout(orderItems, total),
                      style: FilledButton.styleFrom(
                        backgroundColor: blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isCheckingOut
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_outline, size: 17),
                                SizedBox(width: 9),
                                Text(
                                  'PROCEED TO CHECKOUT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ======================================================
// EMPTY STATE
// ======================================================

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 95,
              width: 95,
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                icon,
                color: lightBlue,
                size: 43,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// CUSTOMER ORDERS
// ======================================================

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
      case 'delivered':
        return success;

      case 'cancelled':
      case 'rejected':
        return danger;

      case 'processing':
      case 'shipped':
        return lightBlue;

      default:
        return Colors.amberAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;

    if (user == null) {
      return const EmptyState(
        icon: Icons.person_outline,
        title: 'Login required',
        message: 'Please sign in to view your orders.',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Unable to load your orders.'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingIndicator();
        }

        final docs = [...(snapshot.data?.docs ?? [])];

        if (docs.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No orders yet',
            message: 'Your purchases and order updates will appear here.',
          );
        }

        docs.sort((a, b) {
          final aTime = a.data()['createdAt'] as Timestamp?;
          final bTime = b.data()['createdAt'] as Timestamp?;

          return (bTime?.millisecondsSinceEpoch ?? 0)
              .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
        });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            sectionTitle(
              'My Orders',
              subtitle: 'Track your purchases and order status',
            ),
            const SizedBox(height: 18),
            ...docs.map((doc) {
              final order = doc.data();

              final status = (order['orderStatus'] ?? 'Pending').toString();

              final total = num.tryParse(
                    (order['totalAmount'] ?? 0).toString(),
                  ) ??
                  0;

              final items = (order['items'] as List?) ?? [];

              final timestamp = order['createdAt'] as Timestamp?;

              final date = timestamp == null
                  ? 'Date unavailable'
                  : DateFormat('MMM dd, yyyy - hh:mm a')
                      .format(timestamp.toDate());

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'ORDER DETAILS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor(status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor(status),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      date,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                      ),
                    ),
                    const Divider(
                      height: 25,
                      color: Colors.white12,
                    ),
                    ...items.map((item) {
                      final product = Map<String, dynamic>.from(item as Map);

                      final quantity = product['quantity'] ?? 1;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${product['productName'] ?? 'Product'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              'x$quantity',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(
                      height: 22,
                      color: Colors.white12,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(color: muted),
                        ),
                        Text(
                          peso.format(total),
                          style: const TextStyle(
                            color: lightBlue,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.payment_outlined,
                          size: 15,
                          color: muted,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '${order['paymentMethod'] ?? 'Not specified'}',
                          style: const TextStyle(
                            color: muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

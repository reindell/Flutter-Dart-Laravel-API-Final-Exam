import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// --- STATE MANAGEMENT ---
class AppProvider extends ChangeNotifier {
  final String baseUrl = "http://127.0.0.1:8000/api";
  Map<String, dynamic>? user;
  List<Map<String, dynamic>> cart = [];

  int get cartCount => cart.length;

  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: _headers,
        body: json.encode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        user = json.decode(response.body)['user'];
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Login Error: $e");
    }
    return false;
  }

  Future<bool> register(Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Register Error: $e");
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, String> data) async {
    try {
      if (user == null) return false;
      final response = await http.post(
        Uri.parse("$baseUrl/user/update"),
        headers: _headers,
        body: json.encode({
          'id': user!['id'].toString(),
          ...data,
        }),
      );
      if (response.statusCode == 200) {
        user = json.decode(response.body)['user'];
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Update Error: $e");
    }
    return false;
  }

  Future<bool> placeOrder() async {
    try {
      if (user == null || cart.isEmpty) return false;
      final response = await http.post(
        Uri.parse("$baseUrl/orders/save"),
        headers: _headers,
        body: json.encode({
          'user_id': user!['id'],
          'total': cart.fold(0.0, (sum, item) {
            double price = double.tryParse(item['price'].toString().replaceAll('P', '')) ?? 0.0;
            int qty = (item['quantity'] ?? 1) as int;
            return sum + (price * qty);
          }),
          'items': cart.map((item) => {
            'food_id': item['id'] ?? 1,
            'qty': item['quantity'] ?? 1,
            'price': item['price'].toString().replaceAll('P', ''),
          }).toList(),
        }),
      );
      if (response.statusCode == 201) {
        cart.clear();
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Order Error: $e");
    }
    return false;
  }

  void logout() {
    user = null;
    cart = [];
    notifyListeners();
  }

  void addToCart(Map<String, dynamic> item) {
    int index = cart.indexWhere((element) => element['name'] == item['name']);
    if (index != -1) {
      int currentQty = (cart[index]['quantity'] ?? 1) as int;
      cart[index]['quantity'] = currentQty + 1;
    } else {
      cart.add({...item, 'quantity': 1});
    }
    notifyListeners();
  }

  void removeFromCart(Map<String, dynamic> item) {
    int index = cart.indexWhere((element) => element['name'] == item['name']);
    if (index != -1) {
      if (cart[index]['quantity'] > 1) {
        cart[index]['quantity'] -= 1;
      } else {
        cart.removeAt(index);
      }
      notifyListeners();
    }
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFF3949AB),
          surface: Colors.white,
          background: const Color(0xFFF8FAFC),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Color(0xFF1A237E), fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Color(0xFF1A237E)),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// --- LOGIN PAGE ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.lock_person_rounded, size: 60, color: Color(0xFF1A237E)),
              ),
              const SizedBox(height: 24),
              const Text("Welcome Back",
                  style: TextStyle(fontSize: 28, color: Color(0xFF1A237E), fontWeight: FontWeight.w800)),
              const Text("Sign in to continue", style: TextStyle(color: Colors.blueGrey)),
              const SizedBox(height: 40),
              _buildField(userCtrl, "Username", Icons.person_outline),
              const SizedBox(height: 16),
              _buildField(passCtrl, "Password", Icons.lock_outline, isPass: true),
              const SizedBox(height: 32),
              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (userCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
                    setState(() => isLoading = true);
                    bool success = await context.read<AppProvider>().login(userCtrl.text, passCtrl.text);
                    setState(() => isLoading = false);
                    if (success) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account not found!")));
                    }
                  },
                  child: const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage())),
                  child: const Text("Don't have an account? Sign Up", style: TextStyle(color: Color(0xFF3949AB))))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String h, IconData i, {bool isPass = false}) {
    return TextField(
      controller: c,
      obscureText: isPass,
      decoration: InputDecoration(
        prefixIcon: Icon(i, color: const Color(0xFF1A237E)),
        hintText: h,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5)),
      ),
    );
  }
}

// --- SIGN UP PAGE ---
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final first_name = TextEditingController();
  final last_name = TextEditingController();
  final email = TextEditingController();
  final contact = TextEditingController();
  final user = TextEditingController();
  final pass = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            _regField(first_name, "First Name"),
            _regField(last_name, "Last Name"),
            _regField(email, "Email Address"),
            _regField(contact, "Contact"),
            _regField(user, "Username"),
            _regField(pass, "Password", isPass: true),
            const SizedBox(height: 30),
            isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (first_name.text.isEmpty || user.text.isEmpty || pass.text.isEmpty || email.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in required fields")));
                    return;
                  }
                  setState(() => isLoading = true);
                  bool success = await context.read<AppProvider>().register({
                    'first_name': first_name.text,
                    'last_name': last_name.text,
                    'email': email.text,
                    'contact': contact.text,
                    'username': user.text,
                    'password': pass.text
                  });
                  setState(() => isLoading = false);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration Successful!")));
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration Failed.")));
                  }
                },
                child: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _regField(TextEditingController c, String h, {bool isPass = false}) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
            controller: c,
            obscureText: isPass,
            decoration: InputDecoration(
              hintText: h,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A237E))),
            )));
  }
}

// --- MAIN NAVIGATION ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(onCartClick: () => setState(() => _index = 1)),
      const OrderHistoryPage(),
      const ProfilePage()
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8EAF6),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu, color: Color(0xFF1A237E)), label: "Menu"),
          NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag, color: Color(0xFF1A237E)), label: "Cart"),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: Color(0xFF1A237E)), label: "Profile")
        ],
      ),
    );
  }
}

// --- HOME PAGE ---
class HomePage extends StatelessWidget {
  final VoidCallback onCartClick;
  const HomePage({super.key, required this.onCartClick});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final List<Map<String, dynamic>> items = [
      {"id": 1, "name": "Adobo", "price": "P120"},
      {"id": 2, "name": "Sinigang", "price": "P150"},
      {"id": 3, "name": "Sisig", "price": "P180"},
      {"id": 4, "name": "Camel", "price": "10"},
      {"id": 5, "name": "Kare-Kare", "price": "120"}
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
          title: const Text("Selection Menu"),
          actions: [
            IconButton(
                onPressed: onCartClick,
                icon: Badge(
                  label: Text("${p.cartCount}"),
                  child: const Icon(Icons.shopping_cart_outlined),
                )
            ),
            const SizedBox(width: 8),
          ]
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          final cartItem = p.cart.firstWhere(
                  (element) => element['name'] == item['name'],
              orElse: () => {'quantity': 0}
          );
          int qty = (cartItem['quantity'] ?? 0) as int;

          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text("${item['name']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              subtitle: Text(item['price'].toString(), style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500)),
              trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: qty > 0 ? const Color(0xFFE8EAF6) : const Color(0xFF1A237E),
                      foregroundColor: qty > 0 ? const Color(0xFF1A237E) : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  onPressed: () => p.addToCart(item),
                  child: Text(qty > 0 ? "Added ($qty)" : "Order")
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- PROFILE PAGE ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showEditDialog(BuildContext context, AppProvider p) {
    final first_nameCtrl = TextEditingController(text: p.user?['first_name']);
    final last_nameCtrl = TextEditingController(text: p.user?['last_name']);
    final emailCtrl = TextEditingController(text: p.user?['email']);
    final contactCtrl = TextEditingController(text: p.user?['contact']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile", style: TextStyle(color: Color(0xFF1A237E))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: first_nameCtrl, decoration: const InputDecoration(labelText: "First Name")),
            TextField(controller: last_nameCtrl, decoration: const InputDecoration(labelText: "Last Name")),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: "Contact")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              bool success = await p.updateProfile({
                'first_name': first_nameCtrl.text,
                'last_name': last_nameCtrl.text,
                'email': emailCtrl.text,
                'contact': contactCtrl.text,
              });
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("My Profile")),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const CircleAvatar(radius: 50, backgroundColor: Color(0xFFE8EAF6), child: Icon(Icons.person, size: 50, color: Color(0xFF1A237E))),
                const SizedBox(height: 16),
                Text("${p.user?['first_name'] ?? 'Guest'} ${p.user?['last_name'] ?? ''}",
                    style: const TextStyle(color: Color(0xFF1A237E), fontSize: 22, fontWeight: FontWeight.bold)),
                Text(p.user?['email'] ?? "Login to see details", style: const TextStyle(color: Colors.blueGrey)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _infoTile(Icons.phone_android_outlined, "Contact", p.user?['contact'] ?? "N/A"),
          _infoTile(Icons.alternate_email_outlined, "Username", p.user?['username'] ?? "N/A"),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
                    onPressed: () => _showEditDialog(context, p),
                    label: const Text("Update Information"),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    p.logout();
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
                  },
                  child: const Text("Logout from account", style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoTile(IconData i, String t, String s) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF1F3F9), borderRadius: BorderRadius.circular(8)), child: Icon(i, color: const Color(0xFF1A237E), size: 20)),
      title: Text(t, style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
      subtitle: Text(s, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
    );
  }
}

// --- ORDER PAGE ---
class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final cart = p.cart;

    return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text("Your Cart")),
        body: cart.isEmpty
            ? const Center(child: Text("Cart is currently empty"))
            : Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cart.length,
                itemBuilder: (c, i) {
                  final item = cart[i];
                  double price = double.tryParse(item['price'].toString().replaceAll('P', '')) ?? 0.0;
                  int qty = (item['quantity'] ?? 1) as int;

                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(item['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("P${(price * qty).toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
                      trailing: Container(
                        decoration: BoxDecoration(color: const Color(0xFFF1F3F9), borderRadius: BorderRadius.circular(30)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.remove, size: 18, color: Colors.redAccent), onPressed: () => p.removeFromCart(item)),
                            Text("$qty", style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.add, size: 18, color: Color(0xFF1A237E)), onPressed: () => p.addToCart(item)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Order", style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                      Text("P${cart.fold(0.0, (sum, item) => sum + (double.tryParse(item['price'].toString().replaceAll('P', '')) ?? 0.0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        bool success = await p.placeOrder();
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order confirmed!")));
                        }
                      },
                      child: const Text("Confirm Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            )
          ],
        )
    );
  }
}
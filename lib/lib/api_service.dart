import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AppProvider extends ChangeNotifier {
  final String baseUrl = "http://127.0.0.1:8000/api";

  Map<String, dynamic>? _user;
  String? _token;
  List<Map<String, dynamic>> _cartItems = [];

  // NEW: Track quantity per food item ID
  Map<int, int> _itemQuantities = {};

  Map<String, dynamic>? get user => _user;
  List<Map<String, dynamic>> get cart => _cartItems;
  int get cartCount => _cartItems.length;

  // Helper to get quantity for a specific item
  int getQuantity(int itemId) => _itemQuantities[itemId] ?? 0;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // 1. REGISTRATION: (Updated to handle email)
  Future<bool> register(Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: _headers,
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 2. LOGIN
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: _headers,
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _user = responseData['user'];
        _token = responseData['token'];
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Login Error: $e");
    }
    return false;
  }

  // 3. SAVES ORDER: Sends items + their quantities to the DB
  Future<bool> submitOrder() async {
    if (_cartItems.isEmpty) return false;
    try {
      // Prepare data with quantities for Laravel
      List<Map<String, dynamic>> itemsWithQty = _cartItems.map((item) {
        return {
          'food_id': item['id'],
          'quantity': _itemQuantities[item['id']],
          'price': item['price'],
        };
      }).toList();

      final response = await http.post(
        Uri.parse("$baseUrl/checkout"),
        headers: _headers,
        body: json.encode({'items': itemsWithQty}),
      );

      if (response.statusCode == 201) {
        _cartItems.clear();
        _itemQuantities.clear();
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Order Error: $e");
    }
    return false;
  }

  // 4. PROFILE MANAGEMENT: Updated to include Email and Name
  Future<bool> updateProfile({required String name, required String email, required String contact, required String address}) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/user/update"),
        headers: _headers,
        body: json.encode({
          'id': _user!['id'].toString(),
          'name': name,
          'email': email,
          'contact': contact,
          'address': address
        }),
      );

      if (response.statusCode == 200) {
        _user = json.decode(response.body)['user'];
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Update Error: $e");
    }
    return false;
  }

  // 5. ADD DYNAMIC FOOD
  Future<bool> addFood(String name, String price) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/foods"),
        headers: _headers,
        body: json.encode({'name': name, 'price': price}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Local Cart Synchronization with Quantity Tracking
  void addToCart(Map<String, dynamic> item) {
    int id = item['id'];

    // Increment quantity
    _itemQuantities[id] = (_itemQuantities[id] ?? 0) + 1;

    // Only add to list if it's not already there
    bool alreadyInList = _cartItems.any((element) => element['id'] == id);
    if (!alreadyInList) {
      _cartItems.add(item);
    }

    notifyListeners();
  }

  // Optional: Remove/Decrease quantity
  void removeFromCart(int itemId) {
    if (_itemQuantities.containsKey(itemId)) {
      if (_itemQuantities[itemId]! > 1) {
        _itemQuantities[itemId] = _itemQuantities[itemId]! - 1;
      } else {
        _itemQuantities.remove(itemId);
        _cartItems.removeWhere((item) => item['id'] == itemId);
      }
      notifyListeners();
    }
  }
}
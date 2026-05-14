import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> register(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final existing = await _dbHelper.getUserByUsername(username);
      if (existing != null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final user = User(
        username: username,
        passwordHash: _hashPassword(password),
        createdAt: DateTime.now().toIso8601String(),
      );

      await _dbHelper.insertUser(user);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _dbHelper.getUserByUsername(username);
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final hashedPassword = _hashPassword(password);
      if (user.passwordHash != hashedPassword) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('logged_in_user_id', user.id!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_user_id');
    _currentUser = null;
    notifyListeners();
  }

  Future<void> checkLoginState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('logged_in_user_id');

      if (userId != null) {
        _currentUser = await _dbHelper.getUserById(userId);
      }
    } catch (e) {
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }
}

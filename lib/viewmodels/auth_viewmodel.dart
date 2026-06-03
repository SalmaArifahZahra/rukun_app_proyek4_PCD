import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/helpers/log_helper.dart';
import 'package:rukun_app_proyek4/models/auth_response_model.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel(this._authRepository) {
    checkAuth();
  }

  bool isLoading = false;
  String? errorMessage;
  AuthResponse? authData;
  int _failedLoginCount = 0;
  bool _isLocked = false;
  int _lockSeconds = 0;

  bool get isLoggedIn => authData != null;
  User? get currentUser => authData?.user;
  bool get isLocked => _isLocked;
  int get lockSeconds => _lockSeconds;
  int get failedLoginCount => _failedLoginCount;

  void initAuth() {
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }

  Future<void> login(String nik, String password) async {
    if (_isLocked) {
      errorMessage =
          "Terlalu banyak percobaan. Coba lagi dalam $_lockSeconds detik";
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    authData = null;

    notifyListeners();

    try {
      final result = await _authRepository.login(nik, password);
      _failedLoginCount = 0;
      errorMessage = null;
      authData = result;
    } catch (e, st) {
      final message = e.toString().replaceAll("Exception: ", "");
      _onLoginFailed(message);

      await LogHelper.writeLog(
        "Login gagal: $message",
        source: "AuthViewModel.login",
        level: 1,
        error: e,
        stackTrace: st,
      );
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> register(
    String nik,
    String password,
    String confirmPassword,
  ) async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      await _authRepository.register(
        nik: nik,
        password: password,
        confirmPassword: confirmPassword,
      );

      _failedLoginCount = 0;
      errorMessage = null;
    } catch (e, st) {
      final message = e.toString().replaceAll("Exception: ", "");
      errorMessage = message;

      await LogHelper.writeLog(
        "Register gagal: $message",
        source: "AuthViewModel.register",
        level: 1,
        error: e,
        stackTrace: st,
      );
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();

    authData = null;
    errorMessage = null;

    _failedLoginCount = 0;
    _isLocked = false;
    _lockSeconds = 0;

    notifyListeners();
  }

  Future<void> checkAuth() async {
    debugPrint("CHECK AUTH START");
    isLoading = true;

    notifyListeners();

    try {
      final token = await _authRepository.getToken();
      debugPrint("TOKEN: $token");

      if (token == null || token.isEmpty) {
        authData = null;
        return;
      }

      final user = await _authRepository.getMe(token);
      debugPrint("USER: $user");

      authData = AuthResponse(token: token, user: user);

      debugPrint("AUTH SUCCESS");
    } catch (e, st) {
      debugPrint("AUTH ERROR: $e");

      if (_isNetworkError(e)) {
        final token = await _authRepository.getToken();
        final cachedUser = await _authRepository.getCachedUser();
        if (token != null && cachedUser != null) {
          authData = AuthResponse(token: token, user: cachedUser);
          debugPrint("AUTH FALLBACK TO CACHED USER");
        } else {
          authData = null;
        }
      } else {
        authData = null;
      }

      await LogHelper.writeLog(
        "CheckAuth gagal: $e",
        source: "AuthViewModel.checkAuth",
        level: 1,
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoading = false;

      notifyListeners();

      debugPrint("CHECK AUTH DONE");
    }
  }

  bool _isNetworkError(Object error) {
    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.unknown => true,
        _ => false,
      };
    }

    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('network is unreachable');
  }

  void _onLoginFailed(String message) {
    _failedLoginCount++;
    errorMessage = message;

    if (_failedLoginCount >= 3) {
      _startLockTimer();
    }
    isLoading = false;

    notifyListeners();
  }

  void _startLockTimer() {
    _isLocked = true;
    _lockSeconds = 10;

    notifyListeners();

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      _lockSeconds--;
      notifyListeners();

      return _lockSeconds > 0;
    }).then((_) {
      _isLocked = false;
      _failedLoginCount = 0;
      _lockSeconds = 0;
      errorMessage = null;

      notifyListeners();
    });
  }
}

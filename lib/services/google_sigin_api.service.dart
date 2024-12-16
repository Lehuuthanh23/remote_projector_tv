import 'dart:async';
import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:stacked_services/stacked_services.dart';

import '../app/app.locator.dart';
import '../app/app.router.dart';

class GoogleSignInService {
  static final _navigationService = appLocator<NavigationService>();
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  static GoogleSignInAccount? _currentUser;
  static Timer? _timer;

  static Future<GoogleSignInAccount?> login() async {
    try {
      return await _googleSignIn.signIn();
    } catch (_) {}

    return null;
  }

  static Future<void> logout() async {
    try {
      await _googleSignIn.disconnect();
      dispose();
    } catch (_) {}
  }

  static Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (_) {}

    return null;
  }

  static Stream<GoogleSignInAccount?> get currentUserStream =>
      _googleSignIn.onCurrentUserChanged;

  static Future<bool> verifyAccessToken(String token) async {
    final response = await http.get(Uri.parse(
        'https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=$token'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['audience'] != null;
    }

    return false;
  }

  static void initialize() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      GoogleSignInAccount? user = await _googleSignIn.signInSilently();
      if (user != null) {
        var auth = await user.authentication;
        var accessToken = auth.accessToken;
        if (accessToken != null) {
          bool isValid = await verifyAccessToken(accessToken);
          if (!isValid) {
            _currentUser = null;
            await logout();
            _navigationService.navigateToLoginPage();
          }
        }
      } else if (_currentUser != null) {
        _currentUser = null;
      }
      _currentUser = user;
    });
  }

  static void dispose() {
    _timer?.cancel();
  }
}

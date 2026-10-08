import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'phone_helper.dart';

class AuthService {
  static const String _kLoggedInUserPhone = 'easymanage_auth_user_phone_v1';
  static const String _kIsUserLoggedIn = 'easymanage_auth_is_logged_in_v1';

  final SharedPreferences prefs;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;

  AuthService(this.prefs);

  bool get isLoggedIn {
    return prefs.getBool(_kIsUserLoggedIn) ?? false;
  }

  String get currentUserPhone {
    final localPhone = prefs.getString(_kLoggedInUserPhone);
    if (localPhone != null && localPhone.isNotEmpty) return localPhone;
    return _firebaseAuth.currentUser?.phoneNumber ?? '';
  }

  /// Sends a 6-digit OTP code to the provided phone number
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onError,
    required Function() onAutoVerified,
  }) async {
    final normalized = PhoneHelper.normalize(phoneNumber);
    if (normalized.isEmpty) {
      onError('Please enter a valid mobile number');
      return;
    }

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: normalized,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _firebaseAuth.signInWithCredential(credential);
          await _saveLoginSession(normalized);
          onAutoVerified();
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Firebase phone verification failed: [${e.code}] ${e.message}');
          String message = e.message ?? 'Phone verification failed';
          if (e.code == 'CONFIGURATION_NOT_FOUND' || (e.message != null && e.message!.contains('CONFIGURATION_NOT_FOUND'))) {
            message = 'Phone Auth is not enabled in Firebase Console yet. Please enable "Phone" in Firebase Console -> Authentication -> Sign-in method, or use "Test Login" below.';
          } else if (e.code == 'invalid-phone-number') {
            message = 'The provided phone number is not valid. Please check and try again.';
          } else if (e.code == 'too-many-requests') {
            message = 'Too many requests. Please wait a few minutes before requesting another code.';
          }
          onError(message);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      debugPrint('sendOtp error: $e');
      onError(e.toString());
    }
  }

  /// Verifies the entered 6-digit OTP code
  Future<bool> verifyOtp({
    required String smsCode,
    required String phoneNumber,
    required Function(String errorMessage) onError,
  }) async {
    final normalized = PhoneHelper.normalize(phoneNumber);

    if (_verificationId == null) {
      onError('Verification session expired. Please request a new code.');
      return false;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode.trim(),
      );

      final result = await _firebaseAuth.signInWithCredential(credential);
      if (result.user != null) {
        await _saveLoginSession(normalized);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('verifyOtp FirebaseAuthException: ${e.message}');
      onError(e.message ?? 'Invalid OTP code');
      return false;
    } catch (e) {
      debugPrint('verifyOtp error: $e');
      onError('Invalid OTP code. Please try again.');
      return false;
    }
  }

  /// Dev / Offline bypass login for instant testing
  Future<void> loginDirectly(String phoneNumber) async {
    final normalized = PhoneHelper.normalize(phoneNumber);
    await _saveLoginSession(normalized);
  }

  Future<void> _saveLoginSession(String phone) async {
    await prefs.setString(_kLoggedInUserPhone, phone);
    await prefs.setBool(_kIsUserLoggedIn, true);
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    await prefs.remove(_kLoggedInUserPhone);
    await prefs.setBool(_kIsUserLoggedIn, false);
  }
}

// // lib/services/clerk_auth_service.dart

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:http/http.dart' as http;

// class ClerkAuthService {
//   // 🔧 Config - เปลี่ยนตาม environment ของคุณ
//   static const String clerkFrontendApi =
//       'YOUR_CLERK_FRONTEND_API'; // เช่น clerk.abc123.lcl.dev
//   static const String backendUrl =
//       'http://YOUR_BACKEND_URL'; // เช่น http://localhost:3000
//   static const String redirectUrl = 'skillwallet://callback';

//   final _storage = const FlutterSecureStorage();

//   // Keys สำหรับเก็บข้อมูล
//   static const String _sessionTokenKey = 'clerk_session_token';
//   static const String _userIdKey = 'clerk_user_id';

//   // ===============================
//   // 1. เปิด Clerk Login Page
//   // ===============================
//   Future<bool> signInWithClerk(BuildContext context) async {
//     try {
//       final signInUrl =
//           'https://$clerkFrontendApi/sign-in?redirect_url=$redirectUrl';

//       final result = await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => _ClerkWebView(
//             url: signInUrl,
//             redirectUrl: redirectUrl,
//           ),
//         ),
//       );

//       if (result != null && result is Map<String, String>) {
//         final token = result['token'];
//         final userId = result['userId'];

//         if (token != null && userId != null) {
//           // เก็บ token ใน secure storage
//           await _storage.write(key: _sessionTokenKey, value: token);
//           await _storage.write(key: _userIdKey, value: userId);
//           return true;
//         }
//       }

//       return false;
//     } catch (e) {
//       debugPrint('❌ Sign in error: $e');
//       return false;
//     }
//   }

//   // ===============================
//   // 2. เปิด Clerk Sign Up Page
//   // ===============================
//   Future<bool> signUpWithClerk(BuildContext context) async {
//     try {
//       final signUpUrl =
//           'https://$clerkFrontendApi/sign-up?redirect_url=$redirectUrl';

//       final result = await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => _ClerkWebView(
//             url: signUpUrl,
//             redirectUrl: redirectUrl,
//           ),
//         ),
//       );

//       if (result != null && result is Map<String, String>) {
//         final token = result['token'];
//         final userId = result['userId'];

//         if (token != null && userId != null) {
//           await _storage.write(key: _sessionTokenKey, value: token);
//           await _storage.write(key: _userIdKey, value: userId);
//           return true;
//         }
//       }

//       return false;
//     } catch (e) {
//       debugPrint('❌ Sign up error: $e');
//       return false;
//     }
//   }

//   // ===============================
//   // 3. Sync User Data กับ Backend
//   // ===============================
//   Future<Map<String, dynamic>?> syncUserData() async {
//     try {
//       final token = await _storage.read(key: _sessionTokenKey);

//       if (token == null) {
//         debugPrint('❌ No session token found');
//         return null;
//       }

//       final response = await http.post(
//         Uri.parse('$backendUrl/api/auth/sync'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data;
//       } else {
//         debugPrint('❌ Sync failed: ${response.statusCode}');
//         return null;
//       }
//     } catch (e) {
//       debugPrint('❌ Sync error: $e');
//       return null;
//     }
//   }

//   // ===============================
//   // 4. Get Session Token
//   // ===============================
//   Future<String?> getSessionToken() async {
//     return await _storage.read(key: _sessionTokenKey);
//   }

//   // ===============================
//   // 5. Check if Logged In
//   // ===============================
//   Future<bool> isLoggedIn() async {
//     final token = await _storage.read(key: _sessionTokenKey);
//     return token != null;
//   }

//   // ===============================
//   // 6. Logout
//   // ===============================
//   Future<void> logout() async {
//     await _storage.delete(key: _sessionTokenKey);
//     await _storage.delete(key: _userIdKey);
//   }
// }

// // ===============================
// // WebView สำหรับแสดง Clerk Login UI
// // ===============================
// class _ClerkWebView extends StatefulWidget {
//   final String url;
//   final String redirectUrl;

//   const _ClerkWebView({
//     required this.url,
//     required this.redirectUrl,
//   });

//   @override
//   State<_ClerkWebView> createState() => _ClerkWebViewState();
// }

// class _ClerkWebViewState extends State<_ClerkWebView> {
//   late InAppWebViewController _controller;
//   bool _isLoading = true;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Sign In'),
//         leading: IconButton(
//           icon: const Icon(Icons.close),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Stack(
//         children: [
//           InAppWebView(
//             initialUrlRequest: URLRequest(url: WebUri(widget.url)),
//             onWebViewCreated: (controller) {
//               _controller = controller;
//             },
//             onLoadStart: (controller, url) {
//               setState(() => _isLoading = true);
//               _checkForCallback(url.toString());
//             },
//             onLoadStop: (controller, url) {
//               setState(() => _isLoading = false);
//             },
//           ),
//           if (_isLoading) const Center(child: CircularProgressIndicator()),
//         ],
//       ),
//     );
//   }

//   // ตรวจสอบว่าได้ redirect กลับมาหรือยัง
//   void _checkForCallback(String url) {
//     if (url.startsWith(widget.redirectUrl)) {
//       // Parse URL parameters
//       final uri = Uri.parse(url);
//       final token = uri.queryParameters['__clerk_session_token'];
//       final userId = uri.queryParameters['__clerk_user_id'];

//       if (token != null && userId != null) {
//         Navigator.pop(context, {
//           'token': token,
//           'userId': userId,
//         });
//       }
//     }
//   }
// }

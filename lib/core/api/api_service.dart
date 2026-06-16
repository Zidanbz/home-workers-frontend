import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home_workers_fe/core/models/address_model.dart';
import 'package:home_workers_fe/core/models/chat_model.dart';
import 'package:home_workers_fe/core/models/message_model.dart';
import 'package:home_workers_fe/core/models/notification_model.dart';
import 'package:home_workers_fe/core/models/order_model.dart';
import 'package:home_workers_fe/core/models/user_model.dart';
import 'package:home_workers_fe/core/models/wallet_model.dart';
import 'package:home_workers_fe/core/models/worker_model.dart';
import 'package:home_workers_fe/features/notifications/pages/notification_page.dart';
import 'package:home_workers_fe/core/services/encryption_service.dart';
import 'package:http/http.dart' as http;
import '../models/service_model.dart'; // Impor model yang baru kita buat

class ApiService {
  final String _baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'https://api-eh5nicgdhq-uc.a.run.app/api';

  // Fungsi login (tidak berubah)
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    print('🔐 [loginUser] Starting login for email: $email');
    final url = Uri.parse('$_baseUrl/auth/login');
    print('🌐 [loginUser] URL: $url');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'fcmToken': fcmToken,
      }),
    );

    print('📊 [loginUser] Response Status: ${response.statusCode}');
    print('📝 [loginUser] Response Body: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ [loginUser] Login successful');
      return jsonDecode(response.body);
    } else {
      print('❌ [loginUser] Login failed');
      throw _asException('Gagal login: ${response.body}');
    }
  }

  // Refresh ID token (untuk always login)
  Future<Map<String, dynamic>> refreshIdToken({
    required String refreshToken,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/refresh-token');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw _asException('Gagal refresh token: ${response.body}');
    }
  }

  Future<void> resendVerificationEmail({
    required String email,
    required String token,
  }) async {
    print('📧 [resendVerificationEmail] Starting for email: $email');
    final url = Uri.parse('$_baseUrl/auth/resend-verification');
    print('🌐 [resendVerificationEmail] URL: $url');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );

    print(
      '📊 [resendVerificationEmail] Response Status: ${response.statusCode}',
    );
    print('📝 [resendVerificationEmail] Response Body: ${response.body}');

    if (response.statusCode != 200) {
      print('❌ [resendVerificationEmail] Failed to resend verification email');
      throw _asException(
        'Gagal mengirim ulang email verifikasi: ${response.body}',
      );
    }
    print('✅ [resendVerificationEmail] Verification email sent successfully');
  }

  // =============================
  // UPDATE FCM TOKEN (setelah login)
  // =============================
  Future<void> updateFcmToken({
    required String token, // ini ID token Bearer untuk backend
    required String fcmToken, // ini FCM token device
  }) async {
    print('🔔 [updateFcmToken] Starting FCM token update');
    final url = Uri.parse('$_baseUrl/auth/update-fcm-token');
    print('🌐 [updateFcmToken] URL: $url');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'fcmToken': fcmToken}),
    );

    print('📊 [updateFcmToken] Response Status: ${response.statusCode}');
    print('📝 [updateFcmToken] Response Body: ${response.body}');

    final responseBody = jsonDecode(response.body);
    if (response.statusCode != 200 || responseBody['success'] != true) {
      final message = responseBody['message'] ?? 'Failed to update FCM token';
      print('❌ [updateFcmToken] Failed: $message');
      throw _asException(message);
    }
    print('✅ [updateFcmToken] FCM token updated successfully');
  }

  // --- FUNGSI BARU ---
  // Mengambil daftar layanan milik worker yang sedang login
  Future<List<Service>> getMyServices(String token) async {
    print('🔧 [getMyServices] Starting to fetch worker services');
    final url = Uri.parse('$_baseUrl/services/my-services');
    print('🌐 [getMyServices] URL: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 [getMyServices] Response Status: ${response.statusCode}');
      print('📝 [getMyServices] Response Body: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final List<dynamic> data = responseBody['data'];
        print('✅ [getMyServices] Found ${data.length} services');
        return data.map((json) => Service.fromJson(json)).toList();
      } else {
        print('❌ [getMyServices] Failed to load services');
        throw _asException(
          responseBody['message'] ?? 'Failed to load services',
        );
      }
    } catch (e) {
      print('❌ [getMyServices] Exception: $e');
      throw _asException('Failed to connect to the server. $e');
    }
  }

  Future<void> forgotPassword(String email) async {
    final url = Uri.parse('$_baseUrl/auth/forgot-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    Map<String, dynamic> decoded = {};
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}

    if (response.statusCode == 200) {
      return;
    } else {
      final message =
          decoded['message'] ?? 'Gagal mengirim email reset password.';
      throw _asException(message);
    }
  }

  /// Set password baru memakai oobCode dari email reset Firebase.
  Future<void> resetPassword({
    required String oobCode,
    required String newPassword,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/reset-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'oobCode': oobCode, 'newPassword': newPassword}),
    );

    Map<String, dynamic> decoded = {};
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}

    if (response.statusCode == 200) {
      return;
    } else {
      final message = decoded['message'] ?? 'Gagal mereset password.';
      throw _asException(message);
    }
  }

  Future<User> getMyProfile(String token) async {
    final url = Uri.parse('$_baseUrl/auth/me');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);
      print('📊 [getMyProfile] Response Status: ${response.statusCode}');
      print('📝 [getMyProfile] Response Body: ${response.body}');
      if (response.statusCode == 200 && responseBody['success'] == true) {
        return User.fromJson(responseBody['data']); // ✅ Ambil dari 'data'
      } else {
        throw _asException(
          responseBody['message'] ?? 'Failed to fetch profile',
        );
      }
    } catch (e) {
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<List<Chat>> getMyChats(String token, String currentUserId) async {
    final url = Uri.parse('$_baseUrl/chats');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final List<dynamic> data = responseBody['data'];
        return data.map((json) => Chat.fromJson(json, currentUserId)).toList();
      } else {
        throw _asException(responseBody['message'] ?? 'Failed to load chats');
      }
    } catch (e) {
      throw _asException('Failed to connect to the server. $e');
    }
  }

  Future<List<Message>> getMessages(String token, String chatId) async {
    final url = Uri.parse('$_baseUrl/chats/$chatId/messages');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final List<dynamic> messagesJson = responseBody['data'];
        return messagesJson.map((json) => Message.fromJson(json)).toList();
      } else {
        print("response body: ${response.body}");

        throw _asException(
          responseBody['message'] ?? 'Failed to load messages',
        );
      }
    } catch (e) {
      print("response body: ${e}");
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<void> sendMessage(String token, String chatId, String text) async {
    final url = Uri.parse('$_baseUrl/chats/$chatId/messages');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'text': text}),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode != 201 || responseBody['success'] != true) {
        throw _asException(responseBody['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      if (e is Exception) {
        throw _asException(e.toString().replaceFirst('Exception: ', ''));
      }
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<Map<String, dynamic>> createService({
    required String token,
    required Map<String, dynamic> serviceData,
  }) async {
    final url = Uri.parse('$_baseUrl/services');

    // 1. Definisikan headers dan body sebagai variabel terpisah
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final encodedBody = jsonEncode(serviceData);

    // 2. Letakkan DEBUG PRINT di sini, SEBELUM mengirim permintaan
    print('====================================');
    print('MENGIRIM PERMINTAAN KE: $url');
    print('HEADERS: $headers');
    print('BODY: $encodedBody');
    print('====================================');

    try {
      // 3. Gunakan variabel yang sudah dibuat di dalam http.post
      final response = await http.post(
        url,
        headers: headers,
        body: encodedBody,
      );

      final responseBody = jsonDecode(response.body);

      // Anda bisa menambahkan print untuk melihat respons dari server
      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE BODY: ${response.body}');

      if (response.statusCode == 201 && responseBody['success'] == true) {
        return responseBody['data'] ?? {};
      } else {
        throw _asException(
          responseBody['message'] ?? 'Failed to create service',
        );
      }
    } catch (e) {
      print('Error saat memanggil API: $e');
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<List<Order>> getMyOrders(String token) async {
    final url = Uri.parse('$_baseUrl/orders/my-orders');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final List<dynamic> workerOrdersJson =
            responseBody['data']['asWorker'] ?? [];
        return workerOrdersJson.map((json) => Order.fromJson(json)).toList();
      } else {
        throw _asException(responseBody['message'] ?? 'Failed to load orders');
      }
    } catch (e) {
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<void> updateMyProfile({
    required String token,
    required Map<String, dynamic> dataToUpdate,
  }) async {
    final url = Uri.parse('$_baseUrl/users/me');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(dataToUpdate),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw _asException(errorBody['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<List<Address>> getMyAddresses(String token) async {
    final url = Uri.parse('$_baseUrl/users/me/addresses');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final List<dynamic> addressList = responseBody['data'];
        return addressList.map((json) => Address.fromJson(json)).toList();
      } else {
        throw _asException(
          responseBody['message'] ?? 'Failed to load addresses',
        );
      }
    } catch (e) {
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<void> addAddress({
    required String token,
    required String label,
    required String fullAddress,
    double? latitude,
    double? longitude,
  }) async {
    final url = Uri.parse('$_baseUrl/users/me/addresses');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'label': label,
          'fullAddress': fullAddress,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201 && responseBody['success'] == true) {
        // Berhasil, tidak perlu return
      } else {
        throw _asException(responseBody['message'] ?? 'Failed to add address');
      }
    } catch (e) {
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<void> deleteAddress({
    required String token,
    required String addressId,
  }) async {
    final url = Uri.parse('$_baseUrl/users/me/addresses/$addressId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return;
      }

      throw _asException(responseBody['message'] ?? 'Failed to delete address');
    } catch (e) {
      if (e is Exception) rethrow;
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<void> addPhotoToService({
    required String token,
    required String serviceId,
    required String photoUrl,
  }) async {
    final url = Uri.parse('$_baseUrl/services/$serviceId/photos');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'photoUrl': photoUrl}),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // Photo added successfully
      } else {
        throw _asException(responseBody['message'] ?? 'Failed to add photo');
      }
    } catch (e) {
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<Service> getServiceById(String serviceId) async {
    final url = Uri.parse('$_baseUrl/services/$serviceId');
    try {
      print('🔍 Fetching service details for ID: $serviceId');
      print('🌐 URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📊 Response Status: ${response.statusCode}');
      print('📄 Response Headers: ${response.headers}');
      print('📝 Response Body: ${response.body}');

      // Handle server errors (5xx status codes)
      if (response.statusCode >= 500) {
        throw _asException(
          'The service is temporarily unavailable. Please try again later.',
        );
      }

      // Handle client errors (4xx status codes)
      if (response.statusCode >= 400) {
        throw _asException('This service is no longer available.');
      }

      // Check if response is HTML (error page) instead of JSON
      if (response.headers['content-type']?.contains('text/html') == true) {
        throw _asException('Server error occurred. Please try again later.');
      }

      // Check for empty response
      if (response.body.isEmpty) {
        throw _asException('Server returned empty response');
      }

      Map<String, dynamic> responseBody;
      try {
        responseBody = jsonDecode(response.body);
      } catch (e) {
        // If JSON parsing fails and it's a server error, provide user-friendly message
        throw _asException(
          'Service temporarily unavailable. Please try again later.',
        );
      }

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return Service.fromJson(responseBody['data']);
      } else {
        throw _asException(
          responseBody['message'] ??
              'Failed to load service details (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      print('❌ Error in getServiceById: $e');
      // Provide more user-friendly error messages
      if (e.toString().contains('temporarily unavailable')) {
        throw _asException(
          'The service is temporarily unavailable. Please try again later.',
        );
      } else if (e.toString().contains('no longer available')) {
        throw _asException('This service is no longer available.');
      } else {
        throw _asException(
          'Unable to load service details. Please check your connection and try again.',
        );
      }
    }
  }

  Future<void> deleteService({
    required String token,
    required String serviceId,
  }) async {
    final url = Uri.parse('$_baseUrl/services/$serviceId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // Delete berhasil
      } else {
        throw _asException(
          responseBody['message'] ?? 'Failed to delete service',
        );
      }
    } catch (e) {
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<void> updateService({
    required String token,
    required String serviceId,
    required Map<String, dynamic> dataToUpdate,
  }) async {
    final url = Uri.parse('$_baseUrl/services/$serviceId');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(dataToUpdate),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // Update berhasil
      } else {
        throw _asException(
          responseBody['message'] ?? 'Failed to update service',
        );
      }
    } catch (e) {
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<Order> getOrderById({
    required String token,
    required String orderId,
  }) async {
    final url = Uri.parse('$_baseUrl/orders/$orderId');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return Order.fromJson(responseBody['data']);
      } else {
        throw _asException(
          responseBody['message'] ?? 'Failed to load order details',
        );
      }
    } catch (e) {
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<void> acceptOrder({
    required String token,
    required String orderId,
  }) async {
    final url = Uri.parse('$_baseUrl/orders/$orderId/accept');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // Accepted successfully
      } else {
        throw _asException(responseBody['message'] ?? 'Failed to accept order');
      }
    } catch (e) {
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<String> createChat({
    required String token,
    required String recipientId,
  }) async {
    final url = Uri.parse('$_baseUrl/chats');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'recipientId': recipientId}),
      );

      final responseBody = jsonDecode(response.body);

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          responseBody['success'] == true) {
        return responseBody['data']['chatId'];
      } else {
        throw _asException(
          responseBody['message'] ?? 'Failed to create or get chat',
        );
      }
    } catch (e) {
      if (e is Exception) {
        throw _asException(e.toString().replaceFirst('Exception: ', ''));
      }
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<Map<String, dynamic>> getDashboardSummary(String token) async {
    final url = Uri.parse('$_baseUrl/workers/dashboard/summary');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);
      print('URL: $url');
      print('Token: $token');
      print('Status code: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return Map<String, dynamic>.from(responseBody['data'] ?? {});
      } else {
        throw _asException(
          responseBody['message'] ??
              'Server returned status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error: $e');
      throw _asException('Network error: $e');
    }
  }

  Future<void> markChatAsRead(String token, String chatId) async {
    final url = Uri.parse('$_baseUrl/chats/$chatId/read');
    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      // Opsional: jika ingin memastikan response berhasil
      final responseBody = jsonDecode(response.body);
      if (response.statusCode != 200 || responseBody['success'] != true) {
        throw _asException(responseBody['message'] ?? 'Failed to mark as read');
      }
    } catch (e) {
      // Biarkan error tidak mengganggu UI
      print('Mark chat as read error: $e');
    }
  }

  Future<Wallet> getMyWallet(String token) async {
    final url = Uri.parse('$_baseUrl/wallet/me');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return Wallet.fromJson(responseBody['data']);
      } else {
        throw _asException(responseBody['message'] ?? 'Failed to load wallet');
      }
    } catch (e) {
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<List<Service>> getAllApprovedServices({String? category}) async {
    print('📋 [getAllApprovedServices] Starting to fetch approved services');
    print('📋 [getAllApprovedServices] Category filter: $category');

    // Build URL with category query parameter if provided
    final uri = Uri.parse('$_baseUrl/services').replace(
      queryParameters: category != null && category.isNotEmpty
          ? {'category': category}
          : null,
    );

    print('🌐 [getAllApprovedServices] URL: $uri');

    try {
      final response = await http.get(uri);
      print(
        '📊 [getAllApprovedServices] Response Status: ${response.statusCode}',
      );
      print('📝 [getAllApprovedServices] Response Body: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final services = (responseBody['data'] as List)
            .map((json) => Service.fromJson(json))
            .toList();
        print(
          '✅ [getAllApprovedServices] Found ${services.length} approved services',
        );
        return services;
      } else {
        print('❌ [getAllApprovedServices] Failed to load services');
        throw _asException(
          responseBody['message'] ?? 'Failed to load services',
        );
      }
    } catch (e) {
      print('❌ [getAllApprovedServices] Exception: $e');
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<Map<String, dynamic>> getCustomerDashboardSummary() async {
    final url = Uri.parse('$_baseUrl/dashboard/customer-summary');
    try {
      final response = await http.get(url);

      final responseBody = jsonDecode(response.body);
      print("response body: ${response.body}");
      if (response.statusCode == 200 && responseBody['success'] == true) {
        return responseBody['data'];
      } else {
        throw _asException(
          responseBody['message'] ?? 'Failed to load dashboard summary',
        );
      }
    } catch (e) {
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<List<Order>> getMyOrdersCustomer(
    String token, {
    bool asWorker = false,
  }) async {
    final url = Uri.parse('$_baseUrl/orders/my-orders');

    try {
      print('🔍 Fetching orders for ${asWorker ? 'worker' : 'customer'}');
      print('🌐 URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 Response Status: ${response.statusCode}');
      print('📄 Response Headers: ${response.headers}');
      print('📝 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        if (responseBody['success'] != true) {
          throw _asException(
            responseBody['message'] ?? 'API returned success=false',
          );
        }

        // ✅ Akses ke dalam key "data" dulu
        final ordersJson =
            responseBody['data'][asWorker ? 'asWorker' : 'asCustomer'] ?? [];

        print("✅ Jumlah pesanan: ${ordersJson.length}");

        // Debug each order to see what data is missing
        for (int i = 0; i < ordersJson.length; i++) {
          final orderData = ordersJson[i];
          print("📋 Order $i data:");
          print("  - serviceName: ${orderData['serviceName']}");
          print("  - category: ${orderData['category']}");
          print("  - status: ${orderData['status']}");
          print("  - id: ${orderData['id']}");
        }

        return ordersJson.map<Order>((json) => Order.fromJson(json)).toList();
      } else {
        final errorBody = jsonDecode(response.body);
        throw _asException(
          errorBody['message'] ??
              'Failed to load orders (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      print("❌ Error in getMyOrdersCustomer: $e");
      throw _asException('Failed to connect to the server. $e');
    }
  }

  Future<List<NotificationItem>> getMyNotifications(String token) async {
    print('🔔 [getMyNotifications] Starting to fetch notifications');
    final url = Uri.parse('$_baseUrl/users/me/notifications');
    print('🌐 [getMyNotifications] URL: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 [getMyNotifications] Response Status: ${response.statusCode}');
      print('📝 [getMyNotifications] Response Body: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final List<dynamic> data = responseBody['data'];
        print('✅ [getMyNotifications] Found ${data.length} notifications');
        return data.map((json) => NotificationItem.fromJson(json)).toList();
      } else {
        print('❌ [getMyNotifications] Failed to fetch notifications');
        throw _asException(
          responseBody['message'] ?? 'Failed to fetch notifications',
        );
      }
    } catch (e) {
      print('❌ [getMyNotifications] Exception: $e');
      throw _asException('Failed to connect to the server. $e');
    }
  }

  // Future<Map<String, dynamic>> createOrder({
  //   required String token,
  //   required String serviceId,
  //   required DateTime jadwalPerbaikan,
  //   String? catatan,
  // }) async {
  //   final url = Uri.parse('$_baseUrl/orders');
  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //       body: jsonEncode({
  //         'serviceId': serviceId,
  //         'jadwalPerbaikan': jadwalPerbaikan.toIso8601String(),
  //         'catatan': catatan ?? '',
  //       }),
  //     );
  //     print("response: ${response.body}");
  //     final responseBody = jsonDecode(response.body);
  //     if (response.statusCode == 201) {
  //       return responseBody; // Kembalikan respons yang berisi orderId
  //     } else {
  //       throw _asException(responseBody['message'] ?? 'Failed to create order');
  //     }
  //   } catch (e) {
  //     print("error: $e");
  //     throw _asException('Failed to connect to the server.');
  //   }
  // }

  Future<void> processPayment({
    required String token,
    required String orderId,
    required String paymentMethod,
  }) async {
    // Di aplikasi nyata, endpoint ini akan berinteraksi dengan payment gateway.
    // Untuk saat ini, kita akan buat endpoint dummy di backend yang hanya mengubah status order.
    // Mari kita asumsikan endpointnya adalah PUT /api/orders/:orderId/pay
    final url = Uri.parse('$_baseUrl/orders/$orderId/pay');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'paymentMethod': paymentMethod}),
      );
      print("response: ${response.body}");
      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw _asException(errorBody['message'] ?? 'Failed to process payment');
      }
    } catch (e) {
      print("error: $e");
      throw _asException('Failed to connect to the server.');
    }
  }

  Future<String> initiatePayment(String token, String orderId) async {
    final url = Uri.parse('$_baseUrl/payments/initiate');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'orderId': orderId}),
      );
      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return responseBody['data']['token'];
      } else {
        throw _asException(responseBody['message']);
      }
    } catch (e) {
      throw _asException('Failed to initiate payment.');
    }
  }

  Future<List<Service>> getServicesByCategory(
    String category,
    String token,
  ) async {
    final url = Uri.parse('$_baseUrl/services/category/$category');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('Headers: ${response.headers}');
      if (response.statusCode == 200 && responseBody['success'] == true) {
        final List<dynamic> data = responseBody['data'];
        return data.map((item) => Service.fromJson(item)).toList();
      } else {
        throw _asException(
          responseBody['message'] ?? 'Failed to fetch services',
        );
      }
    } catch (e) {
      print('Error: $e');
      throw _asException('Failed to connect to the server. $e');
    }
  }

  Future<void> registerCustomer({
    required String email,
    required String password,
    required String nama,
    String? fcmToken,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/register/customer');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'nama': nama,
        'fcmToken': fcmToken,
      }),
    );

    if (response.statusCode != 201) {
      final message =
          _extractStructuredErrorMessage(response.body) ??
          'Gagal registrasi customer.';
      throw _asException(message);
    }
  }

  Future<void> registerWorker({
    required String email,
    required String password,
    required String nama,
    required List<String> keahlian,
    required String deskripsi,
    required File ktpFile,
    required File fotoDiriFile,
    String? portfolioLink,
    String? noKtp,
    String? fcmToken,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/register/worker');
    final encryptionService = EncryptionService();

    try {
      // Encrypt KTP file
      final ktpBytes = await ktpFile.readAsBytes();
      final encryptedKtpBytes = encryptionService.encryptFileData(ktpBytes);
      final secureKtpFilename = encryptionService.generateSecureFilename(
        ktpFile.path,
      );

      // Encrypt foto diri file
      final fotoDiriBytes = await fotoDiriFile.readAsBytes();
      final encryptedFotoDiriBytes = encryptionService.encryptFileData(
        fotoDiriBytes,
      );
      final secureFotoDiriFilename = encryptionService.generateSecureFilename(
        fotoDiriFile.path,
      );

      // Hash sensitive data
      final hashedNoKtp = noKtp != null
          ? encryptionService.hashSensitiveData(noKtp)
          : '';

      final request = http.MultipartRequest('POST', url)
        ..fields['email'] = email
        ..fields['password'] = password
        ..fields['nama'] = nama
        ..fields['deskripsi'] = deskripsi
        ..fields['keahlian'] = jsonEncode(keahlian)
        ..fields['linkPortofolio'] = portfolioLink ?? ''
        ..fields['noKtp'] = hashedNoKtp
        ..fields['fcmToken'] = fcmToken ?? ''
        ..fields['isEncrypted'] =
            'true' // Flag to indicate encrypted files
        ..files.add(
          http.MultipartFile.fromBytes(
            'ktp',
            encryptedKtpBytes,
            filename: secureKtpFilename,
          ),
        )
        ..files.add(
          http.MultipartFile.fromBytes(
            'fotoDiri',
            encryptedFotoDiriBytes,
            filename: secureFotoDiriFilename,
          ),
        );

      print('🔐 [registerWorker] Uploading encrypted files');
      print('🔐 [registerWorker] KTP filename: $secureKtpFilename');
      print('🔐 [registerWorker] Foto diri filename: $secureFotoDiriFilename');

      final response = await request.send();
      if (response.statusCode != 201) {
        final responseBody = await response.stream.bytesToString();
        final message =
            _extractStructuredErrorMessage(responseBody) ??
            'Gagal registrasi worker.';
        throw _asException(message);
      }

      print(
        '✅ [registerWorker] Worker registered successfully with encrypted files',
      );
    } catch (e) {
      print('❌ [registerWorker] Failed to register worker: $e');
      rethrow;
    }
  }

  Future<void> proposeQuote({
    required String token,
    required String orderId,
    required num proposedPrice,
  }) async {
    final url = Uri.parse('$_baseUrl/orders/$orderId/quote');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'price': proposedPrice}),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // Quote dikirim berhasil
      } else {
        throw _asException(responseBody['message'] ?? 'Gagal mengirim quote');
      }
    } catch (e) {
      throw _asException('Gagal terhubung ke server. $e');
    }
  }

  Future<void> rejectOrder({
    required String token,
    required String orderId,
  }) async {
    final url = Uri.parse('$_baseUrl/orders/$orderId/reject');
    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode != 200 || responseBody['success'] != true) {
        throw _asException(responseBody['message'] ?? 'Gagal menolak pesanan');
      }
    } catch (e) {
      throw _asException('Gagal terhubung ke server. $e');
    }
  }

  Future<Map<String, dynamic>> getWorkerProfile({
    required String token,
    required String workerId,
  }) async {
    final url = Uri.parse('$_baseUrl/workers/$workerId');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw _asException('Gagal memuat profil worker');
    }

    return jsonDecode(response.body)['data'];
  }

  Future<List<Service>> searchServices({
    String? search,
    String? category,
  }) async {
    var queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (category != null && category.isNotEmpty)
      queryParams['category'] = category;

    final uri = Uri.parse(
      '$_baseUrl/services/search',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Service>.from(
        data['data'].map((item) => Service.fromJson(item)),
      );
    } else {
      throw _asException('Gagal mengambil layanan');
    }
  }

  Future<Map<String, dynamic>> createOrderWithPayment({
    required String token,
    required String serviceId,
    required DateTime jadwalPerbaikan,
    required String catatan,
    String? voucherCode,
    String? locationMode,
    String? savedAddressId,
    String? customAddress,
    double? customLatitude,
    double? customLongitude,
  }) async {
    print('🚀 [createOrderWithPayment] Starting payment process');
    print('🔗 [createOrderWithPayment] Service ID: $serviceId');
    print('📅 [createOrderWithPayment] Schedule: $jadwalPerbaikan');
    print('📝 [createOrderWithPayment] Notes: $catatan');
    print('🎫 [createOrderWithPayment] Voucher: $voucherCode');

    final url = Uri.parse('$_baseUrl/payments/with-order');
    print('🌐 [createOrderWithPayment] URL: $url');

    final requestBody = {
      'serviceId': serviceId,
      'jadwalPerbaikan': jadwalPerbaikan.toIso8601String(),
      'catatan': catatan ?? '',
      if (voucherCode != null) 'voucherCode': voucherCode,
      if (locationMode != null) 'locationMode': locationMode,
      if (savedAddressId != null) 'savedAddressId': savedAddressId,
      if (customAddress != null) 'customAddress': customAddress,
      if (customLatitude != null) 'customLatitude': customLatitude,
      if (customLongitude != null) 'customLongitude': customLongitude,
    };

    print(
      '📦 [createOrderWithPayment] Request Body: ${jsonEncode(requestBody)}',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print(
        '📊 [createOrderWithPayment] Response Status: ${response.statusCode}',
      );
      print(
        '📄 [createOrderWithPayment] Response Headers: ${response.headers}',
      );
      print('📝 [createOrderWithPayment] Response Body: ${response.body}');

      // Check if response body is empty
      if (response.body.isEmpty) {
        print('❌ [createOrderWithPayment] Empty response body');
        throw _asException('Server returned empty response');
      }

      // Check if response is HTML (error page)
      if (response.headers['content-type']?.contains('text/html') == true) {
        print('❌ [createOrderWithPayment] Received HTML instead of JSON');
        throw _asException('Server error - received HTML response');
      }

      Map<String, dynamic> responseBody;
      try {
        responseBody = jsonDecode(response.body);
        print('✅ [createOrderWithPayment] Successfully parsed JSON response');
      } catch (e) {
        print('❌ [createOrderWithPayment] Failed to parse JSON: $e');
        print('📝 [createOrderWithPayment] Raw response: ${response.body}');
        throw _asException('Invalid JSON response from server');
      }

      if (response.statusCode == 201 && responseBody['success'] == true) {
        final data = responseBody['data'];
        print('✅ [createOrderWithPayment] Success! Data: $data');

        // Ensure data is not null and is a Map
        if (data == null) {
          print('❌ [createOrderWithPayment] Data is null');
          throw _asException('Server returned null data');
        }

        if (data is! Map<String, dynamic>) {
          print(
            '❌ [createOrderWithPayment] Data is not a Map: ${data.runtimeType}',
          );
          throw _asException('Server returned invalid data format');
        }

        return data;
      } else {
        String message = responseBody['message'] ?? 'Terjadi kesalahan';
        final errors = responseBody['errors'];
        if (errors is List && errors.isNotEmpty) {
          message = errors.first.toString();
        }
        print('❌ [createOrderWithPayment] API Error: $message');
        print('❌ [createOrderWithPayment] Status Code: ${response.statusCode}');
        print(
          '❌ [createOrderWithPayment] Success Flag: ${responseBody['success']}',
        );
        throw _asException(message);
      }
    } catch (e) {
      print('❌ [createOrderWithPayment] Exception caught: $e');
      print('❌ [createOrderWithPayment] Exception type: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMidtransStatus({
    required String token,
    required String orderId,
  }) async {
    final url = Uri.parse('$_baseUrl/payments/status/$orderId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    Map<String, dynamic>? decoded;
    try {
      if (response.body.isNotEmpty) {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) decoded = parsed;
      }
    } catch (_) {
      // Ignore; we'll fall back to generic error below.
    }

    if (response.statusCode == 200) {
      return decoded?['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    }

    final serverMessage = decoded?['message']?.toString().trim();
    final message = (serverMessage != null && serverMessage.isNotEmpty)
        ? serverMessage
        : 'Gagal mengambil status transaksi Midtrans (HTTP ${response.statusCode}).';
    throw _asException(message);
  }

  Future<List<String>> getBookedSlots({
    required String token,
    required String workerId,
    required String date, // Format: yyyy-MM-dd
  }) async {
    final url = Uri.parse(
      '$_baseUrl/orders/booked-slots?workerId=$workerId&date=$date',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200 && responseBody['success'] == true) {
      return List<String>.from(responseBody['data']);
    } else {
      throw _asException(
        responseBody['message'] ?? 'Failed to fetch booked slots',
      );
    }
  }

  /// Request withdrawal (Worker Only) - Fixed according to documentation
  Future<void> requestWithdraw({
    required String token,
    required int amount,
    required String bankAccount,
    required String bankName,
  }) async {
    final url = Uri.parse('$_baseUrl/wallet/me/withdraw');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'destination': {
            'type': 'bank',
            'bankName': bankName,
            'bankAccount': bankAccount,
          },
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode != 200 || responseBody['success'] != true) {
        throw _asException(
          responseBody['message'] ?? 'Failed to request withdrawal',
        );
      }
    } catch (e) {
      throw _asException('Failed to connect to the server. $e');
    }
  }

  // =============================
  // MISSING ORDER ENDPOINTS
  // =============================

  /// Complete order (Worker Only)
  Future<void> completeOrder({
    required String token,
    required String orderId,
  }) async {
    final url = Uri.parse('$_baseUrl/orders/$orderId/complete');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode != 200 || responseBody['success'] != true) {
        throw _asException(
          responseBody['message'] ?? 'Failed to complete order',
        );
      }
    } catch (e) {
      throw _asException('Failed to connect to the server. $e');
    }
  }

  /// Cancel order (Customer Only)
  Future<void> cancelOrder({
    required String token,
    required String orderId,
  }) async {
    final url = Uri.parse('$_baseUrl/orders/$orderId/cancel');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode != 200 || responseBody['success'] != true) {
        throw _asException(responseBody['message'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      throw _asException('Failed to connect to the server. $e');
    }
  }

  /// Get worker availability
  Future<Map<String, dynamic>> getWorkerAvailability({
    required String token,
    required String workerId,
    required String date, // Format: YYYY-MM-DD
  }) async {
    final url = Uri.parse('$_baseUrl/orders/availability/$workerId?date=$date');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return responseBody['data'];
      } else {
        throw _asException(
          responseBody['message'] ?? 'Failed to get availability',
        );
      }
    } catch (e) {
      throw _asException('Failed to connect to the server. $e');
    }
  }

  Future<void> markNotificationAsRead({
    required String token,
    required String notificationId,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/notifications/$notificationId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw _asException('Gagal menandai notifikasi sebagai dibaca');
    }
  }

  Future<void> updateOrderStatus({
    required String token,
    required String orderId,
    required String newStatus,
  }) async {
    final url = Uri.parse('$_baseUrl/orders/$orderId/status');

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': newStatus}),
    );
    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode != 200) {
      throw _asException(
        jsonDecode(response.body)['message'] ??
            'Gagal memperbarui status order',
      );
    }
  }

  Future<void> respondToQuote({
    required String token,
    required String orderId,
    required String decision,
    String? voucherCode,
  }) async {
    final url = Uri.parse('$_baseUrl/orders/$orderId/quote/respond');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'decision': decision}),
    );

    if (response.statusCode != 200) {
      throw _asException('Failed to respond to quote: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> startPaymentForQuote({
    required String token,
    required String orderId,
    String? voucherCode,
  }) async {
    print('💳 [startPaymentForQuote] Starting payment for quote');
    print('💳 [startPaymentForQuote] Order ID: $orderId');
    print('🎫 [startPaymentForQuote] Voucher: $voucherCode');

    final url = Uri.parse('$_baseUrl/payments/start/$orderId');
    print('💳 [startPaymentForQuote] URL: $url');

    final requestBody = <String, dynamic>{};
    if (voucherCode != null) {
      requestBody['voucherCode'] = voucherCode;
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: requestBody.isNotEmpty ? jsonEncode(requestBody) : null,
      );

      print(
        '💳 [startPaymentForQuote] Response Status: ${response.statusCode}',
      );
      print('💳 [startPaymentForQuote] Response Headers: ${response.headers}');
      print('💳 [startPaymentForQuote] Response Body: ${response.body}');

      // Check if response body is empty
      if (response.body.isEmpty) {
        print('❌ [startPaymentForQuote] Empty response body');
        throw _asException('Server returned empty response');
      }

      // Check if response is HTML (error page)
      if (response.headers['content-type']?.contains('text/html') == true) {
        print('❌ [startPaymentForQuote] Received HTML instead of JSON');
        throw _asException('Server error - received HTML response');
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
        print('✅ [startPaymentForQuote] Successfully parsed JSON response');
      } catch (e) {
        print('❌ [startPaymentForQuote] Failed to parse JSON: $e');
        print('📝 [startPaymentForQuote] Raw response: ${response.body}');
        throw _asException('Invalid JSON response from server');
      }

      if (response.statusCode == 200 && data['success'] == true) {
        final responseData = data['data'];
        print('✅ [startPaymentForQuote] Success! Data: $responseData');

        // Ensure data is not null and is a Map
        if (responseData == null) {
          print('❌ [startPaymentForQuote] Data is null');
          throw _asException('Server returned null data');
        }

        if (responseData is! Map<String, dynamic>) {
          print(
            '❌ [startPaymentForQuote] Data is not a Map: ${responseData.runtimeType}',
          );
          throw _asException('Server returned invalid data format');
        }

        return responseData; // { orderId, snapToken }
      } else {
        final message = data['message'] ?? 'Gagal memulai pembayaran';
        print('❌ [startPaymentForQuote] API Error: $message');
        print('❌ [startPaymentForQuote] Status Code: ${response.statusCode}');
        print('❌ [startPaymentForQuote] Success Flag: ${data['success']}');
        throw _asException(message);
      }
    } catch (e) {
      print('❌ [startPaymentForQuote] Exception caught: $e');
      print('❌ [startPaymentForQuote] Exception type: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<void> submitReview({
    required String token,
    required String orderId,
    required int rating,
    required String comment,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/reviews/orders/$orderId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'rating': rating, 'comment': comment}),
    );

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw _asException(data['message'] ?? 'Gagal mengirim ulasan');
    }
  }

  Future<Worker> getWorkerById(String workerId) async {
    final url = Uri.parse('$_baseUrl/workers/$workerId');
    final response = await http.get(url);

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return Worker.fromJson(body['data']);
    } else {
      throw _asException(body['message'] ?? 'Gagal ambil data worker');
    }
  }

  // =============================
  // MISSING WORKER ENDPOINTS
  // =============================

  /// Get my worker profile (Worker Only)
  Future<Map<String, dynamic>> getMyWorkerProfile(String token) async {
    final url = Uri.parse('$_baseUrl/workers/profile/me');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return responseBody['data'];
      } else {
        throw _asException(
          responseBody['message'] ?? 'Failed to fetch worker profile',
        );
      }
    } catch (e) {
      throw _asException('Failed to connect to the server. $e');
    }
  }

  /// Update my worker profile (Worker Only)
  Future<void> updateMyWorkerProfile({
    required String token,
    required Map<String, dynamic> dataToUpdate,
  }) async {
    final url = Uri.parse('$_baseUrl/workers/profile/me');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(dataToUpdate),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode != 200 || responseBody['success'] != true) {
        throw _asException(
          responseBody['message'] ?? 'Failed to update worker profile',
        );
      }
    } catch (e) {
      throw _asException('Failed to connect to the server. $e');
    }
  }

  /// Get all workers (Public)
  Future<List<Worker>> getAllWorkers() async {
    final url = Uri.parse('$_baseUrl/workers');
    try {
      final response = await http.get(url);

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final List<dynamic> data = responseBody['data'];
        return data.map((json) => Worker.fromJson(json)).toList();
      } else {
        throw _asException(responseBody['message'] ?? 'Failed to load workers');
      }
    } catch (e) {
      throw _asException('Failed to connect to the server. $e');
    }
  }

  // =============================
  // USER MANAGEMENT ENDPOINTS
  // =============================

  /// Update avatar with file upload (multipart/form-data)
  Future<String> updateAvatarWithFile({
    required String token,
    required File avatarFile,
  }) async {
    final url = Uri.parse('$_baseUrl/users/me/avatar');
    try {
      final request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          await http.MultipartFile.fromPath('avatar', avatarFile.path),
        );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final decoded = jsonDecode(responseBody);

      if (response.statusCode == 200 && decoded['success'] == true) {
        return decoded['data']['avatarUrl'];
      } else {
        throw _asException(decoded['message'] ?? 'Failed to update avatar');
      }
    } catch (e) {
      throw _asException('Failed to connect to the server. $e');
    }
  }

  /// Get user avatar
  Future<String?> getAvatar(String token) async {
    print('🖼️ [getAvatar] Starting to fetch user avatar');
    final url = Uri.parse('$_baseUrl/users/me/avatar');
    print('🌐 [getAvatar] URL: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 [getAvatar] Response Status: ${response.statusCode}');
      print('📝 [getAvatar] Response Body: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final avatarUrl = responseBody['data']['avatarUrl'];
        print('✅ [getAvatar] Avatar fetched successfully: $avatarUrl');
        return avatarUrl;
      } else {
        print('❌ [getAvatar] Failed to fetch avatar');
        throw _asException(responseBody['message'] ?? 'Failed to fetch avatar');
      }
    } catch (e) {
      print('❌ [getAvatar] Exception: $e');
      throw _asException('Failed to connect to the server. $e');
    }
  }

  /// Update avatar with URL (for backward compatibility)
  Future<void> updateAvatar({
    required String token,
    required String avatarUrl,
  }) async {
    final url = Uri.parse('$_baseUrl/users/me/avatar');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'avatarUrl': avatarUrl}),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode != 200 || responseBody['success'] != true) {
        throw _asException(responseBody['message'] ?? 'Gagal update avatar');
      }
    } catch (e) {
      throw _asException('Terjadi kesalahan: $e');
    }
  }

  /// Upload documents (Worker Only)
  Future<void> uploadDocuments({
    required String token,
    File? ktpFile,
    File? portfolioFile,
  }) async {
    final url = Uri.parse('$_baseUrl/users/me/documents');
    try {
      final request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token';

      if (ktpFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('ktp', ktpFile.path),
        );
      }
      if (portfolioFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('portfolio', portfolioFile.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final decoded = jsonDecode(responseBody);

      if (response.statusCode != 200 || decoded['success'] != true) {
        throw _asException(decoded['message'] ?? 'Failed to upload documents');
      }
    } catch (e) {
      throw _asException('Failed to connect to the server. $e');
    }
  }

  /// Validasi voucher sebelum membuat order
  /// Mengembalikan: { voucherCode, discount, finalTotal, message }
  Future<Map<String, dynamic>> validateVoucherCode({
    required String token,
    required String voucherCode,
    required int orderAmount,
  }) async {
    final uri = Uri.parse('$_baseUrl/vouchers/validate');

    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'voucherCode': voucherCode.trim(),
        'orderAmount': orderAmount,
      }),
    );

    Map<String, dynamic> body;
    try {
      body = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      throw _asException(
        'Format respons tidak valid dari server (kode: ${resp.statusCode}).',
      );
    }

    // Struktur backend versi helper menggunakan sendSuccess/sendError:
    // success: bool, message: string, data: {...}
    final success = body['success'] == true;

    if (!success) {
      // Ambil pesan error spesifik dari errors array jika ada
      final errors = body['errors'] as List<dynamic>?;
      final msg = errors != null && errors.isNotEmpty
          ? errors.first.toString()
          : (body['message'] ?? 'Validasi voucher gagal.');
      throw _asException(msg);
    }

    final data = (body['data'] ?? {}) as Map<String, dynamic>;

    return {
      'voucherCode': data['voucherCode'],
      'discount': data['discount'] ?? 0,
      'finalTotal': data['finalTotal'],
      'message': data['message'] ?? body['message'],
    };
  }

  Future<Map<String, dynamic>> claimVoucher({
    required String token,
    required String voucherCode,
  }) async {
    final uri = Uri.parse('$_baseUrl/vouchers/claim');

    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'voucherCode': voucherCode.trim()}),
    );

    Map<String, dynamic> body;
    try {
      body = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      throw _asException(
        'Format respons tidak valid dari server (kode: ${resp.statusCode}).',
      );
    }

    if (body['success'] != true) {
      throw _asException(body['message'] ?? 'Gagal klaim voucher.');
    }

    return body['data'] ?? {};
  }

  Future<Map<String, dynamic>> getAvailableVouchers({
    required String token,
  }) async {
    final uri = Uri.parse('$_baseUrl/vouchers/');

    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      throw _asException(
        'Gagal parsing respons server (status: ${resp.statusCode}).',
      );
    }

    final success = decoded['success'] == true;
    if (!success) {
      throw _asException(decoded['message'] ?? 'Gagal mengambil voucher.');
    }

    final data = decoded['data'] as Map<String, dynamic>? ?? {};
    // Pastikan selalu ada struktur minimal
    final global =
        (data['global'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        <Map<String, dynamic>>[];
    final user =
        (data['user'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        <Map<String, dynamic>>[];

    return {'global': global, 'user': user};
  }

  static String readableError(
    dynamic error, {
    String? action,
    String fallback = 'Terjadi kesalahan. Silakan coba lagi.',
  }) {
    final raw = error?.toString() ?? '';
    final formatted = ApiService()._friendlyMessage(raw).trim();
    final message = formatted.isEmpty ? fallback : formatted;
    final actionText = action?.trim();

    if (actionText == null || actionText.isEmpty) {
      return message;
    }

    final actionLower = actionText.toLowerCase();
    final messageLower = message.toLowerCase();

    if (messageLower.startsWith(actionLower) ||
        messageLower.contains('$actionLower:')) {
      return message;
    }

    return '$actionText: $message';
  }

  Exception _asException(dynamic message) {
    return AppException(readableError(message));
  }

  String _friendlyMessage(String raw) {
    final source = raw.trim();
    if (source.isEmpty) {
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }

    final extracted = _extractStructuredErrorMessage(source);
    final message = _normalizeErrorMessage(extracted ?? source);
    if (message.isEmpty) {
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }

    final lower = message.toLowerCase();

    // Network / connectivity
    if (lower.contains('failed to connect to the server') ||
        lower.contains('network error') ||
        lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('handshakeexception') ||
        lower.contains('timed out')) {
      return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    }

    // Auth / session
    if (lower.contains('token expired') || lower.contains('unauthorized')) {
      return 'Sesi Anda berakhir. Silakan login kembali.';
    }
    if (lower.contains('invalid token')) {
      return 'Token tidak valid. Silakan login kembali.';
    }
    if (lower.contains('email atau kata sandi salah') ||
        lower.contains('wrong-password') ||
        lower.contains('invalid credential') ||
        lower.contains('auth/invalid-credential')) {
      return 'Email atau kata sandi salah.';
    }
    if (lower.contains('user account has been disabled') ||
        lower.contains('user-disabled') ||
        lower.contains('akun anda telah dinonaktifkan')) {
      return 'Akun Anda telah dinonaktifkan. Hubungi admin.';
    }

    if (lower.startsWith('gagal login')) {
      return 'Gagal login. Periksa email dan kata sandi Anda.';
    }

    if (lower.startsWith('gagal refresh token')) {
      return 'Sesi Anda berakhir. Silakan login kembali.';
    }

    // Common auth/registration details from Firebase/backend
    if (lower.contains('email address is already in use') ||
        lower.contains('email already registered') ||
        lower.contains('email already in use') ||
        lower.contains('auth/email-already-in-use')) {
      return 'Email sudah terdaftar. Gunakan email lain atau login.';
    }
    if (lower.contains('invalid email format') ||
        lower.contains('invalid-email') ||
        lower.contains('email address is badly formatted')) {
      return 'Format email tidak valid.';
    }
    if (lower.contains('password is too weak') ||
        lower.contains('weak password') ||
        lower.contains('weak-password')) {
      return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
    }
    if (lower.contains('too many requests')) {
      return 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
    }
    if (lower.contains('operation not allowed')) {
      return 'Operasi tidak diizinkan.';
    }
    if (lower.contains('authentication error')) {
      return 'Data registrasi tidak valid. Periksa kembali data Anda.';
    }

    if (lower.startsWith('gagal registrasi customer') ||
        lower.startsWith('gagal registrasi worker') ||
        lower.startsWith('gagal registrasi')) {
      return 'Gagal registrasi. Periksa kembali data Anda.';
    }

    // Server / parsing
    if (lower.contains('server returned empty response')) {
      return 'Server tidak merespons. Silakan coba lagi.';
    }
    if (lower.contains('server error - received html response') ||
        lower.contains('server error occurred')) {
      return 'Terjadi kesalahan pada server. Silakan coba lagi.';
    }
    if (lower.contains('invalid json response')) {
      return 'Respons server tidak valid. Silakan coba lagi.';
    }
    if (lower.contains('server returned null data')) {
      return 'Data dari server kosong. Silakan coba lagi.';
    }
    if (lower.contains('server returned invalid data format')) {
      return 'Format data dari server tidak sesuai.';
    }
    if (lower.contains('validation error')) {
      return 'Data yang dimasukkan tidak valid.';
    }

    if (lower.contains('this service is no longer available')) {
      return 'Layanan ini sudah tidak tersedia.';
    }

    final requiredFieldMatch = RegExp(
      r'^([a-z0-9_ /\-]+?)\s+is required\.?$',
    ).firstMatch(lower);
    if (requiredFieldMatch != null) {
      final field = requiredFieldMatch.group(1)?.trim();
      if (field != null && field.isNotEmpty) {
        return '${_fieldLabel(field)} wajib diisi.';
      }
    }

    // Common fallback translations
    final translations = <String, String>{
      'failed to load services': 'Gagal memuat layanan.',
      'failed to fetch services': 'Gagal memuat layanan.',
      'failed to fetch profile': 'Gagal memuat profil.',
      'failed to load chats': 'Gagal memuat chat.',
      'failed to load messages': 'Gagal memuat pesan.',
      'failed to send message': 'Gagal mengirim pesan.',
      'failed to create service': 'Gagal membuat layanan.',
      'failed to delete service': 'Gagal menghapus layanan.',
      'failed to update service': 'Gagal memperbarui layanan.',
      'failed to load orders': 'Gagal memuat pesanan.',
      'failed to accept order': 'Gagal menerima pesanan.',
      'failed to complete order': 'Gagal menyelesaikan pesanan.',
      'failed to cancel order': 'Gagal membatalkan pesanan.',
      'failed to update profile': 'Gagal memperbarui profil.',
      'failed to load addresses': 'Gagal memuat alamat.',
      'failed to add address': 'Gagal menambah alamat.',
      'failed to add photo': 'Gagal menambah foto.',
      'failed to mark as read': 'Gagal menandai sebagai dibaca.',
      'failed to load wallet': 'Gagal memuat dompet.',
      'failed to load dashboard summary': 'Gagal memuat ringkasan.',
      'failed to fetch notifications': 'Gagal memuat notifikasi.',
      'failed to process payment': 'Gagal memproses pembayaran.',
      'failed to initiate payment': 'Gagal memulai pembayaran.',
      'failed to fetch booked slots': 'Gagal memuat jadwal.',
      'failed to request withdrawal': 'Gagal mengajukan penarikan.',
      'failed to get availability': 'Gagal memuat ketersediaan.',
      'failed to respond to quote': 'Gagal merespons penawaran.',
      'failed to fetch worker profile': 'Gagal memuat profil worker.',
      'failed to update worker profile': 'Gagal memperbarui profil worker.',
      'failed to load workers': 'Gagal memuat daftar worker.',
      'failed to update avatar': 'Gagal memperbarui foto profil.',
      'failed to fetch avatar': 'Gagal memuat foto profil.',
      'failed to upload documents': 'Gagal mengunggah dokumen.',
      'failed to create or get chat': 'Gagal membuka chat.',
      'validation failed': 'Data yang dimasukkan tidak valid.',
      'invalid resource id format': 'Format ID data tidak valid.',
      'resource not found': 'Data tidak ditemukan.',
      'internal server error':
          'Terjadi kesalahan pada server. Silakan coba lagi.',
      'access forbidden': 'Anda tidak memiliki izin untuk melakukan aksi ini.',
      'user data not found in database': 'Data pengguna tidak ditemukan.',
      'user data not found': 'Data pengguna tidak ditemukan.',
      'user not found': 'Pengguna tidak ditemukan.',
      'worker profile not found': 'Profil worker tidak ditemukan.',
      'worker not found': 'Worker tidak ditemukan.',
      'service not found': 'Layanan tidak ditemukan.',
      'voucher not found': 'Voucher tidak ditemukan.',
      'voucher code already exists': 'Kode voucher sudah digunakan.',
      'voucher already claimed': 'Voucher sudah diklaim.',
      'voucher is not active': 'Voucher tidak aktif.',
      'invalid voucher type': 'Tipe voucher tidak valid.',
      'invalid discount type': 'Tipe diskon tidak valid.',
      'value must be a number': 'Nilai harus berupa angka.',
      'maxdiscount must be a number': 'Maksimum diskon harus berupa angka.',
      'minorder must be a number': 'Minimum order harus berupa angka.',
      'invalid startdate format': 'Format tanggal mulai tidak valid.',
      'invalid enddate format': 'Format tanggal akhir tidak valid.',
      'invalid voucher status': 'Status voucher tidak valid.',
      'missing user': 'Data pengguna tidak ditemukan.',
      'only workers can access this endpoint': 'Fitur ini hanya untuk worker.',
      'only workers can create services': 'Fitur ini hanya untuk worker.',
      'only workers can delete services': 'Fitur ini hanya untuk worker.',
      'only workers can withdraw':
          'Hanya worker yang dapat melakukan penarikan.',
      'wallets are for workers only': 'Fitur dompet hanya untuk worker.',
      'this feature is for workers only': 'Fitur ini hanya untuk worker.',
      'amount and destination are required':
          'Nominal dan tujuan penarikan wajib diisi.',
      'photo url is required': 'URL foto wajib diisi.',
      'category name is required': 'Nama kategori wajib diisi.',
      'voucher code is required': 'Kode voucher wajib diisi.',
      'fcmtoken is required': 'FCM token wajib diisi.',
      'refresh token gagal': 'Sesi Anda berakhir. Silakan login kembali.',
      'auth failed': 'Autentikasi gagal. Periksa kembali data Anda.',
      'tidak dapat terhubung ke server autentikasi':
          'Layanan autentikasi sedang bermasalah. Silakan coba lagi nanti.',
    };

    for (final entry in translations.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    if (_looksLikeRawErrorPayload(message)) {
      return 'Terjadi kesalahan pada server. Silakan coba lagi.';
    }

    return message;
  }

  String? _extractStructuredErrorMessage(String raw) {
    final cleaned = raw.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
    Map<String, dynamic>? decoded = _tryDecodeJsonMap(cleaned);

    if (decoded == null) {
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start != -1 && end > start) {
        final jsonCandidate = cleaned.substring(start, end + 1);
        decoded = _tryDecodeJsonMap(jsonCandidate);
      }
    }

    if (decoded == null) {
      return null;
    }

    final error = decoded['error'];
    if (error is Map) {
      final details = error['details']?.toString().trim();
      if (details != null && details.isNotEmpty) {
        return details;
      }
    }

    final errors = decoded['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
      if (first is Map && first['message'] != null) {
        final firstMessage = first['message'].toString().trim();
        if (firstMessage.isNotEmpty) {
          return firstMessage;
        }
      }
    }

    final message = decoded['message']?.toString().trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }

    return null;
  }

  Map<String, dynamic>? _tryDecodeJsonMap(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      // Ignore decode errors and fallback to generic message handling.
    }

    return null;
  }

  String _normalizeErrorMessage(String raw) {
    var normalized = raw.trim();
    if (normalized.isEmpty) return normalized;

    normalized = normalized.replaceFirst(
      RegExp(r'^Exception:\s*', caseSensitive: false),
      '',
    );
    normalized = normalized.replaceFirst(
      RegExp(r'^Error:\s*', caseSensitive: false),
      '',
    );
    normalized = normalized.replaceFirst(
      RegExp(r'^Auth failed:\s*', caseSensitive: false),
      '',
    );
    normalized = normalized.trim();

    if (normalized.startsWith('"') && normalized.endsWith('"')) {
      normalized = normalized.substring(1, normalized.length - 1).trim();
    }

    final lineBreakIndex = normalized.indexOf('\n');
    if (lineBreakIndex != -1) {
      normalized = normalized.substring(0, lineBreakIndex).trim();
    }

    final escapedStackIndex = normalized.toLowerCase().indexOf(r'\n at ');
    if (escapedStackIndex != -1) {
      normalized = normalized.substring(0, escapedStackIndex).trim();
    }

    return normalized;
  }

  String _fieldLabel(String rawField) {
    final field = rawField.trim().toLowerCase();
    const labels = <String, String>{
      'email': 'Email',
      'password': 'Password',
      'nama': 'Nama',
      'name': 'Nama',
      'fcmtoken': 'FCM token',
      'fcm token': 'FCM token',
      'refresh token': 'Refresh token',
      'refreshtoken': 'Refresh token',
      'photo url': 'URL foto',
      'voucher code': 'Kode voucher',
      'category name': 'Nama kategori',
      'amount': 'Nominal',
      'destination': 'Tujuan',
    };

    return labels[field] ?? _capitalize(rawField.trim());
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    final compact = value.replaceAll('_', ' ').trim();
    if (compact.isEmpty) return value;
    return compact[0].toUpperCase() + compact.substring(1);
  }

  bool _looksLikeRawErrorPayload(String message) {
    final lower = message.toLowerCase();
    return lower.contains('"success":false') ||
        (lower.contains('"statuscode"') && lower.contains('"timestamp"')) ||
        lower.contains('firebaseautherror.fromservererror') ||
        lower.contains('/node_modules/') ||
        lower.contains(' at /workspace/') ||
        lower.contains('process.processticksandrejections');
  }
}

class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}

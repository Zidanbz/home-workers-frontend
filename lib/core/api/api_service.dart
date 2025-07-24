import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:home_workers_fe/core/models/address_model.dart';
import 'package:home_workers_fe/core/models/chat_model.dart';
import 'package:home_workers_fe/core/models/message_model.dart';
import 'package:home_workers_fe/core/models/notification_model.dart';
import 'package:home_workers_fe/core/models/order_model.dart';
import 'package:home_workers_fe/core/models/user_model.dart';
import 'package:home_workers_fe/core/models/wallet_model.dart';
import 'package:home_workers_fe/core/models/worker_model.dart';
import 'package:home_workers_fe/features/notifications/pages/notification_page.dart';
import 'package:http/http.dart' as http;
import '../models/service_model.dart'; // Impor model yang baru kita buat

class ApiService {
  final String _baseUrl = 'https://api-eh5nicgdhq-uc.a.run.app/api';

  // Fungsi login (tidak berubah)
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'fcmToken': fcmToken,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal login: ${response.body}');
    }
  }

  Future<void> resendVerificationEmail({
    required String email,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/resend-verification');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengirim ulang email verifikasi: ${response.body}',
      );
    }
  }

  // =============================
  // UPDATE FCM TOKEN (setelah login)
  // =============================
  Future<void> updateFcmToken({
    required String token, // ini ID token Bearer untuk backend
    required String fcmToken, // ini FCM token device
  }) async {
    final url = Uri.parse('$_baseUrl/auth/user/update-fcm-token');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'fcmToken': fcmToken}),
    );

    if (response.statusCode != 200) {
      Map<String, dynamic> decoded = {};
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
      final message =
          decoded['message'] ??
          'Failed to update FCM token (${response.statusCode})';
      throw Exception(message);
    }
  }

  // --- FUNGSI BARU ---
  // Mengambil daftar layanan milik worker yang sedang login
  Future<List<Service>> getMyServices(String token) async {
    final url = Uri.parse('$_baseUrl/services/my-services');
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
        return data.map((json) => Service.fromJson(json)).toList();
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to load services');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server. $e');
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
      throw Exception(message);
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
      throw Exception(message);
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

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return User.fromJson(responseBody['data']); // ✅ Ambil dari 'data'
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to fetch profile');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
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
        throw Exception(responseBody['message'] ?? 'Failed to load chats');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server. $e');
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

        throw Exception(responseBody['message'] ?? 'Failed to load messages');
      }
    } catch (e) {
      print("response body: ${e}");
      throw Exception('Failed to connect to the server.');
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
        throw Exception(responseBody['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
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
        throw Exception(responseBody['message'] ?? 'Failed to create service');
      }
    } catch (e) {
      print('Error saat memanggil API: $e');
      throw Exception('Failed to connect to the server.');
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
        throw Exception(responseBody['message'] ?? 'Failed to load orders');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
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
        throw Exception(errorBody['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
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
        throw Exception(responseBody['message'] ?? 'Failed to load addresses');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
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
        throw Exception(responseBody['message'] ?? 'Failed to add address');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
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
        throw Exception(responseBody['message'] ?? 'Failed to add photo');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
  }

  Future<Service> getServiceById(String serviceId) async {
    final url = Uri.parse('$_baseUrl/services/$serviceId');
    try {
      final response = await http.get(url);

      final responseBody = jsonDecode(response.body);

      print("response DIJASDOSAASDMLADSDASML: ${response.body}");
      if (response.statusCode == 200 && responseBody['success'] == true) {
        return Service.fromJson(responseBody['data']);
      } else {
        throw Exception(
          responseBody['message'] ?? 'Failed to load service details',
        );
      }
    } catch (e) {
      print("error: $e");
      throw Exception('Failed to connect to the server.');
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
        throw Exception(responseBody['message'] ?? 'Failed to delete service');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
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
        throw Exception(responseBody['message'] ?? 'Failed to update service');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
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
        throw Exception(
          responseBody['message'] ?? 'Failed to load order details',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
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
        throw Exception(responseBody['message'] ?? 'Failed to accept order');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
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
        throw Exception(
          responseBody['message'] ?? 'Failed to create or get chat',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
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
        throw Exception(
          responseBody['message'] ??
              'Server returned status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Network error: $e');
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
        throw Exception(responseBody['message'] ?? 'Failed to mark as read');
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
        throw Exception(responseBody['message'] ?? 'Failed to load wallet');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
  }

  Future<List<Service>> getAllApprovedServices({String? category}) async {
    final url = Uri.parse('$_baseUrl/services');

    try {
      final response = await http.get(url);
      final responseBody = jsonDecode(response.body);

      print("response body: ${response.body}");
      if (response.statusCode == 200 && responseBody['success'] == true) {
        return (responseBody['data'] as List)
            .map((json) => Service.fromJson(json))
            .toList();
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to load services');
      }
    } catch (e) {
      print("error: $e");
      throw Exception('Failed to connect to the server.');
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
        throw Exception(
          responseBody['message'] ?? 'Failed to load dashboard summary',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
  }

  Future<List<Order>> getMyOrdersCustomer(
    String token, {
    bool asWorker = false,
  }) async {
    final url = Uri.parse('$_baseUrl/orders/my-orders');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        // ✅ Akses ke dalam key "data" dulu
        final ordersJson =
            responseBody['data'][asWorker ? 'asWorker' : 'asCustomer'] ?? [];

        print("✅ Jumlah pesanan: ${ordersJson.length}");
        print("ordersJson: ${jsonEncode(ordersJson)}");
        print("responseBody: ${jsonEncode(responseBody)}");
        return ordersJson.map<Order>((json) => Order.fromJson(json)).toList();
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load orders');
      }
    } catch (e) {
      print("error: $e");
      throw Exception('Failed to connect to the server.');
    }
  }

  Future<List<NotificationItem>> getMyNotifications(String token) async {
    final url = Uri.parse('$_baseUrl/users/me/notifications');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((json) => NotificationItem.fromJson(json)).toList();
      } else {
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      throw Exception('Failed to fetch notifications.');
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
  //       throw Exception(responseBody['message'] ?? 'Failed to create order');
  //     }
  //   } catch (e) {
  //     print("error: $e");
  //     throw Exception('Failed to connect to the server.');
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
        throw Exception(errorBody['message'] ?? 'Failed to process payment');
      }
    } catch (e) {
      print("error: $e");
      throw Exception('Failed to connect to the server.');
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
        throw Exception(responseBody['message']);
      }
    } catch (e) {
      throw Exception('Failed to initiate payment.');
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
        throw Exception(responseBody['message'] ?? 'Failed to fetch services');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to connect to the server. $e');
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
      throw Exception('Gagal registrasi customer: ${response.body}');
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
    final request = http.MultipartRequest('POST', url)
      ..fields['email'] = email
      ..fields['password'] = password
      ..fields['nama'] = nama
      ..fields['deskripsi'] = deskripsi
      ..fields['keahlian'] = jsonEncode(keahlian)
      ..fields['linkPortofolio'] = portfolioLink ?? ''
      ..fields['noKtp'] = noKtp ?? ''
      ..fields['fcmToken'] = fcmToken ?? ''
      ..files.add(await http.MultipartFile.fromPath('ktp', ktpFile.path))
      ..files.add(
        await http.MultipartFile.fromPath('fotoDiri', fotoDiriFile.path),
      );

    final response = await request.send();
    if (response.statusCode != 201) {
      throw Exception('Gagal registrasi worker: ${response.statusCode}');
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
        throw Exception(responseBody['message'] ?? 'Gagal mengirim quote');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server. $e');
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
        throw Exception(responseBody['message'] ?? 'Gagal menolak pesanan');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server. $e');
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
      throw Exception('Gagal memuat profil worker');
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
      throw Exception('Gagal mengambil layanan');
    }
  }

  Future<Map<String, dynamic>> createOrderWithPayment({
    required String token,
    required String serviceId,
    required DateTime jadwalPerbaikan,
    required String catatan,
    String? voucherCode,
  }) async {
    final url = Uri.parse('$_baseUrl/payments/initiate');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'serviceId': serviceId,
        'jadwalPerbaikan': jadwalPerbaikan.toIso8601String(),
        'catatan': catatan ?? '',
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body)['data'];
      print('✅ Order & Snap token: $data');
      return data;
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Terjadi kesalahan');
    }
  }

  Future<Map<String, dynamic>> getMidtransStatus({
    required String token,
    required String orderId,
  }) async {
    final url = Uri.parse('$_baseUrl/api/payments/status/$orderId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception('Gagal mengambil status transaksi Midtrans');
    }
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
      throw Exception(
        responseBody['message'] ?? 'Failed to fetch booked slots',
      );
    }
  }

  Future<void> requestWithdraw({
    required String token,
    required int amount,
    required String destinationType,
    required String destinationValue,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/wallet/me/withdraw'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': amount,
        'destination': {'type': destinationType, 'value': destinationValue},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
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
      throw Exception('Gagal menandai notifikasi sebagai dibaca');
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
      throw Exception(
        jsonDecode(response.body)['message'] ??
            'Gagal memperbarui status order',
      );
    }
  }

  Future<void> respondToQuote({
    required String token,
    required String orderId,
    required String decision,
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
      throw Exception('Failed to respond to quote: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> startPaymentForQuote({
    required String token,
    required String orderId,
  }) async {
    final url = Uri.parse('$_baseUrl/payments/start/$orderId');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data']; // { orderId, snapToken }
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Gagal memulai pembayaran: ${response.body}');
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
      throw Exception(data['message'] ?? 'Gagal mengirim ulasan');
    }
  }

  Future<Worker> getWorkerById(String workerId) async {
    final url = Uri.parse('$_baseUrl/workers/$workerId');
    final response = await http.get(url);

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return Worker.fromJson(body['data']);
    } else {
      throw Exception(body['message'] ?? 'Gagal ambil data worker');
    }
  }

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
        throw Exception(responseBody['message'] ?? 'Gagal update avatar');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
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
      throw Exception(
        'Format respons tidak valid dari server (kode: ${resp.statusCode}).',
      );
    }

    // Struktur backend versi helper menggunakan sendSuccess/sendError:
    // success: bool, message: string, data: {...}
    final success = body['success'] == true;

    if (!success) {
      // Ambil pesan error spesifik
      final msg = body['message'] ?? 'Validasi voucher gagal.';
      throw Exception(msg);
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
      throw Exception(
        'Format respons tidak valid dari server (kode: ${resp.statusCode}).',
      );
    }

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Gagal klaim voucher.');
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
      throw Exception(
        'Gagal parsing respons server (status: ${resp.statusCode}).',
      );
    }

    final success = decoded['success'] == true;
    if (!success) {
      throw Exception(decoded['message'] ?? 'Gagal mengambil voucher.');
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
}

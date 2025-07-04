import 'dart:convert';
import 'package:home_workers_fe/core/models/address_model.dart';
import 'package:home_workers_fe/core/models/chat_model.dart';
import 'package:home_workers_fe/core/models/message_model.dart';
import 'package:home_workers_fe/core/models/order_model.dart';
import 'package:home_workers_fe/core/models/user_model.dart';
import 'package:home_workers_fe/core/models/wallet_model.dart';
import 'package:home_workers_fe/core/services/secure_storage_service.dart';
import 'package:home_workers_fe/features/chat/pages/chat_detail_page.dart';
import 'package:http/http.dart' as http;
import '../models/service_model.dart'; // Impor model yang baru kita buat

class ApiService {
  final String _baseUrl = 'https://api-eh5nicgdhq-uc.a.run.app/api';
  final SecureStorageService _storageService = SecureStorageService();
  // Fungsi login (tidak berubah)
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Could not connect to the server. Please try again.');
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
          'Authorization': 'Bearer $token', // Gunakan token dari parameter
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseBody = jsonDecode(response.body);
        return responseBody.map((json) => Service.fromJson(json)).toList();
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load services');
      }
    } catch (e) {
      //
      // Error ini yang Anda lihat jika ada masalah koneksi/URL
      throw Exception('Failed to connect to the server. $e');
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

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to fetch profile');
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

      if (response.statusCode == 200) {
        final List<dynamic> responseBody = jsonDecode(response.body);
        // Kirim currentUserId ke fromJson untuk memproses data
        return responseBody
            .map((json) => Chat.fromJson(json, currentUserId))
            .toList();
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load chats');
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

      if (response.statusCode == 200) {
        final List<dynamic> responseBody = jsonDecode(response.body);
        return responseBody.map((json) => Message.fromJson(json)).toList();
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load messages');
      }
    } catch (e) {
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

      if (response.statusCode != 201) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to send message');
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
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(serviceData),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to create service');
      }
    } catch (e) {
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        // Kita hanya tertarik pada pesanan sebagai worker untuk halaman ini
        final List<dynamic> workerOrdersJson = responseBody['asWorker'] ?? [];
        return workerOrdersJson.map((json) => Order.fromJson(json)).toList();
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load orders');
      }
    } catch (e) {
      print('>>> Terjadi Error di getMyOrders: $e');
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

      if (response.statusCode == 200) {
        final List<dynamic> responseBody = jsonDecode(response.body);
        return responseBody.map((json) => Address.fromJson(json)).toList();
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load addresses');
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
      if (response.statusCode != 201) {
        throw Exception(
          jsonDecode(response.body)['message'] ?? 'Failed to add address',
        );
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

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to add photo');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
  }

  Future<Service> getServiceById(String serviceId) async {
    final url = Uri.parse('$_baseUrl/services/$serviceId');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return Service.fromJson(jsonDecode(response.body));
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          errorBody['message'] ?? 'Failed to load service details',
        );
      }
    } catch (e) {
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

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to delete service');
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
      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to update service');
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

      if (response.statusCode == 200) {
        // Backend sudah memperkaya data, jadi kita bisa langsung parse
        return Order.fromJson(jsonDecode(response.body));
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load order details');
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

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to accept order');
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

      if (response.statusCode == 201 || response.statusCode == 200) {
        return responseBody['chatId'];
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

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load summary');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
  }

  Future<void> markChatAsRead(String token, String chatId) async {
    final url = Uri.parse('$_baseUrl/chats/$chatId/read');
    try {
      // Kita tidak perlu menunggu respons, cukup kirim saja
      http.post(url, headers: {'Authorization': 'Bearer $token'});
    } catch (e) {
      // Abaikan error koneksi untuk fungsi ini agar tidak mengganggu UI
      print("Gagal menandai chat sebagai dibaca (opsional): $e");
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

      if (response.statusCode == 200) {
        return Wallet.fromJson(jsonDecode(response.body));
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load wallet');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
  }

  
}

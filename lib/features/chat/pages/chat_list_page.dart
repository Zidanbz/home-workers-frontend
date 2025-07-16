import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/state/auth_provider.dart';
import 'chat_detail_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Chat>> _chatsFuture;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  // Color Palette
  static const Color primaryColor = Color(0xFF1A374D);
  static const Color lightGray = Color(0xFFD9D9D9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.user?.uid;

    if (token != null && userId != null) {
      setState(() {
        _chatsFuture = _apiService.getMyChats(token, userId);
      });
    } else {
      setState(() {
        _chatsFuture = Future.error('Anda tidak terautentikasi.');
      });
    }
  }

  List<Chat> _filterChats(List<Chat> chats) {
    if (_searchQuery.isEmpty) return chats;
    return chats
        .where(
          (chat) =>
              chat.otherUserName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              chat.lastMessage.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: primaryColor),
                decoration: const InputDecoration(
                  hintText: 'Cari percakapan...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text(
                'Percakapan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
        backgroundColor: white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: primaryColor,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: backgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                });
              },
              icon: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                color: primaryColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChats,
        color: primaryColor,
        backgroundColor: white,
        child: FutureBuilder<List<Chat>>(
          future: _chatsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                  strokeWidth: 3,
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Terjadi kesalahan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final allChats = snapshot.data ?? [];
            final filteredChats = _filterChats(allChats);

            if (allChats.isEmpty) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: lightGray.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: primaryColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Belum Ada Percakapan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Mulai percakapan dengan pekerja atau pelanggan',
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor.withOpacity(0.7),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (filteredChats.isEmpty && _searchQuery.isNotEmpty) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: lightGray.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: primaryColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Tidak Ditemukan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada percakapan yang cocok dengan pencarian "$_searchQuery"',
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor.withOpacity(0.7),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final unreadCount = filteredChats
                .where((chat) => chat.unreadCount > 0)
                .length;

            return Column(
              children: [
                // Header dengan statistik
                if (filteredChats.isNotEmpty && _searchQuery.isEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.chat_rounded,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${filteredChats.length} Percakapan',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                              if (unreadCount > 0)
                                Text(
                                  '$unreadCount pesan belum dibaca',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: primaryColor.withOpacity(0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // List percakapan
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      return _buildChatListItem(filteredChats[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatListItem(Chat chat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        border: chat.unreadCount > 0
            ? Border.all(color: primaryColor.withOpacity(0.2), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(chat.unreadCount > 0 ? 0.1 : 0.05),
            blurRadius: chat.unreadCount > 0 ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatDetailPage(
                  chatId: chat.id,
                  name: chat.otherUserName,
                  avatarUrl: chat.otherUserAvatarUrl,
                ),
              ),
            );
            _loadChats();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar dengan border
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: chat.otherUserAvatarUrl.isNotEmpty
                        ? NetworkImage(chat.otherUserAvatarUrl)
                        : const AssetImage('assets/default_profile.png')
                              as ImageProvider,
                    backgroundColor: lightGray.withOpacity(0.3),
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.otherUserName,
                              style: TextStyle(
                                fontWeight: chat.unreadCount > 0
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 16,
                                color: primaryColor,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (chat.unreadCount > 0)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        chat.lastMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Time dan status
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: primaryColor.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            chat.formattedTimestamp,
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (chat.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${chat.unreadCount} pesan baru',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/chat_model.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../chat/pages/chat_detail_page.dart';

class CustomerChatListPage extends StatefulWidget {
  final bool showBackButton;

  const CustomerChatListPage({super.key, this.showBackButton = true});

  @override
  State<CustomerChatListPage> createState() => _CustomerChatListPageState();
}

class _CustomerChatListPageState extends State<CustomerChatListPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Chat>> _chatsFuture;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

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
    _searchFocusNode.dispose();
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
    }
  }

  List<Chat> _filterChats(List<Chat> chats) {
    if (_searchQuery.isEmpty) return chats;
    final query = _searchQuery.toLowerCase();
    return chats
        .where(
          (chat) =>
              chat.otherUserName.toLowerCase().contains(query) ||
              chat.lastMessage.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        title: const Text(
          'Chat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        backgroundColor: white,
        elevation: 0,
        leading: widget.showBackButton && Navigator.of(context).canPop()
            ? Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: primaryColor,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              )
            : null,
        actions: [
          IconButton(
            onPressed: () => _searchFocusNode.requestFocus(),
            icon: const Icon(Icons.search, color: primaryColor),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              icon: const Icon(Icons.close, color: primaryColor),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadChats,
              color: primaryColor,
              backgroundColor: white,
              child: FutureBuilder<List<Chat>>(
                future: _chatsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        ApiService.readableError(
                          snapshot.error,
                          action: 'Gagal memuat daftar chat',
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final chats = _filterChats(snapshot.data!);
                  if (chats.isEmpty) {
                    return _buildEmptyState(
                      message: 'Tidak ada percakapan yang cocok.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      return _buildChatListItem(chats[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: lightGray.withOpacity(0.4)),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Cari percakapan...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: const Icon(Icons.search, color: primaryColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({String message = 'Belum ada percakapan.'}) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(Icons.chat_bubble_outline,
                    size: 40, color: primaryColor.withOpacity(0.6)),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: primaryColor.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatListItem(Chat chat) {
    final isReadOnly = chat.chatAllowed == false;
    final String? readOnlyReason = chat.chatBlockedReason;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        border: chat.unreadCount > 0
            ? Border.all(color: primaryColor.withOpacity(0.2), width: 1)
            : Border.all(color: lightGray.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(chat.unreadCount > 0 ? 0.08 : 0.04),
            blurRadius: chat.unreadCount > 0 ? 16 : 10,
            offset: const Offset(0, 6),
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
                  readOnly: isReadOnly,
                  readOnlyMessage: readOnlyReason,
                ),
              ),
            );
            _loadChats();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: chat.unreadCount > 0
                          ? primaryColor.withOpacity(0.4)
                          : lightGray.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundImage: chat.otherUserAvatarUrl.isNotEmpty
                        ? NetworkImage(chat.otherUserAvatarUrl)
                        : const AssetImage('assets/default_profile.png')
                              as ImageProvider,
                    backgroundColor: lightGray.withOpacity(0.3),
                  ),
                ),
                const SizedBox(width: 14),
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
                                fontSize: 15,
                                color: primaryColor,
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
                      const SizedBox(height: 6),
                      Text(
                        chat.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryColor.withOpacity(0.75),
                        ),
                      ),
                      if (isReadOnly) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                readOnlyReason ?? 'Chat nonaktif (read-only)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: backgroundGray,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        chat.formattedTimestamp,
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (chat.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          chat.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

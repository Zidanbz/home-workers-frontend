import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/chat_model.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../chat/pages/chat_detail_page.dart';

class CustomerChatListPage extends StatefulWidget {
  const CustomerChatListPage({super.key});

  @override
  State<CustomerChatListPage> createState() => _CustomerChatListPageState();
}

class _CustomerChatListPageState extends State<CustomerChatListPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Chat>> _chatsFuture;

  @override
  void initState() {
    super.initState();
    _loadChats();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChats,
        child: FutureBuilder<List<Chat>>(
          future: _chatsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Tidak ada percakapan.'));
            }

            final chats = snapshot.data!;
            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                return _buildChatListItem(chats[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatListItem(Chat chat) {
    return ListTile(
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
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(chat.otherUserAvatarUrl),
      ),
      title: Text(
        chat.otherUserName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            chat.formattedTimestamp,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 4),
          if (chat.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const SizedBox(height: 24),
        ],
      ),
    );
  }
}

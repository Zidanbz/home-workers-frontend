import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/message_model.dart';
import '../../../core/state/auth_provider.dart';

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final String name;
  final String avatarUrl;

  const ChatDetailPage({
    super.key,
    required this.chatId,
    required this.name,
    required this.avatarUrl,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _messageController = TextEditingController();
  final ApiService _apiService = ApiService();
  late Future<List<Message>> _messagesFuture;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markAsRead();
  }

  void _markAsRead() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      _apiService.markChatAsRead(authProvider.token!, widget.chatId);
    }
  }

  void _showComingSoonDialog({String? featureLabel}) {
    final label = featureLabel ?? 'Fitur ini';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Coming Soon'),
        content: Text(
          '$label akan segera tersedia. Nantikan update berikutnya!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _loadMessages() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      setState(() {
        _messagesFuture = _apiService.getMessages(
          authProvider.token!,
          widget.chatId,
        );
      });
    }
    if (authProvider.token != null) {
      print("Chat ID: ${widget.chatId}");

      return;
    }
  }

  Future<void> _handleSendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final messageText = _messageController.text.trim();

    if (token != null) {
      _messageController.clear();

      try {
        await _apiService.sendMessage(token, widget.chatId, messageText);
        _loadMessages();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim pesan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).user?.uid;

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Message>>(
              future: _messagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Mulai percakapan Anda!'));
                }

                final messages = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isSentByMe = message.senderId == currentUserId;
                    return _buildMessageBubble(message, isSentByMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 1,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: (widget.avatarUrl.isNotEmpty)
                ? NetworkImage(widget.avatarUrl)
                : const AssetImage('assets/sp1.png') as ImageProvider,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.name.contains("David") ? "(+44) 50 9285 3022" : "Online",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showComingSoonDialog(featureLabel: 'Video call'),
          icon: const Icon(Icons.videocam_outlined, color: Colors.black),
          tooltip: 'Video call (Coming Soon)',
        ),
        IconButton(
          onPressed: () => _showComingSoonDialog(featureLabel: 'Telepon'),
          icon: const Icon(Icons.call_outlined, color: Colors.black),
          tooltip: 'Telepon (Coming Soon)',
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message, bool isSentByMe) {
    final color = isSentByMe ? const Color(0xFF1E232C) : Colors.white;
    final textColor = isSentByMe ? Colors.white : Colors.black;
    final bubbleAlignment = isSentByMe
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: bubbleAlignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if (!isSentByMe)
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                  ),
              ],
            ),
            child: Text(message.text, style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () => _showComingSoonDialog(featureLabel: 'Lampiran'),
              icon: const Icon(Icons.add, color: Colors.grey),
              tooltip: 'Tambah Lampiran (Coming Soon)',
            ),

            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message ...',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _handleSendMessage,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

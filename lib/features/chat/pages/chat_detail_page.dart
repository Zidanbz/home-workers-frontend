import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/message_model.dart';
import '../../../core/state/auth_provider.dart';

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final String name;
  final String avatarUrl;
  final bool readOnly;
  final String? readOnlyMessage;

  const ChatDetailPage({
    super.key,
    required this.chatId,
    required this.name,
    required this.avatarUrl,
    this.readOnly = false,
    this.readOnlyMessage,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  static const Color primaryColor = Color(0xFF1A374D);
  static const Color backgroundGray = Color(0xFFF8F9FA);
  static const Color sentBubbleColor = Color(0xFF1A374D);
  static const Color receivedBubbleColor = Colors.white;
  static const Color mutedTextColor = Color(0xFF8E9AAF);

  final _messageController = TextEditingController();
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isInitialLoading = true;
  bool _isSending = false;

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

  Future<void> _loadMessages() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      try {
        final result = await _apiService.getMessages(
          authProvider.token!,
          widget.chatId,
        );
        if (!mounted) return;
        setState(() {
          _messages = result;
          _isInitialLoading = false;
        });
        _scrollToBottom();
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isInitialLoading = false;
        });
      }
    } else {
      if (!mounted) return;
      setState(() {
        _isInitialLoading = false;
      });
    }
    if (authProvider.token != null) {
      print("Chat ID: ${widget.chatId}");

      return;
    }
  }

  Future<void> _handleSendMessage() async {
    if (widget.readOnly) return;
    if (_messageController.text.trim().isEmpty) return;
    if (_isSending) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final messageText = _messageController.text.trim();
    final senderId = authProvider.user?.uid;

    if (token != null) {
      _messageController.clear();
      setState(() {
        _isSending = true;
      });

      final optimisticMessage = Message(
        id: 'local_${DateTime.now().microsecondsSinceEpoch}',
        text: messageText,
        senderId: senderId ?? 'unknown',
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages = [..._messages, optimisticMessage];
      });
      _scrollToBottom();

      try {
        await _apiService.sendMessage(token, widget.chatId, messageText);
        _refreshMessagesSilently();
      } catch (e) {
        if (mounted) {
          setState(() {
            _messages = _messages
                .where((message) => message.id != optimisticMessage.id)
                .toList();
          });
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiService.readableError(e, action: 'Gagal mengirim pesan'),
            ),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _refreshMessagesSilently() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) return;
    try {
      final result = await _apiService.getMessages(
        authProvider.token!,
        widget.chatId,
      );
      if (!mounted) return;
      setState(() {
        _messages = result;
      });
      _scrollToBottom();
    } catch (_) {
      // Silent refresh failure should not interrupt UI.
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).user?.uid;

    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (widget.readOnly)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Colors.orange.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.readOnlyMessage ??
                          'Chat hanya tersedia sampai 7 hari setelah pesanan selesai.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(child: Text('Mulai percakapan Anda!'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final bool isSentByMe = message.senderId == currentUserId;
                      return _buildMessageBubble(message, isSentByMe);
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
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withOpacity(0.15),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: widget.avatarUrl.isNotEmpty
                  ? NetworkImage(widget.avatarUrl)
                  : null,
              backgroundColor: Colors.grey.shade200,
              child: widget.avatarUrl.isEmpty
                  ? const Icon(Icons.person, color: primaryColor, size: 18)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.readOnly ? 'Read-only' : 'Online',
                style: TextStyle(
                  color: widget.readOnly
                      ? Colors.orange.shade700
                      : mutedTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showComingSoonDialog(featureLabel: 'Video call'),
          icon: const Icon(Icons.videocam_outlined, color: primaryColor),
          tooltip: 'Video call (Coming Soon)',
        ),
        IconButton(
          onPressed: () => _showComingSoonDialog(featureLabel: 'Telepon'),
          icon: const Icon(Icons.call_outlined, color: primaryColor),
          tooltip: 'Telepon (Coming Soon)',
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message, bool isSentByMe) {
    final color = isSentByMe ? sentBubbleColor : receivedBubbleColor;
    final textColor = isSentByMe ? Colors.white : const Color(0xFF1F2937);
    final bubbleAlignment = isSentByMe
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;
    final timeText = DateFormat('HH:mm').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: bubbleAlignment,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe) ...[
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withOpacity(0.12),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 14,
                backgroundImage: widget.avatarUrl.isNotEmpty
                    ? NetworkImage(widget.avatarUrl)
                    : null,
                backgroundColor: Colors.grey.shade200,
                child: widget.avatarUrl.isEmpty
                    ? const Icon(Icons.person, color: primaryColor, size: 14)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isSentByMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.68,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: isSentByMe
                        ? const Radius.circular(18)
                        : const Radius.circular(4),
                    bottomRight: isSentByMe
                        ? const Radius.circular(4)
                        : const Radius.circular(18),
                  ),
                  boxShadow: [
                    if (!isSentByMe)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: TextStyle(color: textColor, height: 1.35),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 11,
                      color: mutedTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isSentByMe) ...[
                    const SizedBox(width: 6),
                    if (message.id.startsWith('local_'))
                      Icon(Icons.access_time, size: 13, color: mutedTextColor)
                    else
                      Icon(
                        message.readAt != null ? Icons.done_all : Icons.check,
                        size: 14,
                        color: message.readAt != null
                            ? primaryColor
                            : mutedTextColor,
                      ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    if (widget.readOnly) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: SafeArea(
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.readOnlyMessage ??
                      'Chat hanya tersedia sampai 7 hari setelah pesanan selesai.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () => _showComingSoonDialog(featureLabel: 'Lampiran'),
              icon: const Icon(Icons.add, color: mutedTextColor),
              tooltip: 'Tambah Lampiran (Coming Soon)',
            ),

            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
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
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

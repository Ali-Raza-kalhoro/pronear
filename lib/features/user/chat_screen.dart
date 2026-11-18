// lib/features/user/chat_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/global_error_handler.dart';
import '../provider/auth_provider.dart';
import '../provider/chat_provider.dart';

class UserChatScreen extends StatefulWidget {
  final String roomId;
  final String? providerName;
  final String? providerId;

  const UserChatScreen({
    super.key,
    required this.roomId,
    this.providerName,
    this.providerId,
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatProvider _chatProvider;
  int _messageCount = 0;

  bool _isLoading = true;
  String? _providerProfileImage;
  bool _isProviderOnline = false;

  late AnimationController _pulseController;
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    _chatProvider.addListener(_onChatUpdate);
    _initializeChat();
    _loadProviderInfo();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _chatProvider.removeListener(_onChatUpdate);
    _messageController.dispose();
    _scrollController.dispose();
    _chatProvider.disposeMessages();
    _pulseController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _onChatUpdate() {
    if (_chatProvider.messages.length > _messageCount) {
      _messageCount = _chatProvider.messages.length;
      _scrollToBottom();

      final authProvider = context.read<AuthProvider>();
      if (authProvider.userId != null) {
        _chatProvider.markAsRead(widget.roomId, authProvider.userId!);
      }
    }
  }

  Future<void> _initializeChat() async {
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      await _chatProvider.loadMessages(widget.roomId);
      _messageCount = _chatProvider.messages.length;
      _chatProvider.subscribeToMessages(widget.roomId);
      await _chatProvider.markAsRead(widget.roomId, authProvider.userId!);
      setState(() => _isLoading = false);
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error initializing chat: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProviderInfo() async {
    if (widget.providerId == null) return;
    try {
      final provider = await SupabaseService().getProvider(widget.providerId!);
      if (provider != null && mounted) {
        final user = provider['users'] ?? {};
        setState(() {
          _providerProfileImage = user['profile_image'];
          _isProviderOnline = user['is_online'] ?? false;
        });
      }
    } catch (e) {}
  }

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.userId == null) {
      GlobalErrorHandler.showCustomError('Please login to send messages');
      return;
    }

    try {
      final senderId = authProvider.userId!;
      _messageController.clear();
      await _chatProvider.sendMessage(
        roomId: widget.roomId,
        senderId: senderId,
        content: text,
      );
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showCustomError('Failed to send message.');
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (image == null || !mounted) return;

      final authProvider = context.read<AuthProvider>();
      if (authProvider.userId == null) {
        GlobalErrorHandler.showCustomError('Please login.');
        return;
      }

      final bytes = await image.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${authProvider.userId}/chat_$timestamp.jpg';

      await Supabase.instance.client.storage
          .from('chat_images')
          .uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      final url = Supabase.instance.client.storage
          .from('chat_images')
          .getPublicUrl(filePath);

      await _chatProvider.sendMessage(
        roomId: widget.roomId,
        senderId: authProvider.userId!,
        content: url,
        type: 'image',
      );
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showCustomError('Failed to upload image.');
      }
    }
  }

  Future<void> _showMessageOptions(Map<String, dynamic> message) async {
    final authProvider = context.read<AuthProvider>();
    final isMine = message['sender_id'] == authProvider.userId;
    final messageId = message['id'] as String;
    final isDeleted = message['is_deleted'] == true;

    if (isDeleted) {
      GlobalErrorHandler.showCustomError('This message was deleted');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1d3b27),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.orange),
                title: const Text('Delete for me', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _chatProvider.deleteForMe(messageId);
                  GlobalErrorHandler.showCustomSuccess('Message hidden from your chat.');
                },
              ),
              if (isMine)
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  title: const Text('Delete for everyone', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await _chatProvider.deleteForEveryone(messageId);
                      GlobalErrorHandler.showCustomSuccess('Message deleted for everyone.');
                    } catch (e) {
                      GlobalErrorHandler.showCustomError('Failed to delete message.');
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF38804f),
                    Color(0xFF1d3b27),
                    Color(0xFF1d3b27),
                    Color(0xFF38804f),
                  ],
                  stops: [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
            Positioned(
              top: -120,
              right: -100,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final opacity = 0.15 +
                      (0.08 *
                          (1 +
                              math.sin(_pulseController.value * math.pi * 2)) /
                          2);
                  return Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6C63FF).withOpacity(opacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: -150,
              left: -120,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4D96FF).withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final value = math.sin(_floatingController.value * math.pi * 2);
                return Positioned(
                  top: 140 + value * 15,
                  right: 30,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.watch<AuthProvider>();
    final messages = chatProvider.messages;

    if (authProvider.userId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0A2A),
        body: Stack(
          children: [
            _buildBackground(size),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 64, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('Please login to chat',
                      style: TextStyle(
                          fontSize: 18, color: Colors.white.withOpacity(0.7))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF49e8c3),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A2A),
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF49e8c3)),
                  )
                      : chatProvider.error != null
                      ? Center(
                      child: Text(chatProvider.error!,
                          style: const TextStyle(color: Colors.white)))
                      : messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMine =
                          message['sender_id'] == authProvider.userId;
                      final sender = message['users'] ?? {};
                      return GestureDetector(
                        onLongPress: () => _showMessageOptions(message),
                        child: _buildMessage(message, isMine, sender),
                      );
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: Colors.white.withOpacity(0.8), size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: _isProviderOnline ? const Color(0xFF49e8c3) : Colors.grey,
                  width: 2),
            ),
            child: ClipOval(
              child: _providerProfileImage != null
                  ? CachedNetworkImage(
                imageUrl: _providerProfileImage!,
                fit: BoxFit.cover,
                width: 40,
                height: 40,
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFF49e8c3),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
              )
                  : Container(
                color: const Color(0xFF49e8c3),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.providerName ?? 'Provider',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isProviderOnline
                            ? const Color(0xFF49e8c3)
                            : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isProviderOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                          fontSize: 11,
                          color: _isProviderOnline
                              ? const Color(0xFF49e8c3)
                              : Colors.white.withOpacity(0.3)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 80, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 20),
          Text('No messages yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 8),
          Text('Start chatting with the provider',
              style: TextStyle(
                  fontSize: 14, color: Colors.white.withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final isSending = context.watch<ChatProvider>().isSending;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file_rounded,
                color: Color(0xFF49e8c3), size: 24),
            onPressed: isSending ? null : _pickImage,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle:
                TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF49e8c3), Color(0xFF31b999)]),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: isSending
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.send_rounded,
                  color: Colors.black, size: 20),
              onPressed: isSending ? null : _sendMessage,
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(
      Map<String, dynamic> message,
      bool isMine,
      Map<String, dynamic> sender,
      ) {
    final isImage = message['message_type'] == 'image';
    final isDeleted = message['is_deleted'] == true;
    final isRead = message['is_read'] ?? false;
    final time = message['created_at'] != null
        ? DateFormat('hh:mm a').format(DateTime.parse(message['created_at']))
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
        isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF49e8c3).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: sender['profile_image'] != null &&
                    sender['profile_image'].isNotEmpty
                    ? CachedNetworkImageProvider(sender['profile_image'])
                    : null,
                child: sender['profile_image'] == null ||
                    sender['profile_image'].isEmpty
                    ? Icon(Icons.person,
                    size: 16, color: Colors.white.withOpacity(0.5))
                    : null,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMine
                    ? const LinearGradient(
                    colors: [Color(0xFF49e8c3), Color(0xFF31b999)])
                    : LinearGradient(colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMine
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isMine
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                border: Border.all(
                  color: isMine
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMine && sender['full_name'] != null)
                    Text(
                      sender['full_name'],
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF49e8c3)),
                    ),
                  if (!isMine && sender['full_name'] != null)
                    const SizedBox(height: 4),
                  if (isDeleted)
                    Text(
                      'This message was deleted',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isMine
                            ? Colors.black.withOpacity(0.5)
                            : Colors.white.withOpacity(0.4),
                      ),
                    )
                  else if (isImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: message['content'] ?? '',
                        height: 150,
                        width: 200,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 150,
                          width: 200,
                          color: Colors.white.withOpacity(0.05),
                          child: const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF49e8c3))),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 150,
                          width: 200,
                          color: Colors.white.withOpacity(0.05),
                          child: Icon(Icons.broken_image,
                              color: Colors.white.withOpacity(0.2), size: 40),
                        ),
                      ),
                    )
                  else
                    Text(
                      message['content'] ?? '',
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isMine
                              ? Colors.black
                              : Colors.white.withOpacity(0.9)),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                            fontSize: 10,
                            color: isMine
                                ? Colors.black.withOpacity(0.5)
                                : Colors.white.withOpacity(0.3)),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: isRead
                              ? Colors.black.withOpacity(0.7)
                              : Colors.black.withOpacity(0.4),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
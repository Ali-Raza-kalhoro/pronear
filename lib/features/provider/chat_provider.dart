// lib/features/provider/chat_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';

class ChatProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  StreamSubscription<List<Map<String, dynamic>>>? _messageSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _roomsSubscription;

  // Cache for user profiles to attach to real-time messages
  final Map<String, Map<String, dynamic>> _userCache = {};

  // ✅ Track locally deleted message IDs (delete for me)
  final Set<String> _locallyDeletedIds = {};

  // Getters
  List<Map<String, dynamic>> get rooms => _rooms;
  List<Map<String, dynamic>> get messages => _messages
      .where((m) => !_locallyDeletedIds.contains(m['id']))
      .toList();
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  // ============================================================
  // ROOMS
  // ============================================================
  Future<void> loadRooms(String userId, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rooms = await _service.getChatRooms(userId, role);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void subscribeToRooms(String userId, String role) {
    _roomsSubscription?.cancel();
    _roomsSubscription = _service.listenToChatRooms(userId, role).listen(
          (updatedRooms) async {
        try {
          _rooms = await _service.getChatRooms(userId, role);
          notifyListeners();
        } catch (e) {
          debugPrint('Error refreshing rooms: $e');
        }
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  Future<String> getOrCreateRoom(String userId, String providerId, {String? requestId}) async {
    try {
      return await _service.getOrCreateChatRoom(userId, providerId, requestId: requestId);
    } catch (e) {
      throw Exception('Failed to get or create chat room: $e');
    }
  }

  // ============================================================
  // MESSAGES
  // ============================================================
  Future<void> loadMessages(String roomId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetchedMessages = await _service.getMessages(roomId);
      _messages = fetchedMessages;

      for (var msg in fetchedMessages) {
        if (msg['users'] != null) {
          final String uid = msg['sender_id'];
          _userCache[uid] = Map<String, dynamic>.from(msg['users']);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void subscribeToMessages(String roomId) {
    _messageSubscription?.cancel();
    _messageSubscription = _service.listenToMessages(roomId).listen(
          (newRawMessages) {
        _messages = newRawMessages.map((msg) {
          final String senderId = msg['sender_id'];
          final updatedMsg = Map<String, dynamic>.from(msg);
          if (updatedMsg['users'] == null && _userCache.containsKey(senderId)) {
            updatedMsg['users'] = _userCache[senderId];
          }
          return updatedMsg;
        }).toList();

        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
    String? type,
    String? mediaUrl,
  }) async {
    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      await _service.sendMessage(roomId, senderId, content, type: type, mediaUrl: mediaUrl);
      _isSending = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isSending = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markAsRead(String roomId, String userId) async {
    try {
      await _service.markMessagesAsRead(roomId, userId);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // ============================================================
  // ✅ DELETE MESSAGE HELPERS
  // ============================================================
  void deleteForMe(String messageId) {
    _locallyDeletedIds.add(messageId);
    notifyListeners();
  }

  Future<void> deleteForEveryone(String messageId) async {
    try {
      await _service.deleteMessageForEveryone(messageId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete message for everyone: $e');
    }
  }

  // ============================================================
  // DISPOSE / CLEANUP
  // ============================================================
  void disposeMessages() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _messages = [];
    _locallyDeletedIds.clear();
    notifyListeners();
  }

  void disposeRooms() {
    _roomsSubscription?.cancel();
    _roomsSubscription = null;
    _rooms = [];
    notifyListeners();
  }

  void disposeAll() {
    _messageSubscription?.cancel();
    _roomsSubscription?.cancel();
    _messageSubscription = null;
    _roomsSubscription = null;
    _rooms = [];
    _messages = [];
    _locallyDeletedIds.clear();
    _isLoading = false;
    _isSending = false;
    _error = null;
    _userCache.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _roomsSubscription?.cancel();
    super.dispose();
  }
}
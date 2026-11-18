// lib/features/user/my_requests_screen.dart
//
// Customer "Request History": live list of the customer's service requests /
// orders with actions per status:
//   pending   → Cancel
//   accepted  → Open chat
//   completed → Rate provider
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/global_error_handler.dart';
import '../../core/services/supabase_service.dart';
import '../provider/auth_provider.dart';

const _bgDark = Color(0xFF1d3b27);
const _bgLight = Color(0xFF38804f);
const _accent = Color(0xFF49e8c3);

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String _filter = 'all';
  final Set<String> _reviewedProviderIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribe());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _subscribe() {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    _loadMyReviews(userId);
    _sub = SupabaseService().listenToUserRequests(userId).listen(
      (rows) {
        if (!mounted) return;
        setState(() {
          _requests = rows;
          _loading = false;
        });
      },
      onError: (e) {
        debugPrint('⚠️ My requests stream error: $e');
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  Future<void> _loadMyReviews(String userId) async {
    try {
      final rows = await Supabase.instance.client
          .from('reviews')
          .select('provider_id')
          .eq('user_id', userId);
      if (!mounted) return;
      setState(() {
        _reviewedProviderIds
          ..clear()
          ..addAll(rows.map((r) => r['provider_id'].toString()));
      });
    } catch (e) {
      debugPrint('⚠️ Could not load reviews: $e');
    }
  }

  List<Map<String, dynamic>> get _filtered => _filter == 'all'
      ? _requests
      : _requests.where((r) => r['status'] == _filter).toList();

  // ============================================================
  // ACTIONS
  // ============================================================
  Future<void> _cancel(Map<String, dynamic> request) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel request?'),
        content: const Text('The provider will be notified.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    await GlobalErrorHandler.run<void>(
      context: context,
      action: () async {
        final client = Supabase.instance.client;
        await client.from('service_requests').update({
          'status': 'cancelled',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', request['id']).eq('status', 'pending');

        // Notify the provider (their notifications are keyed by users.id)
        final provider = await client
            .from('providers')
            .select('user_id')
            .eq('id', request['provider_id'])
            .maybeSingle();
        if (provider != null) {
          await client.from('notifications').insert({
            'user_id': provider['user_id'],
            'title': 'Request cancelled',
            'body': 'A customer cancelled their request.',
            'type': 'request_status',
            'data': {'request_id': request['id']},
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      },
    );
  }

  Future<void> _openChat(Map<String, dynamic> request) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    final roomId = await GlobalErrorHandler.run<String>(
      context: context,
      action: () => SupabaseService().getOrCreateChatRoom(
        userId,
        request['provider_id'],
        requestId: request['id'],
      ),
    );
    if (roomId == null || !mounted) return;
    context.push('/user/chat/$roomId', extra: {
      'providerName': _providerName(request),
      'providerId': request['provider_id'],
    });
  }

  Future<void> _rate(Map<String, dynamic> request) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    double rating = 5;
    final commentController = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rate ${_providerName(request)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingBar.builder(
              initialRating: rating,
              minRating: 1,
              itemCount: 5,
              itemSize: 36,
              itemBuilder: (_, _) =>
                  const Icon(Icons.star_rounded, color: Colors.amber),
              onRatingUpdate: (v) => rating = v,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: 'Write a short review (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Later')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit')),
        ],
      ),
    );
    final comment = commentController.text.trim();
    commentController.dispose();
    if (submit != true || !mounted) return;

    final saved = await GlobalErrorHandler.run<bool>(
      context: context,
      action: () async {
        await Supabase.instance.client.from('reviews').insert({
          'provider_id': request['provider_id'],
          'user_id': userId,
          'rating': rating.round(),
          'comment': comment.isEmpty ? null : comment,
          'created_at': DateTime.now().toIso8601String(),
        });
        return true;
      },
    );
    if (saved == true && mounted) {
      setState(() => _reviewedProviderIds.add(request['provider_id'].toString()));
      GlobalErrorHandler.showCustomSuccess('Thank you for your review!');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================
  String _providerName(Map<String, dynamic> r) {
    final p = r['providers'];
    if (p is Map) {
      final users = p['users'];
      final name = users is Map ? users['full_name'] : null;
      return (name ?? p['business_name'] ?? p['profession'] ?? 'Provider').toString();
    }
    return 'Provider';
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return Colors.orange.shade400;
      case 'accepted':
        return _accent;
      case 'completed':
        return Colors.green.shade400;
      case 'rejected':
      case 'cancelled':
        return Colors.red.shade400;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic v) {
    final d = DateTime.tryParse('$v');
    if (d == null) return '';
    return DateFormat('d MMM yyyy, h:mm a').format(d.toLocal());
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgLight,
        foregroundColor: Colors.white,
        title: const Text('My Requests'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                for (final f in const [
                  'all',
                  'pending',
                  'accepted',
                  'completed',
                  'rejected',
                  'cancelled'
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f[0].toUpperCase() + f.substring(1)),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: _accent,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    final items = _filtered;
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No requests yet',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildCard(items[i]),
    );
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final status = (r['status'] ?? 'pending').toString();
    final color = _statusColor(status);
    final title = (r['title'] ?? r['service_type'] ?? r['description'] ?? 'Service request').toString();
    final reviewed = _reviewedProviderIds.contains(r['provider_id'].toString());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _providerName(r),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                _formatDate(r['created_at']),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
              const Spacer(),
              if (r['budget'] != null)
                Text(
                  'Rs. ${r['budget']}',
                  style: const TextStyle(
                      color: _accent, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          if (status == 'pending' ||
              status == 'accepted' ||
              (status == 'completed' && !reviewed)) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: switch (status) {
                'pending' => OutlinedButton.icon(
                    onPressed: () => _cancel(r),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cancel request'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade300,
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                  ),
                'accepted' => ElevatedButton.icon(
                    onPressed: () => _openChat(r),
                    icon: const Icon(Icons.chat_bubble_rounded),
                    label: const Text('Open chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.black,
                    ),
                  ),
                _ => ElevatedButton.icon(
                    onPressed: () => _rate(r),
                    icon: const Icon(Icons.star_rounded),
                    label: const Text('Rate provider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                  ),
              },
            ),
          ],
        ],
      ),
    );
  }
}

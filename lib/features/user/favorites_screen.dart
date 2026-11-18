// lib/features/user/favorites_screen.dart
// Customer's favourite providers (route: /user/favorites).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/services/supabase_service.dart';
import '../../widgets/provider_card.dart';
import '../provider/auth_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> _providers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    final rows = await SupabaseService().getFavorites(userId);
    if (!mounted) return;
    setState(() {
      _providers = rows
          .map((f) => f['providers'])
          .whereType<Map>()
          .map((p) => Map<String, dynamic>.from(p))
          .toList();
      _loading = false;
    });
  }

  void _openRequest(Map<String, dynamic> provider) {
    final isBusiness = provider['is_business'] == true;
    context.push(isBusiness
        ? '/user/business-request/${provider['id']}'
        : '/user/request/${provider['id']}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1d3b27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF38804f),
        foregroundColor: Colors.white,
        title: const Text('Favorite Providers'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF49e8c3)))
          : _providers.isEmpty
              ? const Center(
                  child: Text(
                    'No favorites yet.\nTap ♥ on a provider to save them here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _providers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final p = _providers[i];
                      return ProviderCard(
                        provider: p,
                        onTap: () async {
                          await context.push('/user/provider/${p['id']}');
                          _load(); // may have been un-favourited
                        },
                        onRequest: () => _openRequest(p),
                      );
                    },
                  ),
                ),
    );
  }
}

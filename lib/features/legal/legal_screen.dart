// lib/features/legal/legal_screen.dart
// Shows Privacy Policy / Terms / Account Deletion inside the app.
// Routes are public (reachable from login & register without a session).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'legal_content.dart';

enum LegalPage { privacy, terms, deletion }

extension LegalPageX on LegalPage {
  LegalDocument get document {
    switch (this) {
      case LegalPage.privacy:
        return privacyPolicy;
      case LegalPage.terms:
        return termsOfService;
      case LegalPage.deletion:
        return accountDeletion;
    }
  }

  String get route {
    switch (this) {
      case LegalPage.privacy:
        return '/legal/privacy';
      case LegalPage.terms:
        return '/legal/terms';
      case LegalPage.deletion:
        return '/legal/delete-account';
    }
  }
}

class LegalScreen extends StatelessWidget {
  final LegalPage page;
  const LegalScreen({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    final doc = page.document;
    return Scaffold(
      backgroundColor: const Color(0xFF1d3b27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF38804f),
        foregroundColor: Colors.white,
        title: Text(doc.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/role-selection'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              doc.intro,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            for (final s in doc.sections) ...[
              if (s.heading.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  s.heading,
                  style: const TextStyle(
                    color: Color(0xFF49e8c3),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else
                const SizedBox(height: 12),
              for (final p in s.paragraphs) ...[
                const SizedBox(height: 8),
                Text(
                  p,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
              for (final b in s.bullets)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85))),
                      Expanded(
                        child: Text(
                          b,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Privacy Policy · Terms · Delete Account" link row.
/// Used on login, register and in profile screens.
class LegalLinksRow extends StatelessWidget {
  final bool showDeletion;
  const LegalLinksRow({super.key, this.showDeletion = true});

  @override
  Widget build(BuildContext context) {
    Widget link(String label, LegalPage page) => InkWell(
          onTap: () => context.push(page.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
        );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        link('Privacy Policy', LegalPage.privacy),
        Text('·', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
        link('Terms of Service', LegalPage.terms),
        if (showDeletion) ...[
          Text('·',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
          link('Delete Account', LegalPage.deletion),
        ],
      ],
    );
  }
}

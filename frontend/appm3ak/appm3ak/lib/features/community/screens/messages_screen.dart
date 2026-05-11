import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_providers.dart';
import '../../../providers/community_providers.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final meId = me?.id ?? '';
    final messages = ref.watch(communityMessagesProvider);
    final previews = ref
        .read(communityMessagesProvider.notifier)
        .threadPreviews(currentUserId: meId);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: previews.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Aucune conversation pour le moment.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: previews.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = previews[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(
                      p.otherUserName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      p.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(_timeLabel(p.lastAt)),
                    onTap: () => context.push(
                      '/chat/${p.otherUserId}?name=${Uri.encodeComponent(p.otherUserName)}',
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: messages.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/community-posts'),
              icon: const Icon(Icons.forum_outlined),
              label: const Text('Aller aux posts'),
            ),
    );
  }

  String _timeLabel(DateTime t) {
    final now = DateTime.now();
    final d = now.difference(t);
    if (d.inMinutes < 1) return 'maint.';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) return '${d.inHours} h';
    return '${t.day}/${t.month}';
  }
}


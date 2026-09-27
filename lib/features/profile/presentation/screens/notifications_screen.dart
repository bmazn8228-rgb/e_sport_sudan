import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;
  const NotificationsScreen({super.key, required this.userId});

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      return DateFormat('yyyy/MM/dd hh:mm a').format(timestamp.toDate());
    }
    return '';
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'urgent':
        return Icons.warning_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'social':
        return Icons.people_alt_rounded;
      case 'tournament':
        return Icons.emoji_events_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type, BuildContext context) {
    switch (type) {
      case 'urgent':
        return AppTheme.primaryRed;
      case 'wallet':
        return Colors.green;
      case 'social':
        return Colors.purple;
      case 'tournament':
        return Colors.amber;
      default:
        return AppTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ø§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getUserNotificationsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ø­Ø¯Ø« Ø®Ø·Ø£ Ù ÙŠ ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 80, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø¥Ø´Ø¹Ø§Ø±Ø§Øª Ø­Ø§Ù„ÙŠØ§Ù‹',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = notif['isRead'] ?? false;
              final type = notif['type'] ?? 'general';

              return GestureDetector(
                onTap: () {
                  if (!isRead) {
                    FirestoreService().markNotificationAsRead(userId, notif['id']);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRead 
                        ? Theme.of(context).colorScheme.surface 
                        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead ? Colors.transparent : AppTheme.primaryBlue.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getColorForType(type, context).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconForType(type),
                          color: _getColorForType(type, context),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notif['title'] ?? 'Ø¨Ø¯ÙˆÙ† Ø¹Ù†ÙˆØ§Ù†',
                                    style: TextStyle(
                                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notif['body'] ?? '',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTimestamp(notif['createdAt']),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

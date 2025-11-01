import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: () => provider.markAllAsRead(),
                  child: const Text('Tout marquer lu'),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return const Center(
              child: Text('Aucune notification'),
            );
          }

          return ListView.builder(
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              final isRead = notification['read'] == 1 || notification['read'] == true;

              return Dismissible(
                key: Key(notification['id'].toString()),
                onDismissed: (direction) {
                  if (!isRead) {
                    provider.markAsRead(notification['id'] as int);
                  }
                },
                background: Container(
                  color: Colors.green,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.check, color: Colors.white),
                ),
                child: Card(
                  color: isRead ? Colors.white : Colors.blue.shade50,
                  child: ListTile(
                    leading: Icon(
                      _getIconForType(notification['type'] as String? ?? 'info'),
                      color: isRead ? Colors.grey : Colors.blue,
                    ),
                    title: Text(
                      notification['title'] as String? ?? 'Notification',
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification['message'] as String? ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(notification['created_at'] as String?),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    trailing: isRead
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.mark_email_read),
                            onPressed: () => provider.markAsRead(notification['id'] as int),
                          ),
                    onTap: () {
                      if (!isRead) {
                        provider.markAsRead(notification['id'] as int);
                      }
                      // TODO: Naviguer vers la ressource si resource_type et resource_id disponibles
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'epidemic_alert':
        return Icons.warning;
      case 'new_diagnostic':
        return Icons.medical_services;
      case 'appointment':
        return Icons.event;
      default:
        return Icons.info;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return 'Il y a ${difference.inMinutes} min';
        }
        return 'Il y a ${difference.inHours} h';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} j';
      } else {
        return DateFormat('dd/MM/yyyy').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }
}


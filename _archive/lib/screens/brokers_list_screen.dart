import 'package:flutter/material.dart';
import 'package:testing_flutter/core/l10n/l10n_extension.dart';
import 'package:testing_flutter/models/broker.dart';
import 'package:testing_flutter/data/mock_data.dart';
import 'package:testing_flutter/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:testing_flutter/screens/broker_screen.dart';

class BrokersListScreen extends StatelessWidget {
  const BrokersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Broker> brokers = MockData.brokers;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBackground(context),
        title: Text(context.l10n.activeBrokers),
      ),
      body: ListView.separated(
        itemCount: brokers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final broker = brokers[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.whatsAppGray,
              backgroundImage: broker.profilePhoto.isNotEmpty
                  ? CachedNetworkImageProvider(broker.profilePhoto)
                  : null,
              child: broker.profilePhoto.isEmpty
                  ? const Icon(Icons.person, size: 28, color: Colors.white)
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    broker.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatTime(broker.lastSeen),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.tertiaryText(context),
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Icon(
                  broker.isOnline ? Icons.circle : Icons.schedule,
                  size: 12,
                  color: broker.isOnline
                      ? AppTheme.statusGreen
                      : AppTheme.secondaryText(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    broker.statusText,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: AppTheme.tertiaryText(context),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BrokerScreen(broker: broker)),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    if (diff.inDays > 7) {
      return '${lastSeen.day}/${lastSeen.month}';
    }
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }
}

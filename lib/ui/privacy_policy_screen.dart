import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacy)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            l10n.privacySummary,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          _PrivacySection(
            icon: Icons.storage_outlined,
            title: l10n.privacyLocalDataTitle,
            text: l10n.privacyLocalDataText,
          ),
          _PrivacySection(
            icon: Icons.camera_alt_outlined,
            title: l10n.privacyCameraTitle,
            text: l10n.privacyCameraText,
          ),
          _PrivacySection(
            icon: Icons.notifications_outlined,
            title: l10n.privacyRemindersTitle,
            text: l10n.privacyRemindersText,
          ),
          _PrivacySection(
            icon: Icons.ios_share_outlined,
            title: l10n.privacyExportTitle,
            text: l10n.privacyExportText,
          ),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medical_information_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.medicalDisclaimer,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../data/measurement_repository.dart';
import '../data/tonometer_profile_repository.dart';
import '../domain/tonometer_profile.dart';
import '../l10n/l10n.dart';
import '../services/seven_segment_recognizer.dart';
import '../services/tonometer_profile_backup_service.dart';
import 'new_tonometer_screen.dart';

class TonometersScreen extends StatefulWidget {
  const TonometersScreen({
    required this.repository,
    required this.measurementRepository,
    required this.recognizer,
    super.key,
  });

  final TonometerProfileRepository repository;
  final MeasurementRepository measurementRepository;
  final SevenSegmentRecognizer recognizer;

  @override
  State<TonometersScreen> createState() => _TonometersScreenState();
}

class _TonometersScreenState extends State<TonometersScreen> {
  static const _backupService = TonometerProfileBackupService();
  late Future<({List<TonometerProfileSummary> profiles, String activeId})>
  _profiles;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _profiles = _loadProfiles();
  }

  Future<({List<TonometerProfileSummary> profiles, String activeId})>
  _loadProfiles() async {
    return (
      profiles: await widget.repository.getAll(),
      activeId: await widget.repository.getActiveId(),
    );
  }

  Future<void> _select(String id) async {
    await widget.repository.setActive(id);
    if (mounted) setState(_reload);
  }

  Future<void> _add() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NewTonometerScreen(
          repository: widget.repository,
          measurementRepository: widget.measurementRepository,
          recognizer: widget.recognizer,
        ),
      ),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _edit(TonometerProfileSummary profile) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NewTonometerScreen(
          repository: widget.repository,
          measurementRepository: widget.measurementRepository,
          recognizer: widget.recognizer,
          existingProfileId: profile.id,
        ),
      ),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _delete(TonometerProfileSummary profile) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteTonometerTitle),
        content: Text(l10n.deleteTonometerMessage(profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.doNotDelete),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.deleteCustom(profile.id);
      if (mounted) setState(_reload);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileDeleteFailed(error.toString()))),
      );
    }
  }

  Future<void> _backupProfiles() async {
    final l10n = context.l10n;
    try {
      final backup = await _backupService.create(widget.repository);
      if (!mounted) return;
      if (backup.entries.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.noCustomProfilesToBackup)));
        return;
      }
      await _backupService.share(
        backup,
        shareTitle: l10n.backupProfiles,
        subject: l10n.profilesBackupSubject,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profilesBackupFailed(error.toString()))),
      );
    }
  }

  Future<void> _restoreProfiles() async {
    final l10n = context.l10n;
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (file == null) return;
      final backup = _backupService.decodeBytes(await file.readAsBytes());
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.restoreProfilesTitle),
          content: Text(l10n.restoreProfilesMessage(backup.entries.length)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.restore),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await _backupService.restore(widget.repository, backup);
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profilesRestored(backup.entries.length))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profilesRestoreFailed(error.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tonometers),
        actions: [
          PopupMenuButton<String>(
            tooltip: l10n.profileBackupActions,
            onSelected: (value) {
              switch (value) {
                case 'backup':
                  _backupProfiles();
                case 'restore':
                  _restoreProfiles();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'backup',
                child: ListTile(
                  leading: const Icon(Icons.ios_share_outlined),
                  title: Text(l10n.backupProfiles),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'restore',
                child: ListTile(
                  leading: const Icon(Icons.restore_page_outlined),
                  title: Text(l10n.restoreProfiles),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body:
          FutureBuilder<
            ({List<TonometerProfileSummary> profiles, String activeId})
          >(
            future: _profiles,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!;
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                itemCount: data.profiles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final profile = data.profiles[index];
                  final selected = profile.id == data.activeId;
                  final details = [profile.manufacturer, profile.model]
                      .whereType<String>()
                      .where((item) => item.isNotEmpty)
                      .join(' · ');
                  return Card(
                    child: ListTile(
                      onTap: () => _select(profile.id),
                      title: Text(
                        profile.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        [
                          if (details.isNotEmpty) details,
                          if (profile.builtIn) l10n.builtInProfile,
                          if (selected) l10n.activeTonometer,
                        ].join('\n'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.monitor_heart_outlined,
                          ),
                          if (!profile.builtIn)
                            PopupMenuButton<String>(
                              tooltip: l10n.profileActions,
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _edit(profile);
                                  case 'delete':
                                    _delete(profile);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: const Icon(Icons.edit_outlined),
                                    title: Text(l10n.edit),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: const Icon(Icons.delete_outline),
                                    title: Text(l10n.delete),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: FilledButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: Text(l10n.addTonometer),
          ),
        ),
      ),
    );
  }
}

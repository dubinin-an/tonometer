import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

enum HistoryPeriodMode { all, recent, since }

enum HistoryPeriodUnit { weeks, months }

class HistoryFilter {
  const HistoryFilter({
    this.mode = HistoryPeriodMode.all,
    this.amount = 4,
    this.unit = HistoryPeriodUnit.weeks,
    this.since,
  });

  final HistoryPeriodMode mode;
  final int amount;
  final HistoryPeriodUnit unit;
  final DateTime? since;

  bool get isActive => mode != HistoryPeriodMode.all;

  bool includes(DateTime value, DateTime now) {
    if (mode == HistoryPeriodMode.all) return true;
    final cutoff = switch (mode) {
      HistoryPeriodMode.all => DateTime.fromMillisecondsSinceEpoch(0),
      HistoryPeriodMode.recent =>
        unit == HistoryPeriodUnit.weeks
            ? now.subtract(Duration(days: amount * 7))
            : _subtractMonths(now, amount),
      HistoryPeriodMode.since =>
        since ?? DateTime.fromMillisecondsSinceEpoch(0),
    };
    return !value.isBefore(cutoff);
  }

  static DateTime _subtractMonths(DateTime value, int months) {
    final targetMonth = value.month - months;
    final firstOfTargetMonth = DateTime(value.year, targetMonth);
    final day = value.day.clamp(
      1,
      DateUtils.getDaysInMonth(
        firstOfTargetMonth.year,
        firstOfTargetMonth.month,
      ),
    );
    return DateTime(
      firstOfTargetMonth.year,
      firstOfTargetMonth.month,
      day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }
}

class HistoryFilterScreen extends StatefulWidget {
  const HistoryFilterScreen({required this.initialFilter, super.key});

  final HistoryFilter initialFilter;

  @override
  State<HistoryFilterScreen> createState() => _HistoryFilterScreenState();
}

class _HistoryFilterScreenState extends State<HistoryFilterScreen> {
  late HistoryPeriodMode _mode;
  late HistoryPeriodUnit _unit;
  late int _amount;
  late DateTime _since;

  @override
  void initState() {
    super.initState();
    final filter = widget.initialFilter;
    _mode = filter.mode;
    _unit = filter.unit;
    _amount = filter.amount;
    _since = filter.since ?? DateUtils.dateOnly(DateTime.now());
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _since,
      firstDate: DateTime(2000),
      lastDate: DateUtils.dateOnly(DateTime.now()),
      helpText: context.l10n.filterSinceDate,
    );
    if (selected != null && mounted) setState(() => _since = selected);
  }

  void _apply() {
    Navigator.of(context).pop(
      HistoryFilter(
        mode: _mode,
        amount: _amount,
        unit: _unit,
        since: DateUtils.dateOnly(_since),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.displayedData)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
          children: [
            _ModeTile(
              title: l10n.filterAll,
              selected: _mode == HistoryPeriodMode.all,
              onTap: () => setState(() => _mode = HistoryPeriodMode.all),
            ),
            const SizedBox(height: 8),
            _ModeTile(
              title: l10n.filterRecent,
              selected: _mode == HistoryPeriodMode.recent,
              onTap: () => setState(() => _mode = HistoryPeriodMode.recent),
            ),
            if (_mode == HistoryPeriodMode.recent) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.periodLength,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton.outlined(
                            tooltip: l10n.decreasePeriod,
                            onPressed: _amount <= 1
                                ? null
                                : () => setState(() => _amount--),
                            icon: const Icon(Icons.remove),
                          ),
                          Expanded(
                            child: Text(
                              '$_amount',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton.outlined(
                            tooltip: l10n.increasePeriod,
                            onPressed: _amount >= 52
                                ? null
                                : () => setState(() => _amount++),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<HistoryPeriodUnit>(
                        segments: [
                          ButtonSegment(
                            value: HistoryPeriodUnit.weeks,
                            label: Text(l10n.weeks),
                          ),
                          ButtonSegment(
                            value: HistoryPeriodUnit.months,
                            label: Text(l10n.months),
                          ),
                        ],
                        selected: {_unit},
                        onSelectionChanged: (value) =>
                            setState(() => _unit = value.single),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            _ModeTile(
              title: l10n.filterSinceDate,
              selected: _mode == HistoryPeriodMode.since,
              onTap: () => setState(() => _mode = HistoryPeriodMode.since),
            ),
            if (_mode == HistoryPeriodMode.since) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  MaterialLocalizations.of(context).formatMediumDate(_since),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: FilledButton.icon(
          onPressed: _apply,
          icon: const Icon(Icons.check),
          label: Text(l10n.applyFilter),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: selected ? colors.primaryContainer : null,
      child: ListTile(
        minTileHeight: 64,
        onTap: onTap,
        title: Text(title),
        trailing: Icon(
          selected ? Icons.check_circle : Icons.circle_outlined,
          color: selected ? colors.primary : colors.outline,
        ),
      ),
    );
  }
}

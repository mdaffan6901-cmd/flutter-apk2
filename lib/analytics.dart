import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart';

class AnalyticsPage extends StatefulWidget {
  final AppState s;
  const AnalyticsPage(this.s, {super.key});
  @override
  State<AnalyticsPage> createState() => _A();
}

class _A extends State<AnalyticsPage> {
  int r = 30, sel = -1;
  String hid = 'all';
  @override
  Widget build(BuildContext c) {
    final s = widget.s, cs = Theme.of(c).colorScheme, tt = Theme.of(c).textTheme, t = today();
    final all = s.active;
    if (all.isEmpty) return page('Analytics', [empty(c, Icons.insights_rounded, 'No data yet', 'Add habits or load sample data in Settings to see insights.')]);
    final f = all.where((h) => hid == 'all' || h.id == hid).toList(), use = f.isEmpty ? all : f;
    final days = [for (var i = r - 1; i >= 0; i--) ago(i)];
    final size = r <= 30 ? 1 : (r == 90 ? 7 : 30);
    final buckets = [for (var i = 0; i < days.length; i += size) days.sublist(i, min(i + size, days.length))];
    final vals = [for (final b in buckets) pct(cnt(use, b))];
    final total = cnt(use, days);
    final cur = use.fold(0, (a, h) => max(a, h.streak)), bst = use.fold(0, (a, h) => max(a, h.best));
    final act = days.where((d) => use.any((h) => h.has(d))).length / r;
    final wk = r >= 365 ? 53 : 26;
    final st = DateTime(t.year, t.month, t.day - (wk - 1) * 7 - (t.weekday - s.week + 7) % 7);
    Widget cell(DateTime x) {
      if (x.isAfter(t)) return const SizedBox(width: 16, height: 16);
      final n = cnt(use, [x]);
      return Tooltip(message: '${s.date(x)}: ${n[0]}/${n[1]}', child: Container(width: 13, height: 13, margin: const EdgeInsets.all(1.5), decoration: BoxDecoration(color: n[0] == 0 ? cs.surfaceContainerHighest : cs.primary.withValues(alpha: .25 + .75 * n[0] / n[1]), borderRadius: BorderRadius.circular(3))));
    }
    Widget bar(double v, Color col, [String? l, String? rt]) => Row(children: [if (l != null) SizedBox(width: 90, child: Text(l, overflow: TextOverflow.ellipsis)), Expanded(child: TweenAnimationBuilder<double>(tween: Tween<double>(end: v), duration: s.dur, curve: Curves.easeOutCubic, builder: (_, x, __) => LinearProgressIndicator(value: x, color: col, minHeight: 8, borderRadius: BorderRadius.circular(4)))), SizedBox(width: 48, child: Text(rt ?? '${(v * 100).round()}%', textAlign: TextAlign.end))]);
    return page('Analytics', [
      Wrap(spacing: 12, runSpacing: 12, children: [
        SegmentedButton<int>(segments: [for (final x in [7, 30, 90, 365]) ButtonSegment(value: x, label: Text(x == 365 ? '1Y' : '${x}D'))], selected: {r}, onSelectionChanged: (v) => setState(() { r = v.first; sel = -1; })),
        DropdownMenu<String>(initialSelection: hid, onSelected: (v) => setState(() { hid = v ?? 'all'; sel = -1; }), dropdownMenuEntries: [const DropdownMenuEntry(value: 'all', label: 'All habits'), for (final h in all) DropdownMenuEntry(value: h.id, label: h.name)]),
      ]),
      const SizedBox(height: 16),
      Row(children: [stat(c, Icons.task_alt_rounded, '${(pct(total) * 100).round()}%', 'Completion'), stat(c, Icons.event_available_rounded, '${(act * 100).round()}%', 'Consistency')]),
      Row(children: [stat(c, Icons.local_fire_department_rounded, '$cur', 'Current streak'), stat(c, Icons.emoji_events_rounded, '$bst', 'Best streak')]),
      sec(c, r <= 30 ? 'Daily trend' : r == 90 ? 'Weekly trend' : 'Monthly trend'),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: 190, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < vals.length; i++)
            Expanded(child: Tooltip(message: '${s.date(buckets[i].first)}: ${(vals[i] * 100).round()}%', child: GestureDetector(onTap: () => setState(() => sel = sel == i ? -1 : i), child: Container(color: Colors.transparent, alignment: Alignment.bottomCenter, child: AnimatedContainer(duration: s.dur, curve: Curves.easeOutCubic, height: 8 + 170 * vals[i], margin: EdgeInsets.symmetric(horizontal: r == 30 ? 1.5 : 3), decoration: BoxDecoration(color: sel == i ? cs.primary : cs.primary.withValues(alpha: .4), borderRadius: BorderRadius.circular(min(s.radius, 6)))))))),
        ])),
        const SizedBox(height: 12),
        Text(sel < 0 ? 'Tap a bar for details' : '${s.date(buckets[sel].first)} · ${(vals[sel] * 100).round()}% (${cnt(use, buckets[sel])[0]}/${cnt(use, buckets[sel])[1]})', style: tt.bodySmall),
      ]))),
      sec(c, 'Activity'),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: SingleChildScrollView(scrollDirection: Axis.horizontal, reverse: true, child: Row(children: [for (var w = 0; w < wk; w++) Column(children: [for (var d = 0; d < 7; d++) cell(DateTime(st.year, st.month, st.day + w * 7 + d))])])))),
      sec(c, 'Categories'),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        for (final g in cats) if (use.any((h) => h.cat == g)) Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: bar(pct(cnt(use.where((h) => h.cat == g).toList(), days)), cs.primary, g)),
      ]))),
      sec(c, 'Per habit'),
      for (final h in use)
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icons[h.icon], color: h.c), const SizedBox(width: 10), Expanded(child: Text(h.name, style: tt.titleMedium)), Text('${(pct(cnt([h], days)) * 100).round()}%', style: tt.titleMedium)]),
          const SizedBox(height: 10),
          bar(pct(cnt([h], days)), h.c),
          const SizedBox(height: 8),
          Text('Streak ${h.streak} · Best ${h.best} · Month ${h.monthDone}/${h.goal} · Total ${h.done.length}', style: tt.bodySmall),
        ]))),
    ]);
  }
}

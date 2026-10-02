import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart';

Future<void> editor(BuildContext c, AppState s, [Habit? h]) => showModalBottomSheet<void>(context: c, isScrollControlled: true, showDragHandle: true, useSafeArea: true, constraints: const BoxConstraints(maxWidth: 600), builder: (_) => Editor(s, h));

Future<bool> confirm(BuildContext c, String t, String m, String ok) async => await showDialog<bool>(
        context: c,
        builder: (x) => AlertDialog(title: Text(t), content: Text(m), actions: [TextButton(onPressed: () => Navigator.pop(x, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(x, true), child: Text(ok))])) ??
    false;

class HabitTile extends StatelessWidget {
  final AppState s;
  final Habit h;
  final DateTime d;
  final bool menu;
  const HabitTile(this.s, this.h, this.d, {this.menu = false, super.key});
  @override
  Widget build(BuildContext c) {
    final done = h.has(d), cs = Theme.of(c).colorScheme, tt = Theme.of(c).textTheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(s.radius),
        onTap: h.archived ? null : () => s.toggle(h, d),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            AnimatedContainer(duration: s.dur, width: 48, height: 48, decoration: BoxDecoration(color: done ? h.c : h.c.withValues(alpha: .14), borderRadius: BorderRadius.circular(s.radius * .7)), child: Icon(icons[h.icon], color: done ? Colors.white : h.c)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.name, style: tt.titleMedium?.copyWith(decoration: done ? TextDecoration.lineThrough : null)),
              Text('${h.cat} · ${h.streak} day streak${h.remind == null ? '' : ' · ${h.remind}'}', style: tt.bodySmall),
              if (menu) ...[
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(tween: Tween<double>(end: min(1.0, h.monthDone / h.goal)), duration: s.dur, builder: (_, v, __) => LinearProgressIndicator(value: v, color: h.c, minHeight: 6, borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 2),
                Text('${h.monthDone}/${h.goal} this month', style: tt.labelSmall),
              ],
            ])),
            if (!h.archived) AnimatedSwitcher(duration: s.dur, child: Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, key: ValueKey(done), color: done ? h.c : cs.outline)),
            if (menu)
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'e') {
                    editor(c, s, h);
                  } else if (v == 'a') {
                    s.set(() => h.archived = !h.archived);
                  } else if (await confirm(c, 'Delete "${h.name}"?', 'This permanently removes the habit and its history.', 'Delete')) {
                    s.set(() => s.habits.remove(h));
                  }
                },
                itemBuilder: (_) => [const PopupMenuItem(value: 'e', child: Text('Edit')), PopupMenuItem(value: 'a', child: Text(h.archived ? 'Restore' : 'Archive')), const PopupMenuItem(value: 'd', child: Text('Delete'))],
              ),
          ]),
        ),
      ),
    );
  }
}

class HabitsPage extends StatefulWidget {
  final AppState s;
  const HabitsPage(this.s, {super.key});
  @override
  State<HabitsPage> createState() => _H();
}

class _H extends State<HabitsPage> {
  bool arch = false;
  String? cat;
  @override
  Widget build(BuildContext c) {
    final s = widget.s, t = today();
    final list = s.habits.where((h) => h.archived == arch && (cat == null || h.cat == cat)).toList();
    return page('Habits', [
      SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('Active'), icon: Icon(Icons.bolt_rounded)), ButtonSegment(value: true, label: Text('Archived'), icon: Icon(Icons.inventory_2_outlined))], selected: {arch}, onSelectionChanged: (v) => setState(() => arch = v.first)),
      const SizedBox(height: 12),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final x in [null, ...cats]) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(x ?? 'All'), selected: cat == x, onSelected: (_) => setState(() => cat = x)))])),
      const SizedBox(height: 12),
      if (list.isEmpty) empty(c, arch ? Icons.inventory_2_outlined : Icons.add_task_rounded, arch ? 'Nothing archived' : 'No habits found', arch ? 'Archived habits appear here.' : 'Tap "New habit" to create one.'),
      for (final h in list) HabitTile(s, h, t, menu: true),
    ]);
  }
}

class Editor extends StatefulWidget {
  final AppState s;
  final Habit? h;
  const Editor(this.s, this.h, {super.key});
  @override
  State<Editor> createState() => _E();
}

class _E extends State<Editor> {
  late final n = TextEditingController(text: widget.h?.name);
  late String cat = widget.h?.cat ?? cats.first;
  late int ic = widget.h?.icon ?? 0, co = widget.h?.color ?? 0, goal = widget.h?.goal ?? 20;
  late Set<int> days = {...(widget.h?.days ?? {1, 2, 3, 4, 5, 6, 7})};
  late String? rm = widget.h?.remind;
  Widget lb(String t) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 8), child: Text(t, style: Theme.of(context).textTheme.labelLarge));
  void save() {
    final s = widget.s;
    var h = widget.h;
    if (h == null) { h = Habit(id: DateTime.now().microsecondsSinceEpoch.toString(), name: ''); s.habits.add(h); }
    h..name = n.text.trim()..cat = cat..icon = ic..color = co..goal = goal..days = days..remind = rm;
    s.fb();
    s.save();
    Navigator.pop(context);
  }
  @override
  Widget build(BuildContext c) {
    final cs = Theme.of(c).colorScheme, ok = n.text.trim().isNotEmpty && days.isNotEmpty;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(c).bottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.h == null ? 'New habit' : 'Edit habit', style: Theme.of(c).textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextField(controller: n, autofocus: true, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Name')),
        lb('Category'),
        Wrap(spacing: 8, children: [for (final x in cats) ChoiceChip(label: Text(x), selected: cat == x, onSelected: (_) => setState(() => cat = x))]),
        lb('Icon'),
        Wrap(spacing: 8, runSpacing: 8, children: [for (var i = 0; i < icons.length; i++) ic == i ? IconButton.filled(onPressed: () {}, icon: Icon(icons[i])) : IconButton.filledTonal(onPressed: () => setState(() => ic = i), icon: Icon(icons[i]))]),
        lb('Color'),
        Wrap(spacing: 12, children: [for (var i = 0; i < accents.length; i++) Semantics(button: true, label: 'Color ${i + 1}', child: GestureDetector(onTap: () => setState(() => co = i), child: AnimatedContainer(duration: widget.s.dur, width: 36, height: 36, decoration: BoxDecoration(color: accents[i], shape: BoxShape.circle, border: Border.all(color: co == i ? cs.onSurface : Colors.transparent, width: 3)), child: co == i ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null)))]),
        lb('Frequency'),
        Wrap(spacing: 8, children: [ActionChip(label: const Text('Daily'), onPressed: () => setState(() => days = {1, 2, 3, 4, 5, 6, 7})), ActionChip(label: const Text('Weekdays'), onPressed: () => setState(() => days = {1, 2, 3, 4, 5})), ActionChip(label: const Text('Weekends'), onPressed: () => setState(() => days = {6, 7}))]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [for (var i = 1; i <= 7; i++) FilterChip(label: Text(dayNames[i - 1]), selected: days.contains(i), onSelected: (v) => setState(() => v ? days.add(i) : days.remove(i)))]),
        lb('Monthly goal: $goal days'),
        Slider(value: goal.toDouble(), min: 1, max: 31, divisions: 30, label: '$goal', onChanged: (v) => setState(() => goal = v.round())),
        lb('Reminder'),
        InputChip(
          avatar: const Icon(Icons.alarm_rounded, size: 18),
          label: Text(rm ?? 'Add reminder'),
          onPressed: () async {
            final t = await showTimePicker(context: c, initialTime: const TimeOfDay(hour: 9, minute: 0));
            if (t != null) setState(() => rm = '${two(t.hour)}:${two(t.minute)}');
          },
          onDeleted: rm == null ? null : () => setState(() => rm = null),
        ),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')), const SizedBox(width: 8), FilledButton(onPressed: ok ? save : null, child: const Text('Save'))]),
      ]),
    );
  }
}

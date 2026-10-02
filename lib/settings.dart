import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';
import 'habits.dart';

class SettingsPage extends StatelessWidget {
  final AppState s;
  const SettingsPage(this.s, {super.key});
  @override
  Widget build(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    void snack(String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));
    Widget item(String t, Widget w) => Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: Theme.of(c).textTheme.titleSmall), const SizedBox(height: 10), w]));
    Widget chips(List<String> l, int v, void Function(int) f, [List<int>? ids]) => Wrap(spacing: 8, runSpacing: 8, children: [for (var i = 0; i < l.length; i++) ChoiceChip(label: Text(l[i]), selected: v == (ids?[i] ?? i), onSelected: (_) => s.set(() => f(ids?[i] ?? i)))]);
    Widget sw(String t, String sub, bool v, void Function(bool) f) => SwitchListTile(title: Text(t), subtitle: Text(sub), value: v, onChanged: (x) => s.set(() => f(x)));
    Widget act(IconData i, String t, String sub, VoidCallback f) => ListTile(leading: Icon(i), title: Text(t), subtitle: Text(sub), onTap: f);
    Future<void> imp() async {
      final t = TextEditingController();
      final ok = await showDialog<bool>(context: c, builder: (x) => AlertDialog(title: const Text('Import data'), content: TextField(controller: t, maxLines: 8, decoration: const InputDecoration(hintText: 'Paste exported JSON')), actions: [TextButton(onPressed: () => Navigator.pop(x, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(x, true), child: const Text('Import'))]));
      if (ok != true || !c.mounted) return;
      try { s.apply(jsonDecode(t.text)); s.save(); snack('Data imported'); } catch (_) { snack('Invalid data, nothing was changed'); }
    }
    return page('Settings', [
      sec(c, 'Appearance'),
      Card(child: Column(children: [
        item('Theme', SegmentedButton<int>(segments: const [ButtonSegment(value: 0, label: Text('System'), icon: Icon(Icons.brightness_auto_rounded)), ButtonSegment(value: 1, label: Text('Light'), icon: Icon(Icons.light_mode_rounded)), ButtonSegment(value: 2, label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded))], selected: {s.mode}, onSelectionChanged: (v) => s.set(() => s.mode = v.first))),
        item('Accent color', Wrap(spacing: 12, children: [for (var i = 0; i < accents.length; i++) Semantics(button: true, label: 'Accent ${i + 1}', child: GestureDetector(onTap: () => s.set(() => s.accent = i), child: AnimatedContainer(duration: s.dur, width: 40, height: 40, decoration: BoxDecoration(color: accents[i], shape: BoxShape.circle, border: Border.all(color: s.accent == i ? cs.onSurface : Colors.transparent, width: 3)), child: s.accent == i ? const Icon(Icons.check_rounded, color: Colors.white) : null)))])),
        item('Corner radius: ${s.radius.round()}', Slider(value: s.radius, min: 4, max: 32, divisions: 14, onChanged: (v) => s.set(() => s.radius = v))),
        item('Font', chips(const ['Roboto', 'Georgia', 'Courier'], s.font, (v) => s.font = v)),
        sw('Animations', 'Smooth transitions and progress motion', s.anim, (v) => s.anim = v),
      ])),
      sec(c, 'Preferences'),
      Card(child: Column(children: [
        item('Week starts on', chips(const ['Monday', 'Saturday', 'Sunday'], s.week, (v) => s.week = v, [1, 6, 7])),
        item('Date format', chips(const ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'], s.fmt, (v) => s.fmt = v)),
        sw('Reminder alerts', 'Show due reminders on Home while the app is open', s.notif, (v) => s.notif = v),
        sw('Sound', 'Play a click when completing habits', s.sound, (v) => s.sound = v),
        sw('Haptics', 'Vibrate on supported devices', s.haptic, (v) => s.haptic = v),
      ])),
      sec(c, 'Data'),
      Card(child: Column(children: [
        act(Icons.auto_awesome_rounded, 'Load sample data', 'Add demo habits with history', () { s.demo(); snack('Sample data added'); }),
        act(Icons.upload_rounded, 'Export data', 'Copy a JSON backup to the clipboard', () { Clipboard.setData(ClipboardData(text: jsonEncode(s.toJson()))); snack('Backup copied to clipboard'); }),
        act(Icons.download_rounded, 'Import data', 'Paste a JSON backup', imp),
        act(Icons.restart_alt_rounded, 'Reset settings', 'Restore default appearance and preferences', () async { if (await confirm(c, 'Reset settings?', 'Your habits are kept.', 'Reset')) s.resetSettings(); }),
        act(Icons.delete_forever_rounded, 'Clear all data', 'Delete every habit and its history', () async { if (await confirm(c, 'Clear all data?', 'This cannot be undone.', 'Clear')) s.set(() => s.habits = []); }),
      ])),
      sec(c, 'About'),
      Card(child: act(Icons.info_outline_rounded, 'Habit Tracker', 'Version 1.0.0 · data stays in this browser', () => showAboutDialog(context: c, applicationName: 'Habit Tracker', applicationVersion: '1.0.0', applicationLegalese: 'All data is stored locally on this device.'))),
    ]);
  }
}

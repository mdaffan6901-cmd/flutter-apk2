import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics.dart';
import 'habits.dart';
import 'settings.dart';

const accents = [Color(0xFF3F6AE0), Color(0xFF00897B), Color(0xFF7E57C2), Color(0xFFE64A19), Color(0xFFC2185B), Color(0xFF6D8B2F)];
const cats = ['Health', 'Mind', 'Work', 'Learning', 'Social', 'Other'];
const fonts = ['Roboto', 'Georgia', 'Courier New'];
const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const icons = [Icons.fitness_center_rounded, Icons.self_improvement_rounded, Icons.menu_book_rounded, Icons.water_drop_rounded, Icons.bedtime_rounded, Icons.code_rounded, Icons.savings_rounded, Icons.directions_run_rounded, Icons.restaurant_rounded, Icons.brush_rounded, Icons.music_note_rounded, Icons.people_rounded];

String two(int n) => n.toString().padLeft(2, '0');
String k(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
DateTime today() { final n = DateTime.now(); return DateTime(n.year, n.month, n.day); }
DateTime ago(int n) { final t = today(); return DateTime(t.year, t.month, t.day - n); }
List<int> cnt(List<Habit> hs, List<DateTime> ds) { var a = 0, b = 0; for (final h in hs) { for (final d in ds) { if (h.on(d)) { b++; if (h.has(d)) a++; } } } return [a, b]; }
double pct(List<int> c) => c[1] == 0 ? 0 : c[0] / c[1];

class Habit {
  String id, name, cat;
  int icon, color, goal;
  Set<int> days;
  String? remind;
  bool archived;
  Set<String> done;
  Habit({required this.id, required this.name, this.cat = 'Other', this.icon = 0, this.color = 0, this.goal = 20, Set<int>? days, this.remind, this.archived = false, Set<String>? done})
      : days = days ?? {1, 2, 3, 4, 5, 6, 7}, done = done ?? {};
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'cat': cat, 'icon': icon, 'color': color, 'goal': goal, 'days': days.toList(), 'remind': remind, 'archived': archived, 'done': done.toList()};
  factory Habit.fromJson(Map j) => Habit(id: j['id'], name: j['name'], cat: j['cat'], icon: j['icon'], color: j['color'], goal: j['goal'], days: Set<int>.from(j['days']), remind: j['remind'], archived: j['archived'], done: Set<String>.from(j['done']));
  Color get c => accents[color % accents.length];
  bool on(DateTime d) => days.contains(d.weekday);
  bool has(DateTime d) => done.contains(k(d));
  int get monthDone { final t = today(); final p = '${t.year}-${two(t.month)}'; return done.where((x) => x.startsWith(p)).length; }
  int get streak {
    var d = today(), n = 0;
    if (on(d) && !has(d)) d = DateTime(d.year, d.month, d.day - 1);
    for (var i = 0; i < 1000; i++) {
      if (on(d)) { if (has(d)) { n++; } else { break; } }
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }
  int get best {
    if (done.isEmpty) return 0;
    var d = DateTime.parse(done.reduce((a, b) => a.compareTo(b) < 0 ? a : b)), r = 0, m = 0;
    while (!d.isAfter(today())) {
      if (on(d)) { if (has(d)) { r++; m = max(m, r); } else { r = 0; } }
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return m;
  }
}

class AppState extends ChangeNotifier {
  List<Habit> habits = [];
  int mode = 0, accent = 0, font = 0, week = 1, fmt = 0;
  double radius = 16;
  bool anim = true, notif = false, sound = false, haptic = true, ready = false;
  String? err;
  SharedPreferences? p;
  List<Habit> get active => habits.where((h) => !h.archived).toList();
  Duration get dur => Duration(milliseconds: anim ? 300 : 0);
  String date(DateTime d) => ['${two(d.day)}/${two(d.month)}/${d.year}', '${two(d.month)}/${two(d.day)}/${d.year}', k(d)][fmt];
  Future<void> load() async {
    p = await SharedPreferences.getInstance();
    try { final r = p!.getString('d'); if (r != null) apply(jsonDecode(r)); } catch (_) { err = 'Saved data could not be read.'; }
    ready = true;
    notifyListeners();
  }
  void apply(Map j) {
    habits = [for (final h in j['habits'] ?? []) Habit.fromJson(h)];
    mode = j['mode'] ?? 0; accent = j['accent'] ?? 0; font = j['font'] ?? 0; week = j['week'] ?? 1; fmt = j['fmt'] ?? 0;
    radius = (j['radius'] ?? 16).toDouble();
    anim = j['anim'] ?? true; notif = j['notif'] ?? false; sound = j['sound'] ?? false; haptic = j['haptic'] ?? true;
  }
  Map<String, dynamic> toJson() => {'habits': habits.map((h) => h.toJson()).toList(), 'mode': mode, 'accent': accent, 'font': font, 'week': week, 'fmt': fmt, 'radius': radius, 'anim': anim, 'notif': notif, 'sound': sound, 'haptic': haptic};
  void save() { p?.setString('d', jsonEncode(toJson())); notifyListeners(); }
  void set(VoidCallback f) { f(); save(); }
  void fb() { if (haptic) HapticFeedback.selectionClick(); if (sound) SystemSound.play(SystemSoundType.click); }
  void toggle(Habit h, DateTime d) { h.has(d) ? h.done.remove(k(d)) : h.done.add(k(d)); fb(); save(); }
  void markAll(List<Habit> hs) { for (final h in hs) { h.done.add(k(today())); } fb(); save(); }
  void resetSettings() { mode = 0; accent = 0; font = 0; week = 1; fmt = 0; radius = 16; anim = true; notif = false; sound = false; haptic = true; save(); }
  void demo() {
    final r = Random(7);
    for (final (n, i, c, g) in const [('Morning run', 7, 0, 'Health'), ('Read 20 pages', 2, 2, 'Learning'), ('Meditate', 1, 1, 'Mind'), ('Drink water', 3, 3, 'Health'), ('Deep work', 5, 4, 'Work'), ('Call a friend', 11, 5, 'Social')]) {
      final h = Habit(id: '${DateTime.now().microsecondsSinceEpoch}$i', name: n, icon: i, color: c, cat: g, days: i == 5 ? {1, 2, 3, 4, 5} : null, remind: i == 1 ? '20:00' : null);
      for (var x = 0; x < 150; x++) { final d = ago(x); if (h.on(d) && r.nextDouble() < .55 + .3 * (1 - x / 150)) h.done.add(k(d)); }
      habits.add(h);
    }
    save();
  }
}

Widget page(String t, List<Widget> kids) => Builder(builder: (c) => Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 960), child: ListView(padding: const EdgeInsets.fromLTRB(20, 28, 20, 110), children: [Text(t, style: Theme.of(c).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 20), ...kids]))));
Widget sec(BuildContext c, String t) => Padding(padding: const EdgeInsets.only(top: 28, bottom: 10), child: Text(t, style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)));
Widget stat(BuildContext c, IconData i, String v, String l) {
  final th = Theme.of(c);
  return Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: th.colorScheme.primary), const SizedBox(height: 12), Text(v, style: th.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)), Text(l, style: th.textTheme.bodySmall)]))));
}
Widget empty(BuildContext c, IconData i, String t, String m, [Widget? a]) => Padding(padding: const EdgeInsets.symmetric(vertical: 48), child: Center(child: Column(children: [Icon(i, size: 56, color: Theme.of(c).colorScheme.outline), const SizedBox(height: 16), Text(t, style: Theme.of(c).textTheme.titleLarge), const SizedBox(height: 4), Text(m, textAlign: TextAlign.center), if (a != null) ...[const SizedBox(height: 20), a]])));

void main() => runApp(const App());

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppS();
}

class _AppS extends State<App> {
  final s = AppState();
  @override
  void initState() { super.initState(); s.load(); }
  ThemeData th(Brightness b) {
    final sh = RoundedRectangleBorder(borderRadius: BorderRadius.circular(s.radius));
    return ThemeData(useMaterial3: true, brightness: b, colorSchemeSeed: accents[s.accent], fontFamily: fonts[s.font], fontFamilyFallback: const ['Roboto', 'sans-serif'],
      cardTheme: CardThemeData(elevation: 0, shape: sh), filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: sh)), dialogTheme: DialogThemeData(shape: sh),
      bottomSheetTheme: BottomSheetThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(s.radius + 8)))),
      floatingActionButtonTheme: FloatingActionButtonThemeData(shape: sh), inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(s.radius))));
  }
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: s, builder: (_, __) => MaterialApp(title: 'Habit Tracker', debugShowCheckedModeBanner: false, themeMode: ThemeMode.values[s.mode], theme: th(Brightness.light), darkTheme: th(Brightness.dark), home: Shell(s)));
}

class Shell extends StatefulWidget {
  final AppState s;
  const Shell(this.s, {super.key});
  @override
  State<Shell> createState() => _ShellS();
}

class _ShellS extends State<Shell> {
  int i = 0;
  static const nav = [(Icons.home_outlined, Icons.home_rounded, 'Home'), (Icons.task_alt_outlined, Icons.task_alt_rounded, 'Habits'), (Icons.insights_outlined, Icons.insights_rounded, 'Analytics'), (Icons.settings_outlined, Icons.settings_rounded, 'Settings')];
  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final pages = [HomePage(s), HabitsPage(s), AnalyticsPage(s), SettingsPage(s)];
    final body = s.ready
        ? AnimatedSwitcher(duration: s.dur, transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, .02), end: Offset.zero).animate(a), child: c)), child: KeyedSubtree(key: ValueKey(i), child: pages[i]))
        : const Center(child: CircularProgressIndicator());
    return LayoutBuilder(builder: (c, box) {
      final wide = box.maxWidth >= 800;
      return Scaffold(
        body: wide
            ? Row(children: [NavigationRail(selectedIndex: i, extended: box.maxWidth >= 1100, onDestinationSelected: (n) => setState(() => i = n), destinations: [for (final n in nav) NavigationRailDestination(icon: Icon(n.$1), selectedIcon: Icon(n.$2), label: Text(n.$3))]), const VerticalDivider(width: 1), Expanded(child: body)])
            : body,
        bottomNavigationBar: wide ? null : NavigationBar(selectedIndex: i, onDestinationSelected: (n) => setState(() => i = n), destinations: [for (final n in nav) NavigationDestination(icon: Icon(n.$1), selectedIcon: Icon(n.$2), label: n.$3)]),
        floatingActionButton: i < 2 && s.ready ? FloatingActionButton.extended(onPressed: () => editor(context, s), icon: const Icon(Icons.add_rounded), label: const Text('New habit')) : null,
      );
    });
  }
}

class HomePage extends StatelessWidget {
  final AppState s;
  const HomePage(this.s, {super.key});
  @override
  Widget build(BuildContext c) {
    final t = today(), th = Theme.of(c), cs = th.colorScheme, now = TimeOfDay.now();
    final hs = s.active.where((h) => h.on(t)).toList();
    final dn = hs.where((h) => h.has(t)).length;
    final p = hs.isEmpty ? 0.0 : dn / hs.length;
    final best = s.active.fold(0, (a, h) => max(a, h.streak));
    final week = pct(cnt(s.active, [for (var i = 0; i < 7; i++) ago(i)]));
    final List<Habit> due = s.notif ? hs.where((h) => !h.has(t) && h.remind != null && int.parse(h.remind!.substring(0, 2)) * 60 + int.parse(h.remind!.substring(3)) <= now.hour * 60 + now.minute).toList() : [];
    final hr = DateTime.now().hour;
    return page(hr < 12 ? 'Good morning' : hr < 18 ? 'Good afternoon' : 'Good evening', [
      Text(s.date(t), style: th.textTheme.bodyLarge?.copyWith(color: cs.outline)),
      const SizedBox(height: 16),
      if (s.err != null) Card(color: cs.errorContainer, child: ListTile(leading: Icon(Icons.error_outline_rounded, color: cs.onErrorContainer), title: Text(s.err!, style: TextStyle(color: cs.onErrorContainer)))),
      if (due.isNotEmpty) Card(color: cs.tertiaryContainer, child: ListTile(leading: Icon(Icons.alarm_rounded, color: cs.onTertiaryContainer), title: Text('Due now: ${due.map((h) => h.name).join(', ')}', style: TextStyle(color: cs.onTertiaryContainer)))),
      Card(child: Padding(padding: const EdgeInsets.all(24), child: Row(children: [
        TweenAnimationBuilder<double>(tween: Tween<double>(end: p), duration: s.dur, curve: Curves.easeOutCubic, builder: (_, v, __) => SizedBox(width: 96, height: 96, child: Stack(alignment: Alignment.center, children: [SizedBox.expand(child: CircularProgressIndicator(value: v, strokeWidth: 10, strokeCap: StrokeCap.round, backgroundColor: cs.surfaceContainerHighest)), Text('${(v * 100).round()}%', style: th.textTheme.titleLarge)]))),
        const SizedBox(width: 24),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$dn of ${hs.length} done today', style: th.textTheme.titleLarge), const SizedBox(height: 4), Text(hs.isEmpty ? 'Nothing scheduled for today.' : dn == hs.length ? 'All done. Great work!' : '${hs.length - dn} left to go.')])),
      ]))),
      Row(children: [stat(c, Icons.local_fire_department_rounded, '$best', 'Best current streak'), stat(c, Icons.checklist_rounded, '${s.active.length}', 'Active habits'), stat(c, Icons.trending_up_rounded, '${(week * 100).round()}%', 'Last 7 days')]),
      sec(c, "Today's habits"),
      if (s.active.isEmpty)
        empty(c, Icons.add_task_rounded, 'No habits yet', 'Create your first habit or explore with sample data.', Wrap(spacing: 8, children: [FilledButton.icon(onPressed: () => editor(c, s), icon: const Icon(Icons.add_rounded), label: const Text('New habit')), OutlinedButton.icon(onPressed: s.demo, icon: const Icon(Icons.auto_awesome_rounded), label: const Text('Load sample data'))]))
      else ...[
        if (hs.isNotEmpty && dn < hs.length) Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(bottom: 8), child: FilledButton.tonalIcon(onPressed: () => s.markAll(hs), icon: const Icon(Icons.done_all_rounded), label: const Text('Complete all')))),
        if (hs.isEmpty) empty(c, Icons.weekend_rounded, 'Rest day', 'No habits scheduled today.'),
        for (final h in hs) HabitTile(s, h, t),
      ],
    ]);
  }
}

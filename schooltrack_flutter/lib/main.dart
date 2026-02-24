import "dart:async";

import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:schooltrack_flutter/firebase_options.dart";
import "package:schooltrack_flutter/models/app_models.dart";
import "package:schooltrack_flutter/pages/login_page.dart";
import "package:schooltrack_flutter/services/firestore_data_service.dart";
import "package:schooltrack_flutter/services/firebase_notification_service.dart";
import "package:schooltrack_flutter/state/app_state.dart";
import "package:schooltrack_flutter/widgets/common_widgets.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SchoolTrackApp());
}

class SchoolTrackApp extends StatefulWidget {
  const SchoolTrackApp({super.key});
  @override
  State<SchoolTrackApp> createState() => _SchoolTrackAppState();
}

class _SchoolTrackAppState extends State<SchoolTrackApp> {
  final state = AppState.seed();

  @override
  void initState() {
    super.initState();
    unawaited(_initFromFirestore());
  }

  Future<void> _initFromFirestore() async {
    try {
      await state.initializeFromFirestore();
    } catch (_) {}
    await state.restoreSession();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      textTheme: ThemeData.light().textTheme,
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF2563EB), foregroundColor: Colors.white),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2563EB),
          side: const BorderSide(color: Color(0xFF2563EB)),
        ),
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: state.user == null
          ? LoginPage(
              onLogin: (u, p) async {
                if (!await state.login(u, p)) {
                  return false;
                }
                await state.saveSession();
                setState(() {});
                return true;
              },
            )
          : HomePage(
              state: state,
              onChanged: () => setState(() {}),
              onLogout: () {
                state.logout();
                setState(() {});
              },
            ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.state, required this.onChanged, required this.onLogout});
  final AppState state;
  final VoidCallback onChanged;
  final VoidCallback onLogout;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  int _lastUnreadNotifications = -1;
  int _lastUnreadMessages = -1;
  bool _changePasswordDialogOpen = false;

  Future<void> _showMandatoryPasswordDialog() async {
    if (_changePasswordDialogOpen || widget.state.user == null || !widget.state.user!.mustChangePassword) return;
    _changePasswordDialogOpen = true;
    final password = TextEditingController();
    final confirm = TextEditingController();
    String? error;
    var saving = false;

    while (mounted && widget.state.user != null && widget.state.user!.mustChangePassword) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setInnerState) => AlertDialog(
            title: const Text("Sifre Degistirme Zorunlu"),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Ilk giriste varsayilan sifrenizi degistirmeniz gerekiyor."),
                  const SizedBox(height: 12),
                  TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: "Yeni Sifre")),
                  const SizedBox(height: 8),
                  TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: "Yeni Sifre (Tekrar)")),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  if (saving) return;
                  if (password.text.trim().length < 6) {
                    setInnerState(() => error = "Sifre en az 6 karakter olmali.");
                    return;
                  }
                  if (password.text != confirm.text) {
                    setInnerState(() => error = "Sifreler eslesmiyor.");
                    return;
                  }
                  setInnerState(() {
                    error = null;
                    saving = true;
                  });
                  final ok = await widget.state.changeCurrentUserPassword(password.text.trim());
                  if (!ctx.mounted) return;
                  if (!ok) {
                    setInnerState(() {
                      saving = false;
                      error = "Sifre kaydedilemedi. Baglanti veya Firebase yetkisini kontrol edin.";
                    });
                    return;
                  }
                  Navigator.pop(ctx);
                  widget.onChanged();
                },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Kaydet"),
              ),
            ],
          ),
        ),
      );
    }

    _changePasswordDialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 960;
    if (widget.state.user?.mustChangePassword == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showMandatoryPasswordDialog());
    }
    final currentUser = widget.state.user!;
    final pages = [
      DashboardPage(state: widget.state, onChanged: widget.onChanged),
      StudentsPage(state: widget.state, onChanged: widget.onChanged),
      TeachersPage(state: widget.state, onChanged: widget.onChanged),
      MessagesPage(state: widget.state, onChanged: widget.onChanged),
    ];
    return StreamBuilder<List<AppNotification>>(
      stream: FirebaseNotificationService.notificationsForUser(currentUser.id),
      builder: (context, snapshot) {
        final fromFirebase = snapshot.data ?? const <AppNotification>[];
        final unreadNotifications = fromFirebase.where((n) => !n.isRead).length;
        if (_lastUnreadNotifications != -1 && unreadNotifications > _lastUnreadNotifications) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yeni davranis bildirimi var")));
          });
        }
        _lastUnreadNotifications = unreadNotifications;

        return StreamBuilder<List<MessageItem>>(
          stream: FirestoreDataService.messagesForRecipient(currentUser.id),
          builder: (context, messageSnapshot) {
            final remoteIncoming = messageSnapshot.data ?? const <MessageItem>[];
            final unreadMessages = remoteIncoming.where((m) => !m.isRead).length;
            if (_lastUnreadMessages != -1 && unreadMessages > _lastUnreadMessages) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yeni mesajiniz var")));
              });
            }
            _lastUnreadMessages = unreadMessages;

            return Scaffold(
              appBar: mobile ? AppBar(title: Text(["Ana Sayfa", "Ogrenciler", "Ogretmenler", "Mesajlar"][tab])) : null,
              drawer: mobile
                  ? Drawer(
                      child: _Menu(
                        tab: tab,
                        unreadMessages: unreadMessages,
                        onTap: (i) => setState(() => tab = i),
                        onOpenProfile: () async {
                          Navigator.pop(context);
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => MyProfilePage(state: widget.state)));
                          widget.onChanged();
                        },
                        onLogout: widget.onLogout,
                        user: currentUser,
                      ),
                    )
                  : null,
              body: Row(
                children: [
                  if (!mobile)
                    SizedBox(
                      width: 280,
                      child: _Menu(
                        tab: tab,
                        unreadMessages: unreadMessages,
                        onTap: (i) => setState(() => tab = i),
                        onOpenProfile: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => MyProfilePage(state: widget.state)));
                          widget.onChanged();
                        },
                        onLogout: widget.onLogout,
                        user: currentUser,
                      ),
                    ),
                  Expanded(child: pages[tab]),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.tab, required this.unreadMessages, required this.onTap, required this.onOpenProfile, required this.onLogout, required this.user});
  final int tab;
  final int unreadMessages;
  final AppUser user;
  final void Function(int) onTap;
  final VoidCallback onOpenProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final items = const [("Ana Sayfa", Icons.dashboard), ("Ogrenciler", Icons.school), ("Ogretmenler", Icons.group), ("Mesajlar", Icons.chat)];
    return Container(
      color: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Ogrenci Davranis Takip Sistemi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                const Text("Davranis Yonetimi", style: TextStyle(color: Color(0xFF94A3B8))),
              ]),
            ),
            ...List.generate(items.length, (i) {
              final active = i == tab;
              return ListTile(
                leading: Icon(items[i].$2, color: active ? Colors.white : const Color(0xFF94A3B8)),
                tileColor: active ? const Color(0xFF3B82F6) : null,
                title: Row(
                  children: [
                    Expanded(child: Text(items[i].$1, style: TextStyle(color: active ? Colors.white : const Color(0xFFCBD5E1), fontWeight: FontWeight.w700))),
                    if (i == 3 && unreadMessages > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                        child: Text(unreadMessages.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                  ],
                ),
                onTap: () => onTap(i),
              );
            }),
            const Spacer(),
            ListTile(
              onTap: onOpenProfile,
              leading: CircleAvatar(child: Text(user.fullName.substring(0, 1))),
              title: Text(user.fullName, style: const TextStyle(color: Colors.white)),
              subtitle: Text(roleText(user.role), style: const TextStyle(color: Color(0xFF94A3B8))),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text("Cikis Yap"),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44), foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.state, required this.onChanged});
  final AppState state;
  final VoidCallback onChanged;

  Future<void> _showNotifications(BuildContext context, List<AppNotification> notifications) async {
    final currentUserId = state.user!.id;
    final studentsById = {for (final s in state.students) s.id: s};
    final teachersById = {for (final t in state.users) t.id: t};
    // Bildirim listesi acildiginda okunduya cekerek rozet sayacini temizle.
    await FirebaseNotificationService.markAllReadForUser(currentUserId);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Bildirimler"),
        content: SizedBox(
          width: 460,
          child: notifications.isEmpty
              ? const Text("Henuz bildirim yok")
              : ListView(
                  shrinkWrap: true,
                  children: notifications.take(30).map((n) {
                    return ListTile(
                      title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w800)),
                      subtitle: Text(n.message),
                      trailing: Text(DateFormat("dd/MM HH:mm").format(n.time)),
                      onTap: () async {
                        if (n.remoteId != null) {
                          await FirebaseNotificationService.markRead(n.remoteId!);
                        }
                        if (n.behaviorId != null) {
                          Behavior? behavior;
                          for (final b in state.behaviors) {
                            if (b.id == n.behaviorId) {
                              behavior = b;
                              break;
                            }
                          }
                          final student = behavior == null ? null : studentsById[behavior.studentId];
                          if (behavior != null && student != null && dialogContext.mounted) {
                            await _showBehaviorDetail(dialogContext, behavior, student, teachersById[behavior.teacherId]);
                          }
                        }
                      },
                    );
                  }).toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseNotificationService.markAllReadForUser(currentUserId);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text("Tumunu Okundu Yap"),
          ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Kapat")),
        ],
      ),
    );
  }

  Future<void> _showBehaviorDetail(BuildContext context, Behavior b, Student student, AppUser? teacher) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Kayit Detayi"),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Ogrenci: ${student.fullName}", style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text("Ogretmen: ${teacher?.fullName ?? "-"}"),
              Text("Tip: ${b.type == "positive" ? "Olumlu" : "Olumsuz"}"),
              Text("Kategori: ${b.category}"),
              const SizedBox(height: 6),
              Text("Aciklama: ${b.description.isEmpty ? "-" : b.description}"),
              const SizedBox(height: 8),
              Text("Tarih: ${DateFormat("dd/MM/yyyy HH:mm").format(b.date)}"),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = state.stats();
    final activeStudentsById = {for (final st in state.students.where((s) => s.status == "active")) st.id: st};
    final teachersById = {for (final t in state.users) t.id: t};
    final activeBehaviors = state.behaviors.where((b) => activeStudentsById.containsKey(b.studentId)).toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Header(title: "Ogrenci Davranis Takip Sistemi", subtitle: "Hos geldiniz, ${state.user!.fullName}"),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: [
            Stat("Toplam", s.$1.toString(), const Color(0xFF1D4ED8)),
            Stat("Pozitif", s.$2.toString(), const Color(0xFF16A34A)),
            Stat("Negatif", s.$3.toString(), const Color(0xFFDC2626)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Text("Son Etkinlikler", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const Spacer(),
            StreamBuilder<List<AppNotification>>(
              stream: FirebaseNotificationService.notificationsForUser(state.user!.id),
              builder: (context, snapshot) {
                final notifications = snapshot.data ?? const <AppNotification>[];
                final unread = notifications.where((n) => !n.isRead).length;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: "Bildirimler",
                      onPressed: () async => _showNotifications(context, notifications),
                      icon: const Icon(Icons.notifications),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                          child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                );
              },
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await showDialog<void>(context: context, builder: (_) => BehaviorDialog(state: state));
                onChanged();
              },
              icon: const Icon(Icons.add),
              label: const Text("Davranis Ekle"),
            ),
          ]),
          const SizedBox(height: 8),
          ...activeBehaviors.take(6).map((b) {
            final student = activeStudentsById[b.studentId];
            if (student == null) return const SizedBox.shrink();
            final teacher = teachersById[b.teacherId];
            return Card(
              child: ListTile(
                onTap: () async => _showBehaviorDetail(context, b, student, teacher),
                title: Text(student.fullName),
                subtitle: Text("${b.category} - ${b.description}\nOgretmen: ${teacher?.fullName ?? "-"}"),
                leading: Icon(b.type == "positive" ? Icons.check_circle : Icons.warning_amber_rounded, color: b.type == "positive" ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                isThreeLine: true,
                trailing: Text(DateFormat("dd MMM HH:mm").format(b.date)),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key, required this.state, required this.onChanged});
  final AppState state;
  final VoidCallback onChanged;
  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  String q = "";
  bool showArchived = false;
  String classFilter = "Tum Siniflar";
  @override
  Widget build(BuildContext context) {
    final classList = widget.state.students.map((s) => s.className).toSet().toList()..sort();
    final classItems = ["Tum Siniflar", ...classList];
    if (!classItems.contains(classFilter)) {
      classFilter = "Tum Siniflar";
    }
    final list = widget.state.students
        .where((s) => showArchived ? s.status == "archived" : s.status == "active")
        .where((s) => classFilter == "Tum Siniflar" || s.className == classFilter)
        .where((s) => s.fullName.toLowerCase().contains(q.toLowerCase()) || s.studentNumber.contains(q) || s.className.toLowerCase().contains(q.toLowerCase()))
        .toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Header(
            title: "Ogrenciler",
            subtitle: "Ogrenci profillerini ve davranis kayitlarini yonetin",
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(() => showArchived = !showArchived),
                  icon: Icon(showArchived ? Icons.visibility : Icons.archive),
                  label: Text(showArchived ? "Aktifleri Goster" : "Arsivdekiler"),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await showDialog<void>(context: context, builder: (_) => StudentDialog(state: widget.state));
                    widget.onChanged();
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text("Ogrenci Ekle"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: "Ara"), onChanged: (v) => setState(() => q = v)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: classFilter,
                  items: classItems.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => classFilter = v ?? "Tum Siniflar"),
                  decoration: const InputDecoration(labelText: "Sinif Filtresi"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 280, childAspectRatio: 1.28, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemBuilder: (_, i) {
                final s = list[i];
                return InkWell(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetail(state: widget.state, studentId: s.id)));
                    widget.onChanged();
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(
                          children: [
                            CircleAvatar(child: Text(s.fullName.substring(0, 1))),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: s.status == "archived" ? Colors.amber.shade100 : Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
                              child: Text(s.status == "archived" ? "Arsivde" : "Aktif", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(s.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        Text("No: ${s.studentNumber}"),
                        Text("Sinif: ${s.className}"),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key, required this.state, required this.onChanged});
  final AppState state;
  final VoidCallback onChanged;
  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  bool showArchived = false;

  @override
  Widget build(BuildContext context) {
    final list = widget.state.users.where((u) => showArchived ? u.status == "archived" : u.status == "active").toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Header(
            title: "Ogretmenler",
            subtitle: "Okul personelini ve rollerini yonetin",
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(() => showArchived = !showArchived),
                  icon: Icon(showArchived ? Icons.visibility : Icons.archive),
                  label: Text(showArchived ? "Aktifleri Goster" : "Arsivdekiler"),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await showDialog<void>(context: context, builder: (_) => TeacherDialog(state: widget.state));
                    widget.onChanged();
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text("Ogretmen Ekle"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: list
                  .map(
                    (u) => Card(
                      child: ListTile(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherDetail(state: widget.state, teacherId: u.id)));
                          widget.onChanged();
                        },
                        leading: CircleAvatar(
                          backgroundImage: (u.avatarUrl != null && u.avatarUrl!.isNotEmpty) ? NetworkImage(u.avatarUrl!) : null,
                          child: (u.avatarUrl == null || u.avatarUrl!.isEmpty) ? Text(u.fullName.substring(0, 1)) : null,
                        ),
                        title: Text(u.fullName),
                        subtitle: Text("${u.branch ?? "-"} - ${u.email}"),
                        trailing: Text(u.status == "archived" ? "Arsivde" : (u.classTeacherOf ?? "-")),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key, required this.state, required this.onChanged});
  final AppState state;
  final VoidCallback onChanged;
  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  AppUser? selected;
  final c = TextEditingController();

  void _mergeRemoteIncoming(List<MessageItem> remoteIncoming) {
    for (final remote in remoteIncoming) {
      final idx = widget.state.messages.indexWhere((m) => m.id == remote.id);
      if (idx == -1) {
        widget.state.messages.add(remote);
      } else if (widget.state.messages[idx].isRead != remote.isRead) {
        final current = widget.state.messages[idx];
        widget.state.messages[idx] = MessageItem(current.id, current.senderId, current.recipientId, current.content, current.time, isRead: remote.isRead);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = widget.state.users.where((u) => u.id != widget.state.user!.id && u.status == "active").toList();
    selected ??= contacts.isNotEmpty ? contacts.first : null;
    final currentUserId = widget.state.user!.id;
    String userNameById(int id) {
      for (final u in widget.state.users) {
        if (u.id == id) return u.fullName;
      }
      return "-";
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 280,
            child: Card(
              child: ListView(
                children: contacts.map((u) {
                  final unreadFromThisContact = widget.state.messages.where((m) => m.recipientId == currentUserId && m.senderId == u.id && !m.isRead).length;
                  return ListTile(
                    selected: selected?.id == u.id,
                    onTap: () {
                      setState(() => selected = u);
                      widget.state.markChatRead(u.id);
                      widget.onChanged();
                    },
                    leading: CircleAvatar(child: Text(u.fullName.substring(0, 1))),
                    title: Text(u.fullName),
                    subtitle: Text(roleText(u.role)),
                    trailing: unreadFromThisContact > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                            child: Text(unreadFromThisContact.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          )
                        : null,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StreamBuilder<List<MessageItem>>(
              stream: FirestoreDataService.messagesForRecipient(currentUserId),
              builder: (context, snapshot) {
                final remoteIncoming = snapshot.data ?? const <MessageItem>[];
                _mergeRemoteIncoming(remoteIncoming);
                final chat = selected == null ? <MessageItem>[] : widget.state.chat(selected!.id);
                final incoming = widget.state.messages.where((m) => m.recipientId == currentUserId).toList()..sort((a, b) => b.time.compareTo(a.time));
                final outgoing = widget.state.messages.where((m) => m.senderId == currentUserId).toList()..sort((a, b) => b.time.compareTo(a.time));

                if (selected != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    widget.state.markChatRead(selected!.id);
                    widget.onChanged();
                  });
                }

                return DefaultTabController(
                  length: 3,
                  child: Card(
                    child: Column(
                      children: [
                        const TabBar(tabs: [Tab(text: "Sohbet"), Tab(text: "Gelen"), Tab(text: "Gonderilen")]),
                        Expanded(
                          child: TabBarView(
                            children: [
                              Column(
                                children: [
                                  ListTile(title: Text(selected?.fullName ?? "Kisi Yok")),
                                  const Divider(height: 1),
                                  Expanded(
                                    child: ListView(
                                      padding: const EdgeInsets.all(10),
                                      children: chat
                                          .map((m) => Align(
                                                alignment: m.senderId == widget.state.user!.id ? Alignment.centerRight : Alignment.centerLeft,
                                                child: Container(
                                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(color: m.senderId == widget.state.user!.id ? const Color(0xFF2563EB) : Colors.white, borderRadius: BorderRadius.circular(12)),
                                                  child: Text("${m.content}\n${DateFormat("HH:mm").format(m.time)}", style: TextStyle(color: m.senderId == widget.state.user!.id ? Colors.white : Colors.black87)),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(children: [
                                      Expanded(child: TextField(controller: c, decoration: const InputDecoration(hintText: "Mesaj yaz"))),
                                      IconButton(
                                        onPressed: selected == null
                                            ? null
                                            : () {
                                                final t = c.text.trim();
                                                if (t.isEmpty) return;
                                                widget.state.send(selected!.id, t);
                                                c.clear();
                                                widget.onChanged();
                                                setState(() {});
                                              },
                                        icon: const Icon(Icons.send),
                                      ),
                                    ]),
                                  ),
                                ],
                              ),
                              ListView(
                                children: incoming.map((m) {
                                  return ListTile(
                                    title: Text(userNameById(m.senderId)),
                                    subtitle: Text("${m.content}\n${DateFormat("dd/MM HH:mm").format(m.time)}"),
                                    isThreeLine: true,
                                    trailing: IconButton(
                                      tooltip: "Sil",
                                      onPressed: () {
                                        widget.state.deleteMessage(m.id);
                                        widget.onChanged();
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.delete),
                                    ),
                                  );
                                }).toList(),
                              ),
                              ListView(
                                children: outgoing.map((m) {
                                  return ListTile(
                                    title: Text(userNameById(m.recipientId)),
                                    subtitle: Text("${m.content}\n${DateFormat("dd/MM HH:mm").format(m.time)}"),
                                    isThreeLine: true,
                                    trailing: IconButton(
                                      tooltip: "Sil",
                                      onPressed: () {
                                        widget.state.deleteMessage(m.id);
                                        widget.onChanged();
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.delete),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StudentDetail extends StatefulWidget {
  const StudentDetail({super.key, required this.state, required this.studentId});
  final AppState state;
  final int studentId;
  @override
  State<StudentDetail> createState() => _StudentDetailState();
}

class _StudentDetailState extends State<StudentDetail> {
  final ScrollController _detailScrollController = ScrollController();

  @override
  void dispose() {
    _detailScrollController.dispose();
    super.dispose();
  }

  Student? get student {
    for (final s in widget.state.students) {
      if (s.id == widget.studentId) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final current = student;
    if (current == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("Ogrenci bulunamadi")),
      );
    }

    final list = widget.state.behaviors.where((b) => b.studentId == current.id).toList()..sort((a, b) => b.date.compareTo(a.date));
    final positiveCount = list.where((b) => b.type == "positive").length;
    final negativeCount = list.where((b) => b.type == "negative").length;
    final categoryCounts = <String, int>{};
    for (final b in list) {
      categoryCounts[b.category] = (categoryCounts[b.category] ?? 0) + 1;
    }
    final categoryEntries = categoryCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Scaffold(
      appBar: AppBar(
        title: Text(current.fullName),
        actions: [
          IconButton(
            tooltip: "Duzenle",
            onPressed: () async {
              await showDialog<void>(context: context, builder: (_) => StudentEditDialog(state: widget.state, student: current));
              setState(() {});
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: current.status == "archived" ? "Arsivden Cikar" : "Arsivle",
            onPressed: () {
              widget.state.archiveStudent(current.id);
              setState(() {});
            },
            icon: Icon(current.status == "archived" ? Icons.unarchive : Icons.archive),
          ),
          IconButton(
            tooltip: "Sil",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text("Ogrenci Sil"),
                  content: const Text("Bu ogrenciyi silmek istiyor musun?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Iptal")),
                    ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Sil")),
                  ],
                ),
              );
              if (confirm == true) {
                widget.state.deleteStudent(current.id);
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Scrollbar(
          controller: _detailScrollController,
          thumbVisibility: true,
          child: ListView(
            controller: _detailScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundImage: (current.avatarUrl != null && current.avatarUrl!.isNotEmpty) ? NetworkImage(current.avatarUrl!) : null,
                      child: (current.avatarUrl == null || current.avatarUrl!.isEmpty)
                          ? Text(current.fullName.substring(0, 1), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800))
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(current.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    InfoRow("Ogrenci No", current.studentNumber),
                    InfoRow("Sinif", current.className),
                    InfoRow("Veli", current.parentName?.isNotEmpty == true ? current.parentName! : "-"),
                    InfoRow("Telefon", current.parentPhone?.isNotEmpty == true ? current.parentPhone! : "-"),
                    InfoRow("Durum", current.status == "archived" ? "Arsivde" : "Aktif"),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            await showDialog<void>(context: context, builder: (_) => StudentEditDialog(state: widget.state, student: current));
                            setState(() {});
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text("Duzenle"),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            widget.state.archiveStudent(current.id);
                            setState(() {});
                          },
                          icon: Icon(current.status == "archived" ? Icons.unarchive : Icons.archive),
                          label: Text(current.status == "archived" ? "Arsivden Cikar" : "Arsivle"),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text("Ogrenci Sil"),
                                content: const Text("Bu ogrenciyi silmek istiyor musun?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Iptal")),
                                  ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Sil")),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              widget.state.deleteStudent(current.id);
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text("Sil"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text("Toplam: ${list.length}"), avatar: const Icon(Icons.summarize, size: 18)),
                    Chip(label: Text("Olumlu: $positiveCount"), avatar: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18)),
                    Chip(label: Text("Olumsuz: $negativeCount"), avatar: const Icon(Icons.warning, color: Color(0xFFDC2626), size: 18)),
                  ],
                ),
              ),
            ),
            if (categoryEntries.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Davranis Turleri ve Asamalari", style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categoryEntries.map((entry) => Chip(label: Text("${entry.key}: ${entry.value}. Asama"))).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text("Davranis Kayitlari", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (list.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Kayit yok"),
                ),
              ),
            ...list.map(
              (b) => Card(
                child: ListTile(
                  title: Text(b.category),
                  subtitle: Text("${b.description}\n${DateFormat("dd/MM HH:mm").format(b.date)}"),
                  leading: Icon(b.type == "positive" ? Icons.check_circle : Icons.warning, color: b.type == "positive" ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeacherDetail extends StatefulWidget {
  const TeacherDetail({super.key, required this.state, required this.teacherId});
  final AppState state;
  final int teacherId;
  @override
  State<TeacherDetail> createState() => _TeacherDetailState();
}

class _TeacherDetailState extends State<TeacherDetail> {
  AppUser? get teacher {
    for (final t in widget.state.users) {
      if (t.id == widget.teacherId) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final current = teacher;
    if (current == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("Ogretmen bulunamadi")),
      );
    }

    final relatedBehaviorStudents = widget.state.behaviors.where((b) => b.teacherId == current.id).map((e) => e.studentId).toSet();
    final relatedStudents = widget.state.students.where((s) => relatedBehaviorStudents.contains(s.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(current.fullName),
        actions: [
          IconButton(
            tooltip: "Duzenle",
            onPressed: () async {
              await showDialog<void>(context: context, builder: (_) => TeacherEditDialog(state: widget.state, teacher: current));
              setState(() {});
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: current.status == "archived" ? "Arsivden Cikar" : "Arsivle",
            onPressed: () {
              widget.state.archiveTeacher(current.id);
              setState(() {});
            },
            icon: Icon(current.status == "archived" ? Icons.unarchive : Icons.archive),
          ),
          IconButton(
            tooltip: "Sil",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text("Ogretmen Sil"),
                  content: const Text("Bu ogretmeni silmek istiyor musun?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Iptal")),
                    ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Sil")),
                  ],
                ),
              );
              if (confirm == true) {
                widget.state.deleteTeacher(current.id);
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundImage: (current.avatarUrl != null && current.avatarUrl!.isNotEmpty) ? NetworkImage(current.avatarUrl!) : null,
                      child: (current.avatarUrl == null || current.avatarUrl!.isEmpty)
                          ? Text(current.fullName.substring(0, 1), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800))
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(current.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    InfoRow("Kullanici Adi", current.username),
                    InfoRow("Rol", roleText(current.role)),
                    InfoRow("E-posta", current.email),
                    InfoRow("Brans", current.branch?.isNotEmpty == true ? current.branch! : "-"),
                    InfoRow("Sinif Rehberligi", current.classTeacherOf?.isNotEmpty == true ? current.classTeacherOf! : "-"),
                    InfoRow("Durum", current.status == "archived" ? "Arsivde" : "Aktif"),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            await showDialog<void>(context: context, builder: (_) => TeacherEditDialog(state: widget.state, teacher: current));
                            setState(() {});
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text("Duzenle"),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            widget.state.archiveTeacher(current.id);
                            setState(() {});
                          },
                          icon: Icon(current.status == "archived" ? Icons.unarchive : Icons.archive),
                          label: Text(current.status == "archived" ? "Arsivden Cikar" : "Arsivle"),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text("Ogretmen Sil"),
                                content: const Text("Bu ogretmeni silmek istiyor musun?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Iptal")),
                                  ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Sil")),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              widget.state.deleteTeacher(current.id);
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text("Sil"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text("Kayit Girdigi Ogrenciler", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (relatedStudents.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Kayit yok"),
                ),
              ),
            ...relatedStudents.map(
              (s) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (s.avatarUrl != null && s.avatarUrl!.isNotEmpty) ? NetworkImage(s.avatarUrl!) : null,
                    child: (s.avatarUrl == null || s.avatarUrl!.isEmpty) ? Text(s.fullName.substring(0, 1)) : null,
                  ),
                  title: Text(s.fullName),
                  subtitle: Text("No: ${s.studentNumber} - Sinif: ${s.className}"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key, required this.state});
  final AppState state;

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  AppUser? get me => widget.state.user;

  Widget _behaviorCard(Behavior b) {
    Student? student;
    AppUser? teacher;
    for (final s in widget.state.students) {
      if (s.id == b.studentId) {
        student = s;
        break;
      }
    }
    for (final t in widget.state.users) {
      if (t.id == b.teacherId) {
        teacher = t;
        break;
      }
    }
    return Card(
      child: ListTile(
        title: Text(student?.fullName ?? "Ogrenci silinmis"),
        subtitle: Text("${b.category} (${b.type == "positive" ? "Olumlu" : "Olumsuz"})\nOgretmen: ${teacher?.fullName ?? "-"}\n${b.description}\n${DateFormat("dd/MM HH:mm").format(b.date)}"),
        isThreeLine: true,
        trailing: SizedBox(
          width: 86,
          child: Row(
            children: [
              IconButton(
                tooltip: "Duzenle",
                onPressed: () async {
                  await showDialog<void>(context: context, builder: (_) => BehaviorEditDialog(state: widget.state, behavior: b));
                  setState(() {});
                },
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                tooltip: "Sil",
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text("Kaydi Sil"),
                      content: const Text("Bu davranis kaydini silmek istiyor musun?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Iptal")),
                        ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Sil")),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    widget.state.deleteBehavior(b.id);
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.delete),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = me;
    if (current == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text("Kullanici bulunamadi")));
    }

    final myBehaviors = widget.state.behaviors.where((b) => b.teacherId == current.id).toList()..sort((a, b) => b.date.compareTo(a.date));
    final branchBehaviors = widget.state.behaviors
        .where((b) {
          final teacher = widget.state.users.where((u) => u.id == b.teacherId).toList();
          if (teacher.isEmpty) return false;
          return teacher.first.branch == current.branch;
        })
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: const Text("Kendi Profilim")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundImage: (current.avatarUrl != null && current.avatarUrl!.isNotEmpty) ? NetworkImage(current.avatarUrl!) : null,
                        child: (current.avatarUrl == null || current.avatarUrl!.isEmpty)
                            ? Text(current.fullName.substring(0, 1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700))
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(current.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      InfoRow("Kullanici Adi", current.username),
                      InfoRow("E-posta", current.email),
                      InfoRow("Brans", current.branch?.isNotEmpty == true ? current.branch! : "-"),
                      InfoRow("Rol", roleText(current.role)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const TabBar(tabs: [Tab(text: "Girdigim Kayitlar"), Tab(text: "Brans Kayitlari")]),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView(
                      children: [
                        if (myBehaviors.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text("Henuz kayit yok"),
                            ),
                          ),
                        ...myBehaviors.map(_behaviorCard),
                      ],
                    ),
                    ListView(
                      children: [
                        if (current.branch == null || current.branch!.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text("Brans bilgisi bulunamadigi icin kayit listelenemiyor."),
                            ),
                          )
                        else if (branchBehaviors.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text("Bransiniza ait kayit bulunamadi."),
                            ),
                          )
                        else
                          ...branchBehaviors.map(_behaviorCard),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BehaviorEditDialog extends StatefulWidget {
  const BehaviorEditDialog({super.key, required this.state, required this.behavior});
  final AppState state;
  final Behavior behavior;

  @override
  State<BehaviorEditDialog> createState() => _BehaviorEditDialogState();
}

class _BehaviorEditDialogState extends State<BehaviorEditDialog> {
  late String type;
  late final TextEditingController category;
  late final TextEditingController description;

  @override
  void initState() {
    super.initState();
    type = widget.behavior.type;
    category = TextEditingController(text: widget.behavior.category);
    description = TextEditingController(text: widget.behavior.description);
  }

  @override
  void dispose() {
    category.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Davranis Kaydi Duzenle"),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: type,
              items: const [DropdownMenuItem(value: "positive", child: Text("Olumlu")), DropdownMenuItem(value: "negative", child: Text("Olumsuz"))],
              onChanged: (v) => setState(() => type = v ?? "negative"),
              decoration: const InputDecoration(labelText: "Davranis Tipi"),
            ),
            TextField(controller: category, decoration: const InputDecoration(labelText: "Kategori")),
            TextField(controller: description, decoration: const InputDecoration(labelText: "Aciklama")),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Iptal")),
        ElevatedButton(
          onPressed: () {
            widget.state.updateBehavior(
              widget.behavior.id,
              type: type,
              category: category.text.trim(),
              description: description.text.trim(),
            );
            Navigator.pop(context);
          },
          child: const Text("Kaydet"),
        ),
      ],
    );
  }
}

class StudentDialog extends StatelessWidget {
  const StudentDialog({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    final n = TextEditingController();
    final no = TextEditingController();
    final c = TextEditingController();
    final pName = TextEditingController();
    final pPhone = TextEditingController();
    final avatar = TextEditingController();
    return AlertDialog(
      title: const Text("Ogrenci Ekle"),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: n, decoration: const InputDecoration(labelText: "Ad Soyad")),
          TextField(controller: no, decoration: const InputDecoration(labelText: "Ogrenci Numarasi")),
          TextField(controller: c, decoration: const InputDecoration(labelText: "Sinif")),
          TextField(controller: pName, decoration: const InputDecoration(labelText: "Veli Adi")),
          TextField(controller: pPhone, decoration: const InputDecoration(labelText: "Veli Telefonu")),
          TextField(controller: avatar, decoration: const InputDecoration(labelText: "Profil Gorseli URL")),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Iptal")),
        ElevatedButton(
          onPressed: () {
            state.addStudent(
              n.text,
              no.text,
              c.text,
              parentName: pName.text,
              parentPhone: pPhone.text,
              avatarUrl: avatar.text,
            );
            Navigator.pop(context);
          },
          child: const Text("Kaydet"),
        ),
      ],
    );
  }
}

class StudentEditDialog extends StatelessWidget {
  const StudentEditDialog({super.key, required this.state, required this.student});
  final AppState state;
  final Student student;

  @override
  Widget build(BuildContext context) {
    final n = TextEditingController(text: student.fullName);
    final no = TextEditingController(text: student.studentNumber);
    final c = TextEditingController(text: student.className);
    final pName = TextEditingController(text: student.parentName ?? "");
    final pPhone = TextEditingController(text: student.parentPhone ?? "");
    final avatar = TextEditingController(text: student.avatarUrl ?? "");

    return AlertDialog(
      title: const Text("Ogrenci Duzenle"),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: n, decoration: const InputDecoration(labelText: "Ad Soyad")),
          TextField(controller: no, decoration: const InputDecoration(labelText: "Ogrenci Numarasi")),
          TextField(controller: c, decoration: const InputDecoration(labelText: "Sinif")),
          TextField(controller: pName, decoration: const InputDecoration(labelText: "Veli Adi")),
          TextField(controller: pPhone, decoration: const InputDecoration(labelText: "Veli Telefonu")),
          TextField(controller: avatar, decoration: const InputDecoration(labelText: "Profil Gorseli URL")),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Iptal")),
        ElevatedButton(
          onPressed: () {
            state.updateStudent(
              student.id,
              fullName: n.text,
              studentNumber: no.text,
              className: c.text,
              parentName: pName.text,
              parentPhone: pPhone.text,
              avatarUrl: avatar.text,
            );
            Navigator.pop(context);
          },
          child: const Text("Kaydet"),
        ),
      ],
    );
  }
}

class TeacherDialog extends StatelessWidget {
  const TeacherDialog({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final fullName = TextEditingController();
    final email = TextEditingController();
    final branch = TextEditingController();
    final classTeacherOf = TextEditingController();
    final avatar = TextEditingController();

    return AlertDialog(
      title: const Text("Ogretmen Ekle"),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: fullName, decoration: const InputDecoration(labelText: "Ad Soyad")),
          TextField(controller: email, decoration: const InputDecoration(labelText: "E-posta")),
          const SizedBox(height: 6),
          const Text("Kullanici adi e-posta @ oncesi, ilk sifre P123456 olarak otomatik olusturulur.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          TextField(controller: branch, decoration: const InputDecoration(labelText: "Brans")),
          TextField(controller: classTeacherOf, decoration: const InputDecoration(labelText: "Rehberlik Ettigi Sinif")),
          TextField(controller: avatar, decoration: const InputDecoration(labelText: "Profil Gorseli URL")),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Iptal")),
        ElevatedButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final ok = await state.addTeacher(
              fullName: fullName.text,
              email: email.text,
              branch: branch.text,
              classTeacherOf: classTeacherOf.text,
              avatarUrl: avatar.text,
            );
            if (!context.mounted) return;
            if (!ok) {
              messenger.showSnackBar(const SnackBar(content: Text("Ogretmen kaydedilemedi. Firebase yazma yetkisini kontrol edin.")));
              return;
            }
            navigator.pop();
          },
          child: const Text("Kaydet"),
        ),
      ],
    );
  }
}

class TeacherEditDialog extends StatelessWidget {
  const TeacherEditDialog({super.key, required this.state, required this.teacher});
  final AppState state;
  final AppUser teacher;

  @override
  Widget build(BuildContext context) {
    final fullName = TextEditingController(text: teacher.fullName);
    final email = TextEditingController(text: teacher.email);
    final branch = TextEditingController(text: teacher.branch ?? "");
    final classTeacherOf = TextEditingController(text: teacher.classTeacherOf ?? "");
    final avatar = TextEditingController(text: teacher.avatarUrl ?? "");

    return AlertDialog(
      title: const Text("Ogretmen Duzenle"),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: fullName, decoration: const InputDecoration(labelText: "Ad Soyad")),
          TextField(controller: email, decoration: const InputDecoration(labelText: "E-posta")),
          TextField(controller: branch, decoration: const InputDecoration(labelText: "Brans")),
          const SizedBox(height: 6),
          const Text("Kullanici adi e-posta @ oncesine gore otomatik guncellenir.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          TextField(controller: classTeacherOf, decoration: const InputDecoration(labelText: "Rehberlik Ettigi Sinif")),
          TextField(controller: avatar, decoration: const InputDecoration(labelText: "Profil Gorseli URL")),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Iptal")),
        ElevatedButton(
          onPressed: () {
            state.updateTeacher(
              teacher.id,
              fullName: fullName.text,
              email: email.text,
              branch: branch.text,
              classTeacherOf: classTeacherOf.text,
              avatarUrl: avatar.text,
            );
            Navigator.pop(context);
          },
          child: const Text("Kaydet"),
        ),
      ],
    );
  }
}

class BehaviorDialog extends StatefulWidget {
  const BehaviorDialog({super.key, required this.state});
  final AppState state;
  @override
  State<BehaviorDialog> createState() => _BehaviorDialogState();
}

class _BehaviorDialogState extends State<BehaviorDialog> {
  String? selectedClass;
  int? studentId;
  String type = "negative";
  String category = "Telefon Teslim Etmeme";
  bool customCategory = false;
  String customCategoryValue = "";
  bool notifySpecificTeacher = false;
  int? notifyTeacherId;
  static const behaviorCategories = [
    "Telefon Teslim Etmeme",
    "Ders Akisini Bozma",
    "Derse Gec Kalma",
    "Arkadasiyla Alay Etme",
    "Istenmeyen Saka",
    "Kotu Soz Kullanimi",
    "Kavga",
    "Okul Esyasina Zarar Verme",
    "Lakap Takma",
    "Dislama",
    "Ogretmen Yonergesine Uymama",
    "Farkli Kiyafet ile Gelme",
    "Diger [Ekle]",
  ];
  final cat = TextEditingController();
  final desc = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final activeStudents = widget.state.students.where((s) => s.status == "active").toList();
    final activeTeachers = widget.state.users.where((u) => u.role == "teacher" && u.status == "active" && u.id != widget.state.user!.id).toList();
    final classes = activeStudents.map((s) => s.className).toSet().toList()..sort();
    if (activeStudents.isEmpty) {
      return AlertDialog(
        title: const Text("Davranis Kaydi"),
        content: const Text("Aktif ogrenci olmadigi icin davranis eklenemiyor."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tamam"))],
      );
    }
    selectedClass ??= classes.first;
    if (!classes.contains(selectedClass)) {
      selectedClass = classes.first;
    }
    final studentsInClass = activeStudents.where((s) => s.className == selectedClass).toList();
    studentId ??= studentsInClass.first.id;
    if (!studentsInClass.any((s) => s.id == studentId)) {
      studentId = studentsInClass.first.id;
    }
    if (notifySpecificTeacher) {
      if (activeTeachers.isEmpty) {
        notifySpecificTeacher = false;
        notifyTeacherId = null;
      } else {
        notifyTeacherId ??= activeTeachers.first.id;
        if (!activeTeachers.any((t) => t.id == notifyTeacherId)) {
          notifyTeacherId = activeTeachers.first.id;
        }
      }
    }
    return AlertDialog(
      title: const Text("Davranis Kaydi"),
      content: SizedBox(
        width: 380,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            initialValue: selectedClass,
            items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() {
              selectedClass = v;
              final updated = activeStudents.where((s) => s.className == selectedClass).toList();
              studentId = updated.isEmpty ? null : updated.first.id;
            }),
            decoration: const InputDecoration(labelText: "Sinif"),
          ),
          DropdownButtonFormField<int>(
            initialValue: studentId,
            items: studentsInClass.map((s) => DropdownMenuItem(value: s.id, child: Text(s.fullName))).toList(),
            onChanged: (v) => setState(() => studentId = v),
            decoration: const InputDecoration(labelText: "Ogrenci"),
          ),
          DropdownButtonFormField<String>(
            initialValue: type,
            items: const [DropdownMenuItem(value: "positive", child: Text("Olumlu")), DropdownMenuItem(value: "negative", child: Text("Olumsuz"))],
            onChanged: (v) => setState(() => type = v ?? "negative"),
            decoration: const InputDecoration(labelText: "Davranis Tipi"),
          ),
          DropdownButtonFormField<String>(
            initialValue: category,
            items: behaviorCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() {
              category = v ?? behaviorCategories.first;
              customCategory = category == "Diger [Ekle]";
              if (!customCategory) {
                customCategoryValue = "";
                cat.clear();
              }
            }),
            decoration: const InputDecoration(labelText: "Davranis Kategorisi"),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: notifySpecificTeacher,
            onChanged: (v) => setState(() {
              notifySpecificTeacher = v;
              if (!notifySpecificTeacher) notifyTeacherId = null;
            }),
            title: const Text("Belirli ogretmene ayrica bilgi ver"),
          ),
          if (notifySpecificTeacher && activeTeachers.isNotEmpty)
            DropdownButtonFormField<int>(
              initialValue: notifyTeacherId,
              items: activeTeachers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.fullName))).toList(),
              onChanged: (v) => setState(() => notifyTeacherId = v),
              decoration: const InputDecoration(labelText: "Bilgilendirilecek Ogretmen"),
            ),
          if (customCategory)
            Row(
              children: [
                Expanded(child: TextField(controller: cat, decoration: const InputDecoration(labelText: "Kategori Ekle"))),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final value = cat.text.trim();
                    if (value.isEmpty) return;
                    setState(() => customCategoryValue = value);
                  },
                  child: const Text("Ekle"),
                ),
              ],
            ),
          TextField(controller: desc, decoration: const InputDecoration(labelText: "Aciklama")),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Iptal")),
        ElevatedButton(
          onPressed: () {
            final selectedCategory = customCategory ? customCategoryValue : category;
            widget.state.addBehavior(
              studentId!,
              type,
              selectedCategory,
              desc.text,
              notifyTeacherId: notifySpecificTeacher ? notifyTeacherId : null,
            );
            Navigator.pop(context);
          },
          child: const Text("Kaydet"),
        ),
      ],
    );
  }
}




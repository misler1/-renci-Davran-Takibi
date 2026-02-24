import "dart:async";

import "package:schooltrack_flutter/models/app_models.dart";
import "package:schooltrack_flutter/services/firebase_notification_service.dart";
import "package:schooltrack_flutter/services/firestore_data_service.dart";
import "package:shared_preferences/shared_preferences.dart";

class AppState {
  AppUser? user;
  final users = <AppUser>[
    AppUser(1, "hayrunnisa.kelpetin", "P123456", "HAYRUNNİSA KELPETİN", "teacher", "hayrunnisa.kelpetin@paletokullari.com", "5A", branch: "İNGİLİZCE", mustChangePassword: true),
    AppUser(2, "ebru.cimen", "P123456", "EBRU ÇİMEN", "teacher", "ebru.cimen@paletokullari.com", "5A", branch: "İNGİLİZCE", mustChangePassword: true),
    AppUser(3, "busra.eroglucoban", "P123456", "BÜŞRA EROĞLU ÇOBAN", "teacher", "busra.eroglucoban@paletokullari.com", "5A", branch: "FEN BİLİMLERİ", mustChangePassword: true),
    AppUser(4, "sehmus.saglamer", "P123456", "ŞEHMUS SAĞLAMER", "teacher", "sehmus.saglamer@paletokullari.com", "5A", branch: "SOSYAL BİLİMLER", mustChangePassword: true),
    AppUser(5, "sevgi.cengiz", "P123456", "SEVGİ CENGİZ", "teacher", "sevgi.cengiz@paletokullari.com", "5A", branch: "MATEMATİK", mustChangePassword: true),
    AppUser(6, "meryemozge.demir", "P123456", "MERYEM ÖZGE DEMİR", "teacher", "meryemozge.demir@paletokullari.com", "5A", branch: "VAR", mustChangePassword: true),
    AppUser(7, "sakir.saglam", "P123456", "ŞAKİR SAĞLAM", "teacher", "sakir.saglam@paletokullari.com", "5A", branch: "BEDEN EĞİTİMİ", mustChangePassword: true),
    AppUser(8, "turkay.ates", "P123456", "TÜRKAY ATEŞ", "teacher", "turkay.ates@paletokullari.com", "5A", branch: "MÜZİK", mustChangePassword: true),
    AppUser(9, "esra.engin", "P123456", "ESRA ENGİN", "teacher", "esra.engin@paletokullari.com", "5A", branch: "DİN KÜLTÜRÜ VE KURAN", mustChangePassword: true),
    AppUser(10, "ibrahimesad.ergen", "P123456", "İBRAHİM ESAD ERGEN", "teacher", "ibrahimesad.ergen@paletokullari.com", "5A", branch: "DİN KÜLTÜRÜ VE KURAN", mustChangePassword: true),
    AppUser(11, "musa.isler", "P123456", "MUSA İŞLER", "teacher", "musa.isler@paletokullari.com", "7A", branch: "REHBERLİK", mustChangePassword: true),
    AppUser(12, "admin", "P123456", "Okul Yonetimi", "admin", "admin@school.com", null),
    AppUser(13, "ebrarkevser.katirci", "P123456", "EBRAR KEVSER KATIRCI", "teacher", "ebrarkevser.katirci@paletokullari.com", null, branch: "PSİKOLOJİK DANIŞMAN", mustChangePassword: true),
    AppUser(14, "turgut.saglam", "P123456", "TURGUT SAĞLAM", "teacher", "turgut.saglam@paletokullari.com", null, branch: "MÜDÜR YARDIMCISI", mustChangePassword: true),
  ];
  final students = <Student>[
    Student(1, "1001", "ZEHRA BETÜL İSLAMOĞLU", "7A"),
    Student(2, "1002", "İNCİ HÜMA ALEMDAR", "7A"),
    Student(3, "1003", "AHMET İHSAN YANIK", "7A"),
    Student(4, "1004", "ESMA YAPAR", "7A"),
    Student(5, "1005", "MUSTAFA DEMİRCAN", "7A"),
    Student(6, "1006", "ERVA NUR GÜR", "7A"),
    Student(7, "1007", "HALİM KILIÇ", "7A"),
    Student(8, "1008", "YUSUF MUHSİN AYDIN", "7A"),
    Student(9, "1009", "MERYEM HENA TELLİOĞLU", "7A"),
    Student(10, "1010", "AHMET YUSUF TUNCEL", "7A"),
    Student(11, "1011", "ALİ KOÇ", "7A"),
    Student(12, "1012", "AİŞE HÜMEYRA KOCA", "7A"),
    Student(13, "1013", "ZEYNEP HÜMA ALTUN", "7A"),
    Student(14, "1014", "ALİ SALİH ŞÖNER", "7A"),
    Student(15, "1015", "ESMA HANNE CAN", "7A"),
    Student(16, "1016", "ABDULLAH ASAF ESEN", "7A"),
    Student(17, "1017", "AHMET SELİM SAYAN", "7A"),
    Student(18, "1018", "SHEHRBANO KAZMI", "7A"),
    Student(19, "1019", "ZÜLAL KOCAAĞA", "7A"),
    Student(20, "1020", "ZEYNEP LİNA BODUR", "7A"),
    Student(21, "1021", "NİSA TOPALOĞLU", "7B"),
    Student(22, "1022", "BERA ERGAN", "7B"),
    Student(23, "1023", "NAZENİN IŞIK", "7B"),
    Student(24, "1024", "ELİF SENA ÇAKIR", "7B"),
    Student(25, "1025", "ZEYNEP ADA IŞIK", "7B"),
    Student(26, "1026", "MEHMET FATİH TEKİN", "7B"),
    Student(27, "1027", "SELİM CANSU", "7B"),
    Student(28, "1028", "ALİ ÖNGÜN", "7B"),
    Student(29, "1029", "AYŞE AŞICI", "7B"),
    Student(30, "1030", "ÖMER YUSUF USTAOĞLU", "7B"),
    Student(31, "1031", "ZEHRA BESLİ", "7B"),
    Student(32, "1032", "EYMEN KAYA", "7B"),
    Student(33, "1033", "ZEYNEP MEVA İBİŞ", "7B"),
    Student(34, "1034", "CEMAL ENES DEMİRTAŞ", "7B"),
    Student(35, "1035", "HATİCE ZÜLAL SAĞIROĞLU", "7B"),
    Student(36, "1036", "TURAL ÇAĞLAR", "7B"),
    Student(37, "1037", "ESMA ŞEVVAL BAYRAK", "7B"),
    Student(38, "1038", "VEDAT ALP GÜNDOĞAN", "7B"),
    Student(39, "1039", "HANNE MUHACİR", "8A"),
    Student(40, "1040", "FATİMA AİŞE GÜDEN", "8A"),
    Student(41, "1041", "ERVA CEMİLE ONUR", "8A"),
    Student(42, "1042", "MUHAMMED FATİH KAYA", "8A"),
    Student(43, "1043", "MUHAMMED ÖMER ERGEN", "8A"),
    Student(44, "1044", "AYŞE İPEK POLAT", "8A"),
    Student(45, "1045", "FEYZA ECE UĞUR", "8A"),
    Student(46, "1046", "MUHAMMED ZEYD KILIÇ", "8A"),
    Student(47, "1047", "ZEYNEP IRMAK YALÇIN", "8A"),
    Student(48, "1048", "FATİH GÜNEY", "8A"),
    Student(49, "1049", "ELİF BEREN KARMİL", "8A"),
    Student(50, "1050", "KEREM AYGÜN", "8A"),
    Student(51, "1051", "TALYA SALAMEH", "8A"),
    Student(52, "1052", "MUSTAFA AĞDAŞ", "8A"),
    Student(53, "1053", "ELİF NAHİDE AVİNÇ", "8A"),
    Student(54, "1054", "İSMAİL AYGÜN", "8A"),
    Student(55, "1055", "AYŞE ZEHRA GÜNER", "8A"),
    Student(56, "1056", "BURAK KANDİŞ", "8A"),
    Student(57, "1057", "ÖMER BURAK BERBER", "8A"),
    Student(58, "1058", "EYÜP ENSAR YÜKSEL", "8A"),
    Student(59, "1059", "HALUK ERKAM TOPAL", "8A"),
    Student(60, "1060", "MUHAMMED ALİ DEMİR", "8B"),
    Student(61, "1061", "FATMA BETÜL ÇİZMECİOĞLU", "8B"),
    Student(62, "1062", "BEREN SARE SOFU", "8B"),
    Student(63, "1063", "NERİS NEVA KARADERE", "8B"),
    Student(64, "1064", "GÜL GÜNAYDIN", "8B"),
    Student(65, "1065", "İBRAHİM ENES YÜKSEL", "8B"),
    Student(66, "1066", "ELA OLÇOK", "8B"),
    Student(67, "1067", "ELİF KARAKAYA", "8B"),
    Student(68, "1068", "SERRA BÜYÜKEMİRUSTA", "8B"),
    Student(69, "1069", "FATIMA ZÜMRA DEMİRCAN", "8B"),
    Student(70, "1070", "FATİH EMİR KARACA", "8B"),
    Student(71, "1071", "SALİHA MERYEM TÜL", "8B"),
    Student(72, "1072", "KEREM PEKMEZCİ", "8B"),
    Student(73, "1073", "AYŞE ZÜLAL LİMAN", "8B"),
    Student(74, "1074", "ZEYNEP DEMİREL", "8B"),
    Student(75, "1075", "ARDA EYÜP AKGÜÇ", "8B"),
    Student(76, "1076", "TARIK ALİ BEYAZ", "8B"),
    Student(77, "1077", "AYŞE NESLİŞAH ZENGİN", "8B"),
  ];
  final behaviors = <Behavior>[
    Behavior(1, 1, 2, "negative", "Derse Gec Kalma", "10 dakika gec geldi", DateTime.now().subtract(const Duration(hours: 8))),
    Behavior(2, 1, 1, "positive", "Derse Katkida Bulunma", "Arkadasina yardim etti", DateTime.now().subtract(const Duration(hours: 2))),
  ];
  final messages = <MessageItem>[];
  final notifications = <AppNotification>[];

  static AppState seed() => AppState();
  Future<void> initializeFromFirestore() async {
    final canonicalUsersById = {for (final u in users) u.id: u};
    final canonicalUsersByUsername = {for (final u in users) u.username.toLowerCase(): u};
    final canonicalStudentsById = {for (final s in students) s.id: s};
    var all = await FirestoreDataService.loadAll();

    if (all.users.isEmpty) {
      // Firebase bos kurulumda acildiginda varsayilan kullanicilari bir kez yukle.
      await FirestoreDataService.syncUsers(users);
      all = await FirestoreDataService.loadAll();
      if (all.users.isEmpty) {
        throw StateError("Firebase users koleksiyonu bos veya okunamiyor.");
      }
    }

    if (all.students.isEmpty) {
      await FirestoreDataService.syncStudents(students);
      all = await FirestoreDataService.loadAll();
    }
    final normalizedUsers = <AppUser>[];
    for (final remoteUser in all.users) {
      final canonical = canonicalUsersById[remoteUser.id];
      normalizedUsers.add(
        AppUser(
          remoteUser.id,
          remoteUser.username,
          remoteUser.password,
          canonical?.fullName ?? remoteUser.fullName,
          remoteUser.role,
          remoteUser.email,
          remoteUser.classTeacherOf,
          branch: canonical?.branch ?? remoteUser.branch,
          status: remoteUser.status,
          mustChangePassword: remoteUser.mustChangePassword,
          avatarUrl: remoteUser.avatarUrl,
        ),
      );
    }
    var usersChanged = false;
    final existingByUsername = {for (final u in normalizedUsers) u.username.toLowerCase(): u};
    for (final entry in canonicalUsersByUsername.entries) {
      if (!existingByUsername.containsKey(entry.key)) {
        normalizedUsers.add(entry.value);
        usersChanged = true;
      }
    }
    normalizedUsers.sort((a, b) => a.id.compareTo(b.id));
    users
      ..clear()
      ..addAll(normalizedUsers);
    if (usersChanged) {
      unawaited(FirestoreDataService.syncUsers(users));
    }

    if (all.students.isNotEmpty) {
      final normalizedStudents = <Student>[];
      for (final remoteStudent in all.students) {
        final canonical = canonicalStudentsById[remoteStudent.id];
        normalizedStudents.add(
          Student(
            remoteStudent.id,
            remoteStudent.studentNumber,
            canonical?.fullName ?? remoteStudent.fullName,
            remoteStudent.className,
            parentName: remoteStudent.parentName,
            parentPhone: remoteStudent.parentPhone,
            avatarUrl: remoteStudent.avatarUrl,
            status: remoteStudent.status,
          ),
        );
      }
      normalizedStudents.sort((a, b) => a.id.compareTo(b.id));
      students
        ..clear()
        ..addAll(normalizedStudents);
    }
    behaviors
      ..clear()
      ..addAll(all.behaviors);
    messages
      ..clear()
      ..addAll(all.messages);
  }

  int _nextId(Iterable<int> ids) {
    if (ids.isEmpty) return 1;
    return ids.reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<bool> login(String username, String password) async {
    final input = username.trim().toLowerCase();
    if (input.isEmpty) return false;

    var remoteLookupSucceeded = false;
    AppUser? remoteUser;
    try {
      remoteUser = await FirestoreDataService.findUserByUsername(input);
      remoteLookupSucceeded = true;
    } catch (_) {}

    // Uzak kullanici bulunduysa yalnizca uzak kayda gore karar ver.
    // Boylece eski yerel sifreyle yanlis giris engellenir.
    if (remoteLookupSucceeded) {
      final remote = remoteUser;
      if (remote == null) return false;
      if (remote.password == password && remote.status == "active") {
        final index = users.indexWhere((u) => u.id == remote.id);
        if (index == -1) {
          users.add(remote);
        } else {
          users[index] = remote;
        }
        user = remote;
        return true;
      }
      return false;
    }

    final found = users.where((e) => e.username.toLowerCase() == input && e.password == password && e.status == "active");
    if (found.isEmpty) return false;
    user = found.first;
    return true;
  }

  void logout() {
    user = null;
    unawaited(clearSession());
  }
  (int, int, int) stats() => (
        behaviors.length,
        behaviors.where((e) => e.type == "positive").length,
        behaviors.where((e) => e.type == "negative").length,
      );
  void addStudent(
    String name,
    String number,
    String className, {
    String? parentName,
    String? parentPhone,
    String? avatarUrl,
  }) {
    if (name.trim().isEmpty || number.trim().isEmpty || className.trim().isEmpty) return;
    students.insert(
      0,
      Student(
        _nextId(students.map((s) => s.id)),
        number,
        name,
        className,
        parentName: parentName,
        parentPhone: parentPhone,
        avatarUrl: avatarUrl,
      ),
    );
    unawaited(FirestoreDataService.syncStudents(students));
  }

  void updateStudent(
    int id, {
    required String fullName,
    required String studentNumber,
    required String className,
    String? parentName,
    String? parentPhone,
    String? avatarUrl,
  }) {
    final index = students.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final current = students[index];
    students[index] = Student(
      current.id,
      studentNumber,
      fullName,
      className,
      parentName: parentName,
      parentPhone: parentPhone,
      avatarUrl: avatarUrl,
      status: current.status,
    );
    unawaited(FirestoreDataService.syncStudents(students));
  }

  void archiveStudent(int id) {
    final index = students.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final current = students[index];
    students[index] = Student(
      current.id,
      current.studentNumber,
      current.fullName,
      current.className,
      parentName: current.parentName,
      parentPhone: current.parentPhone,
      avatarUrl: current.avatarUrl,
      status: current.status == "archived" ? "active" : "archived",
    );
    unawaited(FirestoreDataService.syncStudents(students));
  }

  void deleteStudent(int id) {
    students.removeWhere((s) => s.id == id);
    behaviors.removeWhere((b) => b.studentId == id);
    unawaited(FirestoreDataService.syncStudents(students));
    unawaited(FirestoreDataService.syncBehaviors(behaviors));
  }

  void addBehavior(int studentId, String type, String category, String description, {int? notifyTeacherId}) {
    if (category.trim().isEmpty) return;
    final now = DateTime.now();
    final behavior = Behavior(_nextId(behaviors.map((b) => b.id)), studentId, user!.id, type, category, description, now);
    behaviors.insert(0, behavior);
    unawaited(FirestoreDataService.syncBehaviors(behaviors));

    Student? student;
    for (final s in students) {
      if (s.id == studentId) {
        student = s;
        break;
      }
    }
    if (student == null) return;
    final sender = user!;
    final text = "${sender.fullName} > ${student.fullName} > $category";

    final recipients = users.where((u) => u.role == "teacher" && u.status == "active" && u.id != sender.id);
    final recipientIds = <int>[];
    for (final teacher in recipients) {
      recipientIds.add(teacher.id);
      notifications.insert(
        0,
        AppNotification(
          notifications.length + 1,
          teacher.id,
          sender.id,
          "Yeni Davranis Kaydi",
          text,
          now,
        ),
      );
    }
    unawaited(
      FirebaseNotificationService.createBehaviorNotifications(
        senderId: sender.id,
        recipientIds: recipientIds,
        title: "Yeni Davranis Kaydi",
        message: text,
        time: now,
        behaviorId: behavior.id,
      ),
    );

    if (notifyTeacherId != null && notifyTeacherId != sender.id) {
      AppUser? target;
      for (final u in users) {
        if (u.id == notifyTeacherId && u.status == "active" && u.role == "teacher") {
          target = u;
          break;
        }
      }
      if (target != null) {
        final detailed = "Davranis Bilgilendirme\n"
            "Ogrenci: ${student.fullName}\n"
            "Tip: ${type == "positive" ? "Olumlu" : "Olumsuz"}\n"
            "Kategori: $category\n"
            "Aciklama: ${description.trim().isEmpty ? "-" : description.trim()}\n"
            "Tarih: ${now.day.toString().padLeft(2, "0")}/${now.month.toString().padLeft(2, "0")}/${now.year} ${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}";
        messages.add(MessageItem(_nextId(messages.map((m) => m.id)), sender.id, target.id, detailed, now, isRead: false));
        unawaited(FirestoreDataService.syncMessages(messages));
      }
    }
  }

  void updateBehavior(
    int id, {
    required String type,
    required String category,
    required String description,
  }) {
    final index = behaviors.indexWhere((b) => b.id == id);
    if (index == -1) return;
    final current = behaviors[index];
    behaviors[index] = Behavior(
      current.id,
      current.studentId,
      current.teacherId,
      type,
      category,
      description,
      current.date,
    );
    unawaited(FirestoreDataService.syncBehaviors(behaviors));
  }

  void deleteBehavior(int id) {
    behaviors.removeWhere((b) => b.id == id);
    unawaited(FirestoreDataService.syncBehaviors(behaviors));
  }

  Future<bool> addTeacher({
    required String fullName,
    required String email,
    required String branch,
    required String classTeacherOf,
    required String avatarUrl,
  }) {
    if (fullName.trim().isEmpty || email.trim().isEmpty) return Future.value(false);
    final nextId = users.isEmpty ? 1 : (users.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    final normalizedEmail = email.trim().toLowerCase();
    final generatedUsername = usernameFromEmail(normalizedEmail);
    final newUser = AppUser(
      nextId,
      generatedUsername,
      "P123456",
      fullName.trim(),
      "teacher",
      normalizedEmail,
      classTeacherOf.trim().isEmpty ? null : classTeacherOf.trim(),
      branch: branch.trim().isEmpty ? null : branch.trim(),
      mustChangePassword: true,
      avatarUrl: avatarUrl.trim().isEmpty ? null : avatarUrl.trim(),
    );
    users.add(newUser);
    return FirestoreDataService.syncUsers(users).then((_) => true).catchError((_) {
      users.removeWhere((u) => u.id == newUser.id);
      return false;
    });
  }

  void updateTeacher(
    int id, {
    required String fullName,
    required String email,
    required String branch,
    required String classTeacherOf,
    required String avatarUrl,
  }) {
    final index = users.indexWhere((u) => u.id == id);
    if (index == -1) return;
    final current = users[index];
    final normalizedEmail = email.trim().toLowerCase();
    users[index] = AppUser(
      current.id,
      usernameFromEmail(normalizedEmail),
      current.password,
      fullName,
      current.role,
      normalizedEmail,
      classTeacherOf.isEmpty ? null : classTeacherOf,
      branch: branch.isEmpty ? null : branch,
      status: current.status,
      mustChangePassword: current.mustChangePassword,
      avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
    );
    if (user?.id == current.id) {
      user = users[index];
    }
    unawaited(FirestoreDataService.syncUsers(users));
  }

  void archiveTeacher(int id) {
    final index = users.indexWhere((u) => u.id == id);
    if (index == -1) return;
    final current = users[index];
    users[index] = AppUser(
      current.id,
      current.username,
      current.password,
      current.fullName,
      current.role,
      current.email,
      current.classTeacherOf,
      branch: current.branch,
      status: current.status == "archived" ? "active" : "archived",
      mustChangePassword: current.mustChangePassword,
      avatarUrl: current.avatarUrl,
    );
    if (user?.id == current.id) {
      user = users[index];
    }
    unawaited(FirestoreDataService.syncUsers(users));
  }

  void deleteTeacher(int id) {
    users.removeWhere((u) => u.id == id);
    behaviors.removeWhere((b) => b.teacherId == id);
    messages.removeWhere((m) => m.senderId == id || m.recipientId == id);
    if (user?.id == id) {
      logout();
    }
    unawaited(FirestoreDataService.syncUsers(users));
    unawaited(FirestoreDataService.syncBehaviors(behaviors));
    unawaited(FirestoreDataService.syncMessages(messages));
  }

  void send(int recipientId, String content) {
    messages.add(MessageItem(_nextId(messages.map((m) => m.id)), user!.id, recipientId, content, DateTime.now(), isRead: false));
    unawaited(FirestoreDataService.syncMessages(messages));
  }
  List<MessageItem> chat(int contactId) => messages.where((m) => (m.senderId == user!.id && m.recipientId == contactId) || (m.senderId == contactId && m.recipientId == user!.id)).toList();
  void deleteMessage(int id) {
    messages.removeWhere((m) => m.id == id);
    unawaited(FirestoreDataService.syncMessages(messages));
  }

  int unreadMessageCountForCurrentUser() {
    if (user == null) return 0;
    return messages.where((m) => m.recipientId == user!.id && !m.isRead).length;
  }

  void markChatRead(int contactId) {
    if (user == null) return;
    var changed = false;
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      if (m.recipientId == user!.id && m.senderId == contactId && !m.isRead) {
        messages[i] = MessageItem(m.id, m.senderId, m.recipientId, m.content, m.time, isRead: true);
        changed = true;
      }
    }
    if (changed) {
      unawaited(FirestoreDataService.syncMessages(messages));
    }
  }

  List<AppNotification> notificationsForCurrentUser() {
    if (user == null) return const [];
    return notifications.where((n) => n.recipientId == user!.id).toList()..sort((a, b) => b.time.compareTo(a.time));
  }

  int unreadNotificationCountForCurrentUser() {
    if (user == null) return 0;
    return notifications.where((n) => n.recipientId == user!.id && !n.isRead).length;
  }

  void markNotificationRead(int id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    final current = notifications[idx];
    notifications[idx] = AppNotification(
      current.id,
      current.recipientId,
      current.senderId,
      current.title,
      current.message,
      current.time,
      isRead: true,
    );
  }

  void markAllNotificationsReadForCurrentUser() {
    if (user == null) return;
    for (var i = 0; i < notifications.length; i++) {
      final n = notifications[i];
      if (n.recipientId == user!.id && !n.isRead) {
        notifications[i] = AppNotification(
          n.id,
          n.recipientId,
          n.senderId,
          n.title,
          n.message,
          n.time,
          isRead: true,
        );
      }
    }
  }

  Future<bool> changeCurrentUserPassword(String newPassword) async {
    if (user == null) return false;
    final idx = users.indexWhere((u) => u.id == user!.id);
    if (idx == -1) return false;
    final current = users[idx];
    final updated = AppUser(
      current.id,
      current.username,
      newPassword,
      current.fullName,
      current.role,
      current.email,
      current.classTeacherOf,
      branch: current.branch,
      status: current.status,
      mustChangePassword: false,
      avatarUrl: current.avatarUrl,
    );
    users[idx] = updated;
    user = updated;
    try {
      await FirestoreDataService.syncUsers(users).timeout(const Duration(seconds: 12));
      return true;
    } catch (_) {
      users[idx] = current;
      user = current;
      return false;
    }
  }

  Future<void> saveSession() async {
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("session_user_id", user!.id);
    await prefs.setString("session_username", user!.username.toLowerCase());
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt("session_user_id");
    final username = prefs.getString("session_username")?.trim().toLowerCase();
    int idx = -1;
    if (id != null) {
      idx = users.indexWhere((u) => u.id == id && u.status == "active");
    }
    if (idx == -1 && username != null && username.isNotEmpty) {
      idx = users.indexWhere((u) => u.username.toLowerCase() == username && u.status == "active");
    }
    if (idx != -1) {
      user = users[idx];
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("session_user_id");
    await prefs.remove("session_username");
  }

  Future<void> syncAllToFirestoreNow() async {
    await FirestoreDataService.syncUsers(users);
    await FirestoreDataService.syncStudents(students);
    await FirestoreDataService.syncBehaviors(behaviors);
    await FirestoreDataService.syncMessages(messages);
  }
}







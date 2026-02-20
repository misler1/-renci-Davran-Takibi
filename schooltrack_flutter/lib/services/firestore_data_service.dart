import "package:cloud_firestore/cloud_firestore.dart";
import "package:schooltrack_flutter/models/app_models.dart";

class FirestoreSnapshotData {
  const FirestoreSnapshotData({
    required this.users,
    required this.students,
    required this.behaviors,
    required this.messages,
  });
  final List<AppUser> users;
  final List<Student> students;
  final List<Behavior> behaviors;
  final List<MessageItem> messages;
}

class FirestoreDataService {
  static CollectionReference<Map<String, dynamic>> _collection(String name) => FirebaseFirestore.instance.collection(name);

  static Future<AppUser?> findUserByUsername(String username) async {
    final trimmed = username.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    final query = await _collection("users").where("username", isEqualTo: trimmed).limit(1).get();
    if (query.docs.isEmpty) return null;
    return _mapUsers(query).first;
  }

  static Future<({List<AppUser> users, List<Student> students})> loadUsersAndStudents() async {
    final usersSnap = await _collection("users").get();
    final studentsSnap = await _collection("students").get();

    final users = _mapUsers(usersSnap);
    final students = _mapStudents(studentsSnap);
    return (users: users, students: students);
  }

  static Future<({List<Behavior> behaviors, List<MessageItem> messages})> loadBehaviorsAndMessages() async {
    final behaviorsSnap = await _collection("behaviors").get();
    final messagesSnap = await _collection("messages").get();

    final behaviors = _mapBehaviors(behaviorsSnap);
    final messages = _mapMessages(messagesSnap);
    return (behaviors: behaviors, messages: messages);
  }

  static Stream<List<MessageItem>> messagesForRecipient(int recipientId) {
    return _collection("messages")
        .where("recipientId", isEqualTo: recipientId)
        .snapshots()
        .map((snap) => _mapMessages(snap));
  }

  static Future<FirestoreSnapshotData> loadAll() async {
    final snapshots = await Future.wait([
      _collection("users").get(),
      _collection("students").get(),
      _collection("behaviors").get(),
      _collection("messages").get(),
    ]);
    final users = _mapUsers(snapshots[0]);
    final students = _mapStudents(snapshots[1]);
    final behaviors = _mapBehaviors(snapshots[2]);
    final messages = _mapMessages(snapshots[3]);

    return FirestoreSnapshotData(users: users, students: students, behaviors: behaviors, messages: messages);
  }

  static List<AppUser> _mapUsers(QuerySnapshot<Map<String, dynamic>> usersSnap) {
    return usersSnap.docs.map((d) {
      final m = d.data();
      return AppUser(
        (m["id"] as num).toInt(),
        (m["username"] as String?) ?? "",
        (m["password"] as String?) ?? "P123456",
        (m["fullName"] as String?) ?? "",
        (m["role"] as String?) ?? "teacher",
        (m["email"] as String?) ?? "",
        m["classTeacherOf"] as String?,
        branch: m["branch"] as String?,
        status: (m["status"] as String?) ?? "active",
        mustChangePassword: (m["mustChangePassword"] as bool?) ?? false,
        avatarUrl: m["avatarUrl"] as String?,
      );
    }).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  static List<Student> _mapStudents(QuerySnapshot<Map<String, dynamic>> studentsSnap) {
    return studentsSnap.docs.map((d) {
      final m = d.data();
      return Student(
        (m["id"] as num).toInt(),
        (m["studentNumber"] as String?) ?? "",
        (m["fullName"] as String?) ?? "",
        (m["className"] as String?) ?? "",
        parentName: m["parentName"] as String?,
        parentPhone: m["parentPhone"] as String?,
        avatarUrl: m["avatarUrl"] as String?,
        status: (m["status"] as String?) ?? "active",
      );
    }).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  static List<Behavior> _mapBehaviors(QuerySnapshot<Map<String, dynamic>> behaviorsSnap) {
    return behaviorsSnap.docs.map((d) {
      final m = d.data();
      final ts = m["date"];
      return Behavior(
        (m["id"] as num).toInt(),
        (m["studentId"] as num).toInt(),
        (m["teacherId"] as num).toInt(),
        (m["type"] as String?) ?? "negative",
        (m["category"] as String?) ?? "",
        (m["description"] as String?) ?? "",
        ts is Timestamp ? ts.toDate() : DateTime.now(),
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<MessageItem> _mapMessages(QuerySnapshot<Map<String, dynamic>> messagesSnap) {
    return messagesSnap.docs.map((d) {
      final m = d.data();
      final ts = m["time"];
      return MessageItem(
        (m["id"] as num).toInt(),
        (m["senderId"] as num).toInt(),
        (m["recipientId"] as num).toInt(),
        (m["content"] as String?) ?? "",
        ts is Timestamp ? ts.toDate() : DateTime.now(),
        isRead: (m["isRead"] as bool?) ?? false,
      );
    }).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
  }

  static Future<void> syncUsers(List<AppUser> users) async {
    final col = _collection("users");
    final batch = FirebaseFirestore.instance.batch();
    for (final u in users) {
      batch.set(col.doc(u.id.toString()), {
        "id": u.id,
        "username": u.username,
        "password": u.password,
        "fullName": u.fullName,
        "role": u.role,
        "email": u.email,
        "classTeacherOf": u.classTeacherOf,
        "branch": u.branch,
        "status": u.status,
        "mustChangePassword": u.mustChangePassword,
        "avatarUrl": u.avatarUrl,
      });
    }
    await batch.commit();
  }

  static Future<void> syncStudents(List<Student> students) async {
    final col = _collection("students");
    final batch = FirebaseFirestore.instance.batch();
    for (final s in students) {
      batch.set(col.doc(s.id.toString()), {
        "id": s.id,
        "studentNumber": s.studentNumber,
        "fullName": s.fullName,
        "className": s.className,
        "parentName": s.parentName,
        "parentPhone": s.parentPhone,
        "avatarUrl": s.avatarUrl,
        "status": s.status,
      });
    }
    await batch.commit();
  }

  static Future<void> syncBehaviors(List<Behavior> behaviors) async {
    final col = _collection("behaviors");
    final batch = FirebaseFirestore.instance.batch();
    for (final b in behaviors) {
      batch.set(col.doc(b.id.toString()), {
        "id": b.id,
        "studentId": b.studentId,
        "teacherId": b.teacherId,
        "type": b.type,
        "category": b.category,
        "description": b.description,
        "date": Timestamp.fromDate(b.date),
      });
    }
    await batch.commit();
  }

  static Future<void> syncMessages(List<MessageItem> messages) async {
    final col = _collection("messages");
    final batch = FirebaseFirestore.instance.batch();

    for (final m in messages) {
      batch.set(col.doc(m.id.toString()), {
        "id": m.id,
        "senderId": m.senderId,
        "recipientId": m.recipientId,
        "content": m.content,
        "time": Timestamp.fromDate(m.time),
        "isRead": m.isRead,
      });
    }

    await batch.commit();
  }
}

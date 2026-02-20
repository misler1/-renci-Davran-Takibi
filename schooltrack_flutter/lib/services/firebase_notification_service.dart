import "package:cloud_firestore/cloud_firestore.dart";
import "package:schooltrack_flutter/models/app_models.dart";

class FirebaseNotificationService {
  static CollectionReference<Map<String, dynamic>> get _collection => FirebaseFirestore.instance.collection("teacher_notifications");

  static Future<void> createBehaviorNotifications({
    required int senderId,
    required List<int> recipientIds,
    required String title,
    required String message,
    required DateTime time,
    int? behaviorId,
  }) async {
    for (final recipientId in recipientIds) {
      await _collection.add({
        "senderId": senderId,
        "recipientId": recipientId,
        "title": title,
        "message": message,
        "isRead": false,
        "time": Timestamp.fromDate(time),
        "behaviorId": behaviorId,
      });
    }
  }

  static Stream<List<AppNotification>> notificationsForUser(int recipientId) {
    return _collection.where("recipientId", isEqualTo: recipientId).snapshots().map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        final ts = data["time"];
        final date = ts is Timestamp ? ts.toDate() : DateTime.now();
        return AppNotification(
          0,
          (data["recipientId"] as num?)?.toInt() ?? recipientId,
          (data["senderId"] as num?)?.toInt() ?? 0,
          (data["title"] as String?) ?? "Bildirim",
          (data["message"] as String?) ?? "",
          date,
          isRead: (data["isRead"] as bool?) ?? false,
          remoteId: doc.id,
          behaviorId: (data["behaviorId"] as num?)?.toInt(),
        );
      }).toList()
        ..sort((a, b) => b.time.compareTo(a.time));
      return items;
    });
  }

  static Future<void> markRead(String remoteId) async {
    await _collection.doc(remoteId).update({"isRead": true});
  }

  static Future<void> markAllReadForUser(int recipientId) async {
    final query = await _collection.where("recipientId", isEqualTo: recipientId).where("isRead", isEqualTo: false).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {"isRead": true});
    }
    await batch.commit();
  }
}

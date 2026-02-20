String roleText(String role) {
  switch (role) {
    case "teacher":
      return "Ogretmen";
    case "admin":
      return "Yonetici";
    default:
      return role;
  }
}

String usernameFromEmail(String email) {
  final trimmed = email.trim().toLowerCase();
  if (!trimmed.contains("@")) return trimmed;
  return trimmed.split("@").first;
}

class AppUser {
  AppUser(
    this.id,
    this.username,
    this.password,
    this.fullName,
    this.role,
    this.email,
    this.classTeacherOf, {
    this.branch,
    this.status = "active",
    this.mustChangePassword = false,
    this.avatarUrl,
  });
  final int id;
  final String username;
  final String password;
  final String fullName;
  final String role;
  final String email;
  final String? classTeacherOf;
  final String? branch;
  final String status;
  final bool mustChangePassword;
  final String? avatarUrl;
}

class Student {
  Student(
    this.id,
    this.studentNumber,
    this.fullName,
    this.className, {
    this.parentName,
    this.parentPhone,
    this.avatarUrl,
    this.status = "active",
  });
  final int id;
  final String studentNumber;
  final String fullName;
  final String className;
  final String? parentName;
  final String? parentPhone;
  final String? avatarUrl;
  final String status;
}

class Behavior {
  Behavior(this.id, this.studentId, this.teacherId, this.type, this.category, this.description, this.date);
  final int id;
  final int studentId;
  final int teacherId;
  final String type;
  final String category;
  final String description;
  final DateTime date;
}

class AppNotification {
  AppNotification(
    this.id,
    this.recipientId,
    this.senderId,
    this.title,
    this.message,
    this.time, {
    this.isRead = false,
    this.remoteId,
    this.behaviorId,
  });
  final int id;
  final int recipientId;
  final int senderId;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;
  final String? remoteId;
  final int? behaviorId;
}

class MessageItem {
  MessageItem(this.id, this.senderId, this.recipientId, this.content, this.time, {this.isRead = false});
  final int id;
  final int senderId;
  final int recipientId;
  final String content;
  final DateTime time;
  final bool isRead;
}

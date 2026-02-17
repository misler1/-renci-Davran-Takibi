
import { db } from "./db";
import {
  users, students, behaviors, notifications, messages,
  type User, type InsertUser, type Student, type InsertStudent,
  type Behavior, type InsertBehavior, type Notification, type Message,
  type InsertBehavior as CreateBehaviorParams // Alias for clarity
} from "@shared/schema";
import { eq, desc, or, and, sql } from "drizzle-orm";

export interface IStorage {
  // Users
  getUser(id: number): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  createUser(user: InsertUser): Promise<User>;
  updateUser(id: number, updates: Partial<User>): Promise<User>;
  getUsers(): Promise<User[]>;
  getTeachers(): Promise<User[]>; // Filter by role 'teacher'

  // Students
  getStudent(id: number): Promise<Student | undefined>;
  getStudentByNumber(number: string): Promise<Student | undefined>;
  createStudent(student: InsertStudent): Promise<Student>;
  getStudents(): Promise<Student[]>;
  getStudentsByClass(className: string): Promise<Student[]>;

  // Behaviors
  createBehavior(behavior: InsertBehavior): Promise<Behavior>;
  getBehaviors(filters?: { studentId?: number, teacherId?: number }): Promise<(Behavior & { teacher: User, student: Student })[]>;
  getBehaviorStats(): Promise<{ total: number, positive: number, negative: number }>;

  // Notifications
  createNotification(notification: Omit<Notification, "id" | "createdAt" | "isRead">): Promise<Notification>;
  getNotifications(userId: number): Promise<Notification[]>;
  markNotificationRead(id: number): Promise<void>;

  // Messages
  createMessage(message: Omit<Message, "id" | "createdAt" | "isRead">): Promise<Message>;
  getMessages(userId: number, contactId?: number): Promise<Message[]>;
}

export class DatabaseStorage implements IStorage {
  // Users
  async getUser(id: number): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.id, id));
    return user;
  }

  async getUserByUsername(username: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.username, username));
    return user;
  }

  async createUser(user: InsertUser): Promise<User> {
    const [newUser] = await db.insert(users).values(user).returning();
    return newUser;
  }

  async updateUser(id: number, updates: Partial<User>): Promise<User> {
    const [updated] = await db.update(users).set(updates).where(eq(users.id, id)).returning();
    return updated;
  }

  async getUsers(): Promise<User[]> {
    return await db.select().from(users).orderBy(users.fullName);
  }

  async getTeachers(): Promise<User[]> {
    return await db.select().from(users).where(eq(users.role, 'teacher')).orderBy(users.fullName);
  }

  // Students
  async getStudent(id: number): Promise<Student | undefined> {
    const [student] = await db.select().from(students).where(eq(students.id, id));
    return student;
  }

  async getStudentByNumber(number: string): Promise<Student | undefined> {
    const [student] = await db.select().from(students).where(eq(students.studentNumber, number));
    return student;
  }

  async createStudent(student: InsertStudent): Promise<Student> {
    const [newStudent] = await db.insert(students).values(student).returning();
    return newStudent;
  }

  async getStudents(): Promise<Student[]> {
    return await db.select().from(students).orderBy(students.className, students.studentNumber);
  }

  async getStudentsByClass(className: string): Promise<Student[]> {
    return await db.select().from(students).where(eq(students.className, className));
  }

  // Behaviors
  async createBehavior(behavior: InsertBehavior): Promise<Behavior> {
    const [newBehavior] = await db.insert(behaviors).values(behavior).returning();
    return newBehavior;
  }

  async getBehaviors(filters?: { studentId?: number, teacherId?: number }): Promise<(Behavior & { teacher: User, student: Student })[]> {
    const conditions = [];
    if (filters?.studentId) conditions.push(eq(behaviors.studentId, filters.studentId));
    if (filters?.teacherId) conditions.push(eq(behaviors.teacherId, filters.teacherId));

    const query = db.select({
        id: behaviors.id,
        studentId: behaviors.studentId,
        teacherId: behaviors.teacherId,
        type: behaviors.type,
        category: behaviors.category,
        description: behaviors.description,
        stage: behaviors.stage,
        date: behaviors.date,
        teacher: users,
        student: students,
      })
      .from(behaviors)
      .leftJoin(users, eq(behaviors.teacherId, users.id))
      .leftJoin(students, eq(behaviors.studentId, students.id))
      .orderBy(desc(behaviors.date));

    if (conditions.length > 0) {
      // @ts-ignore
      query.where(and(...conditions));
    }

    // @ts-ignore
    return await query;
  }

  async getBehaviorStats(): Promise<{ total: number, positive: number, negative: number }> {
    const [total] = await db.select({ count: sql<number>`count(*)` }).from(behaviors);
    const [positive] = await db.select({ count: sql<number>`count(*)` }).from(behaviors).where(eq(behaviors.type, 'positive'));
    const [negative] = await db.select({ count: sql<number>`count(*)` }).from(behaviors).where(eq(behaviors.type, 'negative'));

    return {
      total: Number(total?.count || 0),
      positive: Number(positive?.count || 0),
      negative: Number(negative?.count || 0),
    };
  }


  // Notifications
  async createNotification(notification: Omit<Notification, "id" | "createdAt" | "isRead">): Promise<Notification> {
    const [newNotif] = await db.insert(notifications).values(notification).returning();
    return newNotif;
  }

  async getNotifications(userId: number): Promise<Notification[]> {
    return await db.select()
      .from(notifications)
      .where(eq(notifications.recipientId, userId))
      .orderBy(desc(notifications.createdAt))
      .limit(50);
  }

  async markNotificationRead(id: number): Promise<void> {
    await db.update(notifications).set({ isRead: true }).where(eq(notifications.id, id));
  }

  // Messages
  async createMessage(message: Omit<Message, "id" | "createdAt" | "isRead">): Promise<Message> {
    const [msg] = await db.insert(messages).values(message).returning();
    return msg;
  }

  async getMessages(userId: number, contactId?: number): Promise<Message[]> {
     const conditions = [
        or(
          eq(messages.senderId, userId),
          eq(messages.recipientId, userId)
        )
     ];

     if (contactId) {
       conditions.push(
         or(
            and(eq(messages.senderId, userId), eq(messages.recipientId, contactId)),
            and(eq(messages.senderId, contactId), eq(messages.recipientId, userId))
         )
       );
     }

    return await db.select()
      .from(messages)
      .where(and(...conditions))
      .orderBy(desc(messages.createdAt))
      .limit(100);
  }
}

export const storage = new DatabaseStorage();

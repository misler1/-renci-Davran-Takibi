
import { pgTable, text, serial, integer, boolean, timestamp, jsonb } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

// === TABLE DEFINITIONS ===

// Users (Teachers/Admins)
export const users = pgTable("users", {
  id: serial("id").primaryKey(),
  username: text("username").notNull().unique(), // firstname.lastname
  password: text("password").notNull(),
  fullName: text("full_name").notNull(),
  email: text("email").notNull(),
  role: text("role").notNull().default("teacher"), // teacher, admin, principal
  classTeacherOf: text("class_teacher_of"), // e.g., "9-A" (nullable)
  coachGroup: text("coach_group"), // e.g., "Group 1" (nullable)
  isFirstLogin: boolean("is_first_login").default(true),
  status: text("status").notNull().default("active"), // active, archived
  createdAt: timestamp("created_at").defaultNow(),
});

// Students
export const students = pgTable("students", {
  id: serial("id").primaryKey(),
  studentNumber: text("student_number").notNull().unique(),
  fullName: text("full_name").notNull(),
  className: text("class_name").notNull(), // e.g., "9-A"
  parentName: text("parent_name"),
  parentPhone: text("parent_phone"),
  coachId: integer("coach_id").references(() => users.id), // Assigned coach teacher
  status: text("status").notNull().default("active"), // active, archived
  createdAt: timestamp("created_at").defaultNow(),
});

// Behavior Records
export const behaviors = pgTable("behaviors", {
  id: serial("id").primaryKey(),
  studentId: integer("student_id").notNull().references(() => students.id),
  teacherId: integer("teacher_id").notNull().references(() => users.id),
  type: text("type").notNull(), // 'positive' | 'negative'
  category: text("category").notNull(), // e.g., 'Late', 'Disruption', etc.
  description: text("description"),
  stage: integer("stage").default(1), // 1: Warning, 2: Class Teacher, 3: Guidance, etc.
  date: timestamp("date").defaultNow(),
});

// Notifications
export const notifications = pgTable("notifications", {
  id: serial("id").primaryKey(),
  recipientId: integer("recipient_id").notNull().references(() => users.id),
  senderId: integer("sender_id").references(() => users.id), // Nullable if system notification
  type: text("type").notNull(), // 'behavior_alert', 'message'
  title: text("title").notNull(),
  message: text("message").notNull(),
  relatedId: integer("related_id"), // ID of behavior or other entity
  isRead: boolean("is_read").default(false),
  createdAt: timestamp("created_at").defaultNow(),
});

// Messages (Teacher to Teacher)
export const messages = pgTable("messages", {
  id: serial("id").primaryKey(),
  senderId: integer("sender_id").notNull().references(() => users.id),
  recipientId: integer("recipient_id").notNull().references(() => users.id),
  content: text("content").notNull(),
  isRead: boolean("is_read").default(false),
  createdAt: timestamp("created_at").defaultNow(),
});

// === RELATIONS ===
export const usersRelations = relations(users, ({ many }) => ({
  behaviorsRecorded: many(behaviors),
  notificationsReceived: many(notifications),
  messagesSent: many(messages, { relationName: "sender" }),
  messagesReceived: many(messages, { relationName: "recipient" }),
  studentsCoached: many(students),
}));

export const studentsRelations = relations(students, ({ one, many }) => ({
  coach: one(users, {
    fields: [students.coachId],
    references: [users.id],
  }),
  behaviors: many(behaviors),
}));

export const behaviorsRelations = relations(behaviors, ({ one }) => ({
  student: one(students, {
    fields: [behaviors.studentId],
    references: [students.id],
  }),
  teacher: one(users, {
    fields: [behaviors.teacherId],
    references: [users.id],
  }),
}));

// === BASE SCHEMAS ===
export const insertUserSchema = createInsertSchema(users).omit({ id: true, createdAt: true, isFirstLogin: true });
export const insertStudentSchema = createInsertSchema(students).omit({ id: true, createdAt: true });
export const insertBehaviorSchema = createInsertSchema(behaviors).omit({ id: true, date: true });
export const insertMessageSchema = createInsertSchema(messages).omit({ id: true, createdAt: true, isRead: true });

// === EXPLICIT API CONTRACT TYPES ===
export type User = typeof users.$inferSelect;
export type InsertUser = z.infer<typeof insertUserSchema>;
export type Student = typeof students.$inferSelect;
export type InsertStudent = z.infer<typeof insertStudentSchema>;
export type Behavior = typeof behaviors.$inferSelect;
export type InsertBehavior = z.infer<typeof insertBehaviorSchema>;
export type Notification = typeof notifications.$inferSelect;
export type Message = typeof messages.$inferSelect;

// Request Types
export type LoginRequest = { username: string; password: string };
export type ChangePasswordRequest = { currentPassword: string; newPassword: string };
export type CreateBehaviorRequest = InsertBehavior & { notifyClassTeacher?: boolean; notifyCoach?: boolean };

// Response Types
export type AuthResponse = User; // Simplified for MVP


import type { Express, Request, Response, NextFunction } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { api, errorSchemas } from "@shared/routes";
import { z } from "zod";
import session from "express-session";
import MemoryStore from "memorystore";
import { scrypt, randomBytes, timingSafeEqual } from "crypto";
import { promisify } from "util";
import { InsertUser } from "@shared/schema";

const scryptAsync = promisify(scrypt);

// Auth Helpers
async function hashPassword(password: string) {
  const salt = randomBytes(16).toString("hex");
  const buf = (await scryptAsync(password, salt, 64)) as Buffer;
  return `${buf.toString("hex")}.${salt}`;
}

async function comparePassword(stored: string, supplied: string) {
  const [hashed, salt] = stored.split(".");
  const buf = (await scryptAsync(supplied, salt, 64)) as Buffer;
  return timingSafeEqual(Buffer.from(hashed, "hex"), buf);
}

// Middleware to check auth
function requireAuth(req: Request, res: Response, next: NextFunction) {
  if (!req.session.userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }
  next();
}

// Extend session type
declare module "express-session" {
  interface SessionData {
    userId: number;
  }
}

export async function registerRoutes(
  httpServer: Server,
  app: Express
): Promise<Server> {
  const isProduction = process.env.NODE_ENV === "production";
  const sameSite = (process.env.SESSION_SAME_SITE ?? "lax") as "lax" | "strict" | "none";

  // Session Setup
  const SessionStore = MemoryStore(session);
  app.use(
    session({
      secret: process.env.SESSION_SECRET || "default_secret_key",
      resave: false,
      saveUninitialized: false,
      cookie: {
        maxAge: 86400000, // 24h
        httpOnly: true,
        sameSite,
        secure: isProduction,
      },
      store: new SessionStore({
        checkPeriod: 86400000,
      }),
    })
  );

  // === AUTH Routes ===

  app.post(api.auth.login.path, async (req, res) => {
    try {
      const { username, password } = api.auth.login.input.parse(req.body);
      const user = await storage.getUserByUsername(username);

      if (!user || !(await comparePassword(user.password, password))) {
        return res.status(401).json({ message: "Invalid credentials" });
      }

      req.session.userId = user.id;
      res.json(user);
    } catch (err) {
      res.status(400).json({ message: "Invalid input" });
    }
  });

  app.post(api.auth.logout.path, (req, res) => {
    req.session.destroy(() => {
      res.json({ message: "Logged out" });
    });
  });

  app.get(api.auth.me.path, async (req, res) => {
    if (!req.session.userId) return res.status(401).json({ message: "Not logged in" });
    const user = await storage.getUser(req.session.userId);
    if (!user) return res.status(401).json({ message: "User not found" });
    res.json(user);
  });

  app.post(api.auth.changePassword.path, requireAuth, async (req, res) => {
    try {
      const { currentPassword, newPassword } = api.auth.changePassword.input.parse(req.body);
      const user = await storage.getUser(req.session.userId!);

      if (!user || !(await comparePassword(user.password, currentPassword))) {
        return res.status(400).json({ message: "Incorrect current password" });
      }

      const hashedPassword = await hashPassword(newPassword);
      await storage.updateUser(user.id, { password: hashedPassword, isFirstLogin: false });

      res.json({ message: "Password updated" });
    } catch (err) {
      res.status(400).json({ message: "Invalid input" });
    }
  });

  // === DATA Routes ===

  app.get(api.users.list.path, requireAuth, async (req, res) => {
    const users = await storage.getUsers();
    res.json(users);
  });

  app.get(api.users.get.path, requireAuth, async (req, res) => {
    const user = await storage.getUser(Number(req.params.id));
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  });

  app.post(api.users.create.path, requireAuth, async (req, res) => {
    try {
      const input = api.users.create.input.parse(req.body);
      // Hash default password or provided one
      const hashedPassword = await hashPassword(input.password || "P123456");
      const user = await storage.createUser({ ...input, password: hashedPassword });
      res.status(201).json(user);
    } catch (err) {
      res.status(400).json({ message: "Invalid input" });
    }
  });

  app.patch(api.users.update.path, requireAuth, async (req, res) => {
    try {
      const input = api.users.update.input.parse(req.body);
      const user = await storage.updateUser(Number(req.params.id), input);
      res.json(user);
    } catch (err) {
      res.status(400).json({ message: "Invalid input" });
    }
  });

  app.delete(api.users.delete.path, requireAuth, async (req, res) => {
    await storage.deleteUser(Number(req.params.id));
    res.json({ success: true });
  });

  app.get(api.students.list.path, requireAuth, async (req, res) => {
    const students = await storage.getStudents();
    res.json(students);
  });

  app.get(api.students.get.path, requireAuth, async (req, res) => {
    const student = await storage.getStudent(Number(req.params.id));
    if (!student) return res.status(404).json({ message: "Student not found" });
    res.json(student);
  });

  app.post(api.students.create.path, requireAuth, async (req, res) => {
    try {
      const input = api.students.create.input.parse(req.body);
      const student = await storage.createStudent(input);
      res.status(201).json(student);
    } catch (err) {
       if (err instanceof z.ZodError) {
        res.status(400).json({
          message: err.errors[0].message,
          field: err.errors[0].path.join('.'),
        });
      } else {
        res.status(500).json({ message: "Internal server error" });
      }
    }
  });

  app.patch(api.students.update.path, requireAuth, async (req, res) => {
    try {
      const input = api.students.update.input.parse(req.body);
      const student = await storage.updateStudent(Number(req.params.id), input);
      res.json(student);
    } catch (err) {
      res.status(400).json({ message: "Invalid input" });
    }
  });

  app.delete(api.students.delete.path, requireAuth, async (req, res) => {
    await storage.deleteStudent(Number(req.params.id));
    res.json({ success: true });
  });

  app.get(api.behaviors.list.path, requireAuth, async (req, res) => {
    const filters = {
      studentId: req.query.studentId ? Number(req.query.studentId) : undefined,
      teacherId: req.query.teacherId ? Number(req.query.teacherId) : undefined,
    };
    const behaviors = await storage.getBehaviors(filters);
    res.json(behaviors);
  });

  app.post(api.behaviors.create.path, requireAuth, async (req, res) => {
    try {
      const input = api.behaviors.create.input.parse(req.body);
      const { notifyClassTeacher, notifyCoach, ...behaviorData } = input;

      const behavior = await storage.createBehavior(behaviorData);
      
      // Handle Notifications
      const student = await storage.getStudent(behaviorData.studentId);
      const currentUser = await storage.getUser(req.session.userId!);

      if (student && currentUser) {
        const message = `${currentUser.fullName} reported a ${behaviorData.type} behavior for ${student.fullName}: ${behaviorData.category}`;

        // Notify Class Teacher
        if (notifyClassTeacher) {
          const teachers = await storage.getTeachers();
          const classTeacher = teachers.find(t => t.classTeacherOf === student.className);
          if (classTeacher && classTeacher.id !== currentUser.id) {
             await storage.createNotification({
                recipientId: classTeacher.id,
                senderId: currentUser.id,
                type: 'behavior_alert',
                title: 'New Behavior Record',
                message: message,
                relatedId: behavior.id
             });
          }
        }

        // Notify Coach
        if (notifyCoach && student.coachId) {
           if (student.coachId !== currentUser.id) {
             await storage.createNotification({
                recipientId: student.coachId,
                senderId: currentUser.id,
                type: 'behavior_alert',
                title: 'New Behavior Record',
                message: message,
                relatedId: behavior.id
             });
           }
        }
      }

      res.status(201).json(behavior);
    } catch (err) {
      if (err instanceof z.ZodError) {
        res.status(400).json({
          message: err.errors[0].message,
          field: err.errors[0].path.join('.'),
        });
      } else {
        res.status(500).json({ message: "Internal server error" });
      }
    }
  });

  app.get(api.behaviors.stats.path, requireAuth, async (req, res) => {
    const stats = await storage.getBehaviorStats();
    res.json({...stats, recent: []}); // Recent fetched via list endpoint separately
  });

  app.get(api.notifications.list.path, requireAuth, async (req, res) => {
    const notifications = await storage.getNotifications(req.session.userId!);
    res.json(notifications);
  });

  app.post(api.notifications.markRead.path, requireAuth, async (req, res) => {
    await storage.markNotificationRead(Number(req.params.id));
    res.json({ success: true });
  });

  // Messages
  app.get(api.messages.list.path, requireAuth, async (req, res) => {
     const contactId = req.query.contactId ? Number(req.query.contactId) : undefined;
     const messages = await storage.getMessages(req.session.userId!, contactId);
     res.json(messages);
  });

  app.post(api.messages.send.path, requireAuth, async (req, res) => {
    try {
      const input = api.messages.send.input.parse(req.body);
      // Ensure sender is current user
      if (input.senderId !== req.session.userId) {
         return res.status(403).json({ message: "Sender mismatch" });
      }
      const message = await storage.createMessage(input);
      
      // Notify recipient
      const sender = await storage.getUser(req.session.userId!);
      if (sender) {
        await storage.createNotification({
           recipientId: input.recipientId,
           senderId: sender.id,
           type: 'message',
           title: `New message from ${sender.fullName}`,
           message: input.content.substring(0, 50) + (input.content.length > 50 ? '...' : ''),
           relatedId: message.id
        });
      }

      res.status(201).json(message);
    } catch (err) {
      res.status(400).json({ message: "Invalid input" });
    }
  });

  // SEED DATA
  seed();

  return httpServer;
}

async function seed() {
  const users = await storage.getUsers();
  if (users.length === 0) {
    const password = await hashPassword("P123456");
    
    // Create Teachers
    const musa = await storage.createUser({
      username: "musa.isler",
      password,
      fullName: "Musa Isler",
      email: "musa.isler@paletokullari.k12.tr",
      role: "teacher",
      classTeacherOf: "9-A",
      coachGroup: "Group 1",
    });

    const ayse = await storage.createUser({
      username: "ayse.yilmaz",
      password,
      fullName: "Ayse Yilmaz",
      email: "ayse.yilmaz@paletokullari.k12.tr",
      role: "teacher",
      classTeacherOf: "10-B",
      coachGroup: "Group 2",
    });

    const mehmet = await storage.createUser({
      username: "mehmet.demir",
      password,
      fullName: "Mehmet Demir",
      email: "mehmet.demir@paletokullari.k12.tr",
      role: "admin", // Principal/Admin
      classTeacherOf: null,
      coachGroup: null,
    });

    // Create Students
    const s1 = await storage.createStudent({
      studentNumber: "101",
      fullName: "Ali Veli",
      className: "9-A",
      parentName: "Veli Baba",
      parentPhone: "555-111-1111",
      coachId: musa.id,
    });

    const s2 = await storage.createStudent({
       studentNumber: "102",
       fullName: "Zeynep Kaya",
       className: "9-A",
       parentName: "Fatma Anne",
       parentPhone: "555-222-2222",
       coachId: musa.id,
    });

    const s3 = await storage.createStudent({
       studentNumber: "201",
       fullName: "Can Yildiz",
       className: "10-B",
       parentName: "Ahmet Baba",
       parentPhone: "555-333-3333",
       coachId: ayse.id,
    });

    // Create Behaviors
    await storage.createBehavior({
      studentId: s1.id,
      teacherId: ayse.id, // Reported by another teacher
      type: "negative",
      category: "Derse Geç Kalma",
      description: "10 dakika geç geldi.",
      stage: 1,
    });

    await storage.createBehavior({
       studentId: s1.id,
       teacherId: musa.id,
       type: "positive",
       category: "Diğer",
       description: "Arkadaşına yardım etti.",
       stage: 0,
    });
    
    console.log("Database seeded!");
  }
}

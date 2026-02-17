# SchoolTrack - Behavior Management System

## Overview

SchoolTrack is a full-stack web application for school behavior management. It allows teachers and administrators to track student behavior (positive and negative), manage student and teacher records, send internal messages, and receive notifications. The app features role-based access (teacher, admin, principal), a dashboard with analytics charts, and a staged behavior escalation system (warning → class teacher → guidance, etc.).

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Frontend
- **Framework**: React 18 with TypeScript, bundled by Vite
- **Routing**: Wouter (lightweight client-side router)
- **State Management**: TanStack React Query for server state; no global client state library
- **UI Components**: shadcn/ui (new-york style) built on Radix UI primitives with Tailwind CSS
- **Styling**: Tailwind CSS with CSS custom properties for theming, custom fonts (Outfit for display, Plus Jakarta Sans for body)
- **Charts**: Recharts for dashboard analytics (PieChart for behavior breakdown)
- **Forms**: React Hook Form with Zod validation via @hookform/resolvers
- **Date Formatting**: date-fns
- **Path Aliases**: `@/` maps to `client/src/`, `@shared/` maps to `shared/`

### Backend
- **Framework**: Express 5 on Node.js with TypeScript (run via tsx)
- **HTTP Server**: Node's `createServer` wrapping Express, enabling potential WebSocket support
- **Authentication**: Session-based auth using express-session with MemoryStore (not persistent across restarts). Passwords hashed with Node's built-in scrypt. Sessions store `userId`.
- **API Design**: REST API under `/api/*` prefix. API contracts defined in `shared/routes.ts` using Zod schemas, shared between client and server for type-safe validation.
- **Dev Server**: Vite dev server mounted as middleware in development; static file serving in production

### Data Layer
- **Database**: PostgreSQL (required via `DATABASE_URL` environment variable)
- **ORM**: Drizzle ORM with `drizzle-zod` for automatic Zod schema generation from table definitions
- **Schema Location**: `shared/schema.ts` — shared between frontend and backend
- **Migrations**: Managed via `drizzle-kit push` (push-based, no migration files needed for dev)
- **Connection**: `pg` Pool via `server/db.ts`

### Database Schema (key tables)
- **users**: Teachers/admins with roles (teacher, admin, principal), class assignments, coach groups
- **students**: Student records with class names, parent contact info, assigned coach (references users)
- **behaviors**: Behavior records linking students and teachers, with type (positive/negative), category, stage (escalation level), and date
- **notifications**: User-targeted notifications with read status
- **messages**: Internal messaging between users (sender/recipient)

### API Contract Pattern
The `shared/routes.ts` file defines a typed API contract object (`api`) with method, path, input schema, and response schemas for each endpoint. Client hooks in `client/src/hooks/` consume these contracts directly, ensuring frontend-backend type alignment without code generation.

### Authentication Flow
- Login: POST `/api/login` with username/password → sets session cookie
- Session check: GET `/api/user` → returns current user or 401
- Logout: POST `/api/logout` → destroys session
- Protected routes use `requireAuth` middleware on the server and `PrivateRoute` wrapper on the client

### Build Process
- **Dev**: `tsx server/index.ts` with Vite middleware for HMR
- **Production Build**: Vite builds client to `dist/public/`, esbuild bundles server to `dist/index.cjs` with selective dependency bundling (allowlist pattern to reduce cold start syscalls)

### Key Design Decisions
1. **Shared schema and API contracts** — Single source of truth in `shared/` prevents frontend/backend drift
2. **MemoryStore for sessions** — Simple setup but not production-persistent; consider `connect-pg-simple` (already in dependencies) for PostgreSQL-backed sessions
3. **DatabaseStorage class implementing IStorage interface** — Clean abstraction over data access, making it easy to swap implementations
4. **Push-based migrations** — Uses `drizzle-kit push` instead of migration files for rapid development

## External Dependencies

### Required Services
- **PostgreSQL Database**: Must be provisioned and accessible via `DATABASE_URL` environment variable. Used for all persistent data (users, students, behaviors, notifications, messages).

### Key NPM Packages
- **drizzle-orm** + **drizzle-kit**: Database ORM and migration tooling
- **express** (v5): HTTP server framework
- **express-session** + **memorystore**: Session management (consider switching to `connect-pg-simple` for production)
- **zod** + **drizzle-zod**: Runtime validation and schema generation
- **@tanstack/react-query**: Server state management
- **recharts**: Data visualization
- **wouter**: Client-side routing
- **react-hook-form**: Form handling
- **shadcn/ui** (Radix UI + Tailwind): Component library

### Replit-Specific
- **@replit/vite-plugin-runtime-error-modal**: Error overlay in development
- **@replit/vite-plugin-cartographer** and **@replit/vite-plugin-dev-banner**: Dev-only Replit integrations (conditionally loaded)
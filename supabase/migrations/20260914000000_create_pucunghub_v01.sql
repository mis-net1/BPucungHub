-- ============================================================
-- PucungHub v0.1
-- Initial Database Schema Migration
--
-- Scope:
-- 8 tables only
-- No RLS
-- No triggers
-- No cron
-- No Edge Functions
-- No application features
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ============================================================
-- 1. PROFILES
-- Extends Supabase auth.users with studio profile information
-- ============================================================

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY
    REFERENCES auth.users(id)
    ON DELETE CASCADE,

  full_name text NOT NULL,
  email text,
  avatar_url text,

  role text NOT NULL
    CHECK (
      role IN (
        'ADMIN',
        'ART_DIRECTOR',
        'STAFF',
        'INTERN'
      )
    ),

  status text NOT NULL DEFAULT 'ACTIVE'
    CHECK (
      status IN (
        'ACTIVE',
        'INACTIVE'
      )
    ),

  phone text,
  division text,
  institution text,
  skills text,
  bio text,
  join_date date,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);


-- ============================================================
-- 2. PROJECTS
-- Project-level management
--
-- Project Manager and Art Director are assignments at
-- project level, not global user roles.
-- ============================================================

CREATE TABLE public.projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  name text NOT NULL,
  code text NOT NULL UNIQUE,
  description text,
  client_partner text,

  project_manager_id uuid
    REFERENCES public.profiles(id)
    ON DELETE SET NULL,

  art_director_id uuid
    REFERENCES public.profiles(id)
    ON DELETE SET NULL,

  status text NOT NULL DEFAULT 'PLANNING'
    CHECK (
      status IN (
        'PLANNING',
        'ACTIVE',
        'ON_HOLD',
        'COMPLETED',
        'ARCHIVED'
      )
    ),

  start_date date,
  deadline date,
  cover_url text,

  created_by uuid NOT NULL
    REFERENCES public.profiles(id)
    ON DELETE RESTRICT,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);


-- ============================================================
-- 3. TASKS
-- Individual work items inside a project
-- ============================================================

CREATE TABLE public.tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  project_id uuid NOT NULL
    REFERENCES public.projects(id)
    ON DELETE CASCADE,

  title text NOT NULL,
  description text,

  assignee_id uuid
    REFERENCES public.profiles(id)
    ON DELETE SET NULL,

  created_by uuid NOT NULL
    REFERENCES public.profiles(id)
    ON DELETE RESTRICT,

  priority text NOT NULL DEFAULT 'MEDIUM'
    CHECK (
      priority IN (
        'LOW',
        'MEDIUM',
        'HIGH',
        'URGENT'
      )
    ),

  status text NOT NULL DEFAULT 'BACKLOG'
    CHECK (
      status IN (
        'BACKLOG',
        'TODO',
        'IN_PROGRESS',
        'SUBMITTED',
        'REVIEW',
        'REVISION',
        'APPROVED',
        'CANCELLED'
      )
    ),

  deadline timestamptz,

  -- One reference attachment for the task itself.
  -- Submission files are stored separately in task_submissions.
  attachment_url text,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);


-- ============================================================
-- 4. TASK SUBMISSIONS
-- Versioned task submissions from staff/intern
-- ============================================================

CREATE TABLE public.task_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  task_id uuid NOT NULL
    REFERENCES public.tasks(id)
    ON DELETE CASCADE,

  submitted_by uuid NOT NULL
    REFERENCES public.profiles(id)
    ON DELETE RESTRICT,

  submission_note text,
  file_url text,
  external_url text,

  version integer NOT NULL
    CHECK (version > 0),

  submitted_at timestamptz NOT NULL DEFAULT now(),

  UNIQUE (task_id, version)
);


-- ============================================================
-- 5. TASK REVIEWS
-- Review result for a submitted task version
-- ============================================================

CREATE TABLE public.task_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  submission_id uuid NOT NULL
    REFERENCES public.task_submissions(id)
    ON DELETE CASCADE,

  reviewer_id uuid NOT NULL
    REFERENCES public.profiles(id)
    ON DELETE RESTRICT,

  status text NOT NULL
    CHECK (
      status IN (
        'APPROVED',
        'REVISION'
      )
    ),

  feedback text,

  created_at timestamptz NOT NULL DEFAULT now()
);


-- ============================================================
-- 6. ATTENDANCE
-- Onsite / WFH attendance records
-- GPS is stored as supporting evidence, not absolute security.
-- ============================================================

CREATE TABLE public.attendance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  user_id uuid NOT NULL
    REFERENCES public.profiles(id)
    ON DELETE CASCADE,

  date date NOT NULL DEFAULT CURRENT_DATE,

  check_in timestamptz,
  check_out timestamptz,

  latitude numeric(10, 7),
  longitude numeric(10, 7),

  -- Distance from studio coordinate in meters.
  distance numeric(10, 2),

  attendance_type text NOT NULL
    CHECK (
      attendance_type IN (
        'ONSITE',
        'WFH'
      )
    ),

  status text NOT NULL
    CHECK (
      status IN (
        'PRESENT',
        'LATE',
        'WFH',
        'ABSENT'
      )
    ),

  note text,

  -- Optional WFH / attendance evidence.
  evidence_url text,

  -- Optional browser/device information.
  device_info jsonb,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  -- One attendance record per user per date.
  UNIQUE (user_id, date)
);


-- ============================================================
-- 7. ATTENDANCE SETTINGS
-- Studio GPS and attendance configuration
-- ============================================================

CREATE TABLE public.attendance_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  studio_name text NOT NULL DEFAULT 'Bapak Pucung Studio',

  latitude numeric(10, 7) NOT NULL,
  longitude numeric(10, 7) NOT NULL,

  -- Maximum allowed distance from studio coordinate.
  allowed_radius integer NOT NULL DEFAULT 100
    CHECK (allowed_radius > 0),

  check_in_start time,
  check_in_end time,

  check_out_start time,
  check_out_end time,

  updated_by uuid
    REFERENCES public.profiles(id)
    ON DELETE SET NULL,

  updated_at timestamptz NOT NULL DEFAULT now()
);


-- ============================================================
-- 8. NOTIFICATIONS
-- In-app notifications
-- ============================================================

CREATE TABLE public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  user_id uuid NOT NULL
    REFERENCES public.profiles(id)
    ON DELETE CASCADE,

  title text NOT NULL,
  message text NOT NULL,

  type text NOT NULL
    CHECK (
      type IN (
        'TASK',
        'SUBMISSION',
        'REVIEW',
        'ATTENDANCE',
        'PROJECT',
        'SYSTEM'
      )
    ),

  is_read boolean NOT NULL DEFAULT false,

  created_at timestamptz NOT NULL DEFAULT now()
);


-- ============================================================
-- INDEXES
-- ============================================================

-- Projects
CREATE INDEX idx_projects_project_manager_id
  ON public.projects(project_manager_id);

CREATE INDEX idx_projects_art_director_id
  ON public.projects(art_director_id);

CREATE INDEX idx_projects_created_by
  ON public.projects(created_by);

CREATE INDEX idx_projects_status
  ON public.projects(status);


-- Tasks
CREATE INDEX idx_tasks_project_id
  ON public.tasks(project_id);

CREATE INDEX idx_tasks_assignee_id
  ON public.tasks(assignee_id);

CREATE INDEX idx_tasks_created_by
  ON public.tasks(created_by);

CREATE INDEX idx_tasks_status
  ON public.tasks(status);

CREATE INDEX idx_tasks_deadline
  ON public.tasks(deadline);


-- Task submissions
CREATE INDEX idx_task_submissions_task_id
  ON public.task_submissions(task_id);

CREATE INDEX idx_task_submissions_submitted_by
  ON public.task_submissions(submitted_by);


-- Task reviews
CREATE INDEX idx_task_reviews_submission_id
  ON public.task_reviews(submission_id);

CREATE INDEX idx_task_reviews_reviewer_id
  ON public.task_reviews(reviewer_id);


-- Attendance
CREATE INDEX idx_attendance_user_id
  ON public.attendance(user_id);

CREATE INDEX idx_attendance_date
  ON public.attendance(date);

CREATE INDEX idx_attendance_type
  ON public.attendance(attendance_type);


-- Notifications
CREATE INDEX idx_notifications_user_id
  ON public.notifications(user_id);

CREATE INDEX idx_notifications_created_at
  ON public.notifications(created_at);

CREATE INDEX idx_notifications_unread
  ON public.notifications(user_id, is_read);


-- ============================================================
-- SINGLE ATTENDANCE SETTINGS RECORD
-- Only one configuration row is allowed.
-- ============================================================

CREATE UNIQUE INDEX idx_attendance_settings_single_row
  ON public.attendance_settings ((true));
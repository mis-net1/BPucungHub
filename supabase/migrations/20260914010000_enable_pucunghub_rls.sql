-- ============================================================
-- PucungHub v0.1
-- Row Level Security
--
-- Scope:
-- Enable RLS and create access policies for the 8 core tables.
--
-- No application features.
-- No cron.
-- No Edge Functions.
-- ============================================================


-- ============================================================
-- HELPER: GET CURRENT USER ROLE
--
-- SECURITY DEFINER prevents RLS recursion when policies need
-- to check the current user's role from public.profiles.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role
  FROM public.profiles
  WHERE id = auth.uid()
  LIMIT 1;
$$;


-- ============================================================
-- ENABLE RLS
-- ============================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- 1. PROFILES
-- ============================================================

-- Authenticated users can view studio profiles.
CREATE POLICY "profiles_select_authenticated"
ON public.profiles
FOR SELECT
TO authenticated
USING (true);


-- Users can update their own basic profile.
-- Role/status changes are intentionally handled separately
-- by administrators/server-side processes.
CREATE POLICY "profiles_update_own"
ON public.profiles
FOR UPDATE
TO authenticated
USING (
  id = auth.uid()
)
WITH CHECK (
  id = auth.uid()
);


-- Admin can update any profile.
CREATE POLICY "profiles_update_admin"
ON public.profiles
FOR UPDATE
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
)
WITH CHECK (
  public.get_my_role() = 'ADMIN'
);


-- ============================================================
-- 2. PROJECTS
-- ============================================================

-- Admin can see all projects.
CREATE POLICY "projects_select_admin"
ON public.projects
FOR SELECT
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
);


-- Art Director can see projects assigned to them.
CREATE POLICY "projects_select_art_director"
ON public.projects
FOR SELECT
TO authenticated
USING (
  public.get_my_role() = 'ART_DIRECTOR'
  AND art_director_id = auth.uid()
);


-- Project Manager can see projects assigned to them.
CREATE POLICY "projects_select_project_manager"
ON public.projects
FOR SELECT
TO authenticated
USING (
  project_manager_id = auth.uid()
);


-- Staff and Intern can see projects that contain one of
-- their assigned tasks.
CREATE POLICY "projects_select_task_assignee"
ON public.projects
FOR SELECT
TO authenticated
USING (
  public.get_my_role() IN ('STAFF', 'INTERN')
  AND EXISTS (
    SELECT 1
    FROM public.tasks
    WHERE tasks.project_id = projects.id
      AND tasks.assignee_id = auth.uid()
  )
);


-- Admin can create projects.
CREATE POLICY "projects_insert_admin"
ON public.projects
FOR INSERT
TO authenticated
WITH CHECK (
  public.get_my_role() = 'ADMIN'
);


-- Admin can update projects.
CREATE POLICY "projects_update_admin"
ON public.projects
FOR UPDATE
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
)
WITH CHECK (
  public.get_my_role() = 'ADMIN'
);


-- Art Director can update projects assigned to them.
CREATE POLICY "projects_update_art_director"
ON public.projects
FOR UPDATE
TO authenticated
USING (
  public.get_my_role() = 'ART_DIRECTOR'
  AND art_director_id = auth.uid()
)
WITH CHECK (
  public.get_my_role() = 'ART_DIRECTOR'
  AND art_director_id = auth.uid()
);


-- Project Manager can update projects assigned to them.
CREATE POLICY "projects_update_project_manager"
ON public.projects
FOR UPDATE
TO authenticated
USING (
  project_manager_id = auth.uid()
)
WITH CHECK (
  project_manager_id = auth.uid()
);


-- Only Admin can delete projects.
CREATE POLICY "projects_delete_admin"
ON public.projects
FOR DELETE
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
);


-- ============================================================
-- 3. TASKS
-- ============================================================

-- Admin sees all tasks.
CREATE POLICY "tasks_select_admin"
ON public.tasks
FOR SELECT
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
);


-- Art Director sees tasks in projects assigned to them.
CREATE POLICY "tasks_select_art_director"
ON public.tasks
FOR SELECT
TO authenticated
USING (
  public.get_my_role() = 'ART_DIRECTOR'
  AND EXISTS (
    SELECT 1
    FROM public.projects
    WHERE projects.id = tasks.project_id
      AND projects.art_director_id = auth.uid()
  )
);


-- Project Manager sees tasks in projects assigned to them.
CREATE POLICY "tasks_select_project_manager"
ON public.tasks
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.projects
    WHERE projects.id = tasks.project_id
      AND projects.project_manager_id = auth.uid()
  )
);


-- Staff and Intern see their own assigned tasks.
CREATE POLICY "tasks_select_assignee"
ON public.tasks
FOR SELECT
TO authenticated
USING (
  assignee_id = auth.uid()
);


-- Admin can create tasks.
CREATE POLICY "tasks_insert_admin"
ON public.tasks
FOR INSERT
TO authenticated
WITH CHECK (
  public.get_my_role() = 'ADMIN'
);


-- Art Director can create tasks in their projects.
CREATE POLICY "tasks_insert_art_director"
ON public.tasks
FOR INSERT
TO authenticated
WITH CHECK (
  public.get_my_role() = 'ART_DIRECTOR'
  AND EXISTS (
    SELECT 1
    FROM public.projects
    WHERE projects.id = project_id
      AND projects.art_director_id = auth.uid()
  )
);


-- Project Manager can create tasks in their projects.
CREATE POLICY "tasks_insert_project_manager"
ON public.tasks
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.projects
    WHERE projects.id = project_id
      AND projects.project_manager_id = auth.uid()
  )
);


-- Admin can update any task.
CREATE POLICY "tasks_update_admin"
ON public.tasks
FOR UPDATE
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
)
WITH CHECK (
  public.get_my_role() = 'ADMIN'
);


-- Art Director can update tasks in their projects.
CREATE POLICY "tasks_update_art_director"
ON public.tasks
FOR UPDATE
TO authenticated
USING (
  public.get_my_role() = 'ART_DIRECTOR'
  AND EXISTS (
    SELECT 1
    FROM public.projects
    WHERE projects.id = project_id
      AND projects.art_director_id = auth.uid()
  )
)
WITH CHECK (
  public.get_my_role() = 'ART_DIRECTOR'
  AND EXISTS (
    SELECT 1
    FROM public.projects
    WHERE projects.id = project_id
      AND projects.art_director_id = auth.uid()
  )
);


-- Assignees can update their own assigned tasks.
-- This allows progress/status updates.
CREATE POLICY "tasks_update_assignee"
ON public.tasks
FOR UPDATE
TO authenticated
USING (
  assignee_id = auth.uid()
)
WITH CHECK (
  assignee_id = auth.uid()
);


-- Only Admin can delete tasks.
CREATE POLICY "tasks_delete_admin"
ON public.tasks
FOR DELETE
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
);


-- ============================================================
-- 4. TASK SUBMISSIONS
-- ============================================================

-- Admin can see all submissions.
CREATE POLICY "submissions_select_admin"
ON public.task_submissions
FOR SELECT
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
);


-- User can see their own submissions.
CREATE POLICY "submissions_select_own"
ON public.task_submissions
FOR SELECT
TO authenticated
USING (
  submitted_by = auth.uid()
);


-- Project Manager / Art Director can see submissions
-- belonging to tasks in their projects.
CREATE POLICY "submissions_select_manager"
ON public.task_submissions
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.tasks
    JOIN public.projects
      ON projects.id = tasks.project_id
    WHERE tasks.id = task_id
      AND (
        projects.project_manager_id = auth.uid()
        OR projects.art_director_id = auth.uid()
      )
  )
);


-- Users can create their own submissions.
CREATE POLICY "submissions_insert_own"
ON public.task_submissions
FOR INSERT
TO authenticated
WITH CHECK (
  submitted_by = auth.uid()
);


-- Admin can delete submissions.
CREATE POLICY "submissions_delete_admin"
ON public.task_submissions
FOR DELETE
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
);


-- ============================================================
-- 5. TASK REVIEWS
-- ============================================================

-- Admin can see all reviews.
CREATE POLICY "reviews_select_admin"
ON public.task_reviews
FOR SELECT
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
);


-- Reviewers can see reviews they created.
CREATE POLICY "reviews_select_own"
ON public.task_reviews
FOR SELECT
TO authenticated
USING (
  reviewer_id = auth.uid()
);


-- Submitters can see reviews for their submissions.
CREATE POLICY "reviews_select_submitter"
ON public.task_reviews
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.task_submissions
    WHERE task_submissions.id = submission_id
      AND task_submissions.submitted_by = auth.uid()
  )
);


-- Art Director / Project Manager can create reviews
-- for submissions in their projects.
CREATE POLICY "reviews_insert_manager"
ON public.task_reviews
FOR INSERT
TO authenticated
WITH CHECK (
  (
    public.get_my_role() = 'ART_DIRECTOR'
    OR EXISTS (
      SELECT 1
      FROM public.projects
      JOIN public.tasks
        ON tasks.project_id = projects.id
      JOIN public.task_submissions
        ON task_submissions.task_id = tasks.id
      WHERE task_submissions.id = submission_id
        AND projects.art_director_id = auth.uid()
    )
  )
  OR EXISTS (
    SELECT 1
    FROM public.projects
    JOIN public.tasks
      ON tasks.project_id = projects.id
    JOIN public.task_submissions
      ON task_submissions.task_id = tasks.id
    WHERE task_submissions.id = submission_id
      AND projects.project_manager_id = auth.uid()
  )
);


-- Admin can update/delete reviews.
CREATE POLICY "reviews_update_admin"
ON public.task_reviews
FOR UPDATE
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
)
WITH CHECK (
  public.get_my_role() = 'ADMIN'
);

CREATE POLICY "reviews_delete_admin"
ON public.task_reviews
FOR DELETE
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
);


-- ============================================================
-- 6. ATTENDANCE
-- ============================================================

-- Admin sees all attendance.
CREATE POLICY "attendance_select_admin"
ON public.attendance
FOR SELECT
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
);


-- Users see their own attendance.
CREATE POLICY "attendance_select_own"
ON public.attendance
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
);


-- Admin can create attendance records.
CREATE POLICY "attendance_insert_admin"
ON public.attendance
FOR INSERT
TO authenticated
WITH CHECK (
  public.get_my_role() = 'ADMIN'
);


-- Users can create their own attendance.
CREATE POLICY "attendance_insert_own"
ON public.attendance
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid()
);


-- Admin can update attendance.
CREATE POLICY "attendance_update_admin"
ON public.attendance
FOR UPDATE
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
)
WITH CHECK (
  public.get_my_role() = 'ADMIN'
);


-- Users can update their own attendance.
CREATE POLICY "attendance_update_own"
ON public.attendance
FOR UPDATE
TO authenticated
USING (
  user_id = auth.uid()
)
WITH CHECK (
  user_id = auth.uid()
);


-- Only Admin can delete attendance.
CREATE POLICY "attendance_delete_admin"
ON public.attendance
FOR DELETE
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
);


-- ============================================================
-- 7. ATTENDANCE SETTINGS
-- ============================================================

-- Authenticated users can read studio attendance settings.
CREATE POLICY "attendance_settings_select_authenticated"
ON public.attendance_settings
FOR SELECT
TO authenticated
USING (true);


-- Only Admin can create settings.
CREATE POLICY "attendance_settings_insert_admin"
ON public.attendance_settings
FOR INSERT
TO authenticated
WITH CHECK (
  public.get_my_role() = 'ADMIN'
);


-- Only Admin can update settings.
CREATE POLICY "attendance_settings_update_admin"
ON public.attendance_settings
FOR UPDATE
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
)
WITH CHECK (
  public.get_my_role() = 'ADMIN'
);


-- Only Admin can delete settings.
CREATE POLICY "attendance_settings_delete_admin"
ON public.attendance_settings
FOR DELETE
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
);


-- ============================================================
-- 8. NOTIFICATIONS
-- ============================================================

-- Admin can see all notifications.
CREATE POLICY "notifications_select_admin"
ON public.notifications
FOR SELECT
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
);


-- Users can see their own notifications.
CREATE POLICY "notifications_select_own"
ON public.notifications
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
);


-- Admin can create notifications.
CREATE POLICY "notifications_insert_admin"
ON public.notifications
FOR INSERT
TO authenticated
WITH CHECK (
  public.get_my_role() = 'ADMIN'
);


-- Users can mark their own notifications as read.
CREATE POLICY "notifications_update_own"
ON public.notifications
FOR UPDATE
TO authenticated
USING (
  user_id = auth.uid()
)
WITH CHECK (
  user_id = auth.uid()
);


-- Admin can update any notification.
CREATE POLICY "notifications_update_admin"
ON public.notifications
FOR UPDATE
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
)
WITH CHECK (
  public.get_my_role() = 'ADMIN'
);


-- Only Admin can delete notifications.
CREATE POLICY "notifications_delete_admin"
ON public.notifications
FOR DELETE
TO authenticated
USING (
  public.get_my_role() = 'ADMIN'
);
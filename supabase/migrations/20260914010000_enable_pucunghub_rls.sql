-- ============================================================
-- PucungHub v0.1
-- Row Level Security
-- ============================================================

-- ============================================================
-- PRIVATE HELPER FUNCTIONS
-- ============================================================

CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION private.my_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT p.role
  FROM public.profiles AS p
  WHERE p.id = (SELECT auth.uid())
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION private.my_status()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT p.status
  FROM public.profiles AS p
  WHERE p.id = (SELECT auth.uid())
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION private.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT COALESCE((SELECT private.my_role()) = 'ADMIN', false);
$$;

CREATE OR REPLACE FUNCTION private.can_access_project(project_uuid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.projects AS p
    WHERE p.id = project_uuid
      AND (
        p.project_manager_id = (SELECT auth.uid())
        OR p.art_director_id = (SELECT auth.uid())
        OR (SELECT private.is_admin())
        OR EXISTS (
          SELECT 1
          FROM public.tasks AS t
          WHERE t.project_id = p.id
            AND t.assignee_id = (SELECT auth.uid())
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION private.can_access_task(task_uuid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.tasks AS t
    JOIN public.projects AS p
      ON p.id = t.project_id
    WHERE t.id = task_uuid
      AND (
        t.assignee_id = (SELECT auth.uid())
        OR p.project_manager_id = (SELECT auth.uid())
        OR p.art_director_id = (SELECT auth.uid())
        OR (SELECT private.is_admin())
      )
  );
$$;

CREATE OR REPLACE FUNCTION private.can_access_submission(submission_uuid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.task_submissions AS s
    JOIN public.tasks AS t
      ON t.id = s.task_id
    JOIN public.projects AS p
      ON p.id = t.project_id
    WHERE s.id = submission_uuid
      AND (
        s.submitted_by = (SELECT auth.uid())
        OR p.project_manager_id = (SELECT auth.uid())
        OR p.art_director_id = (SELECT auth.uid())
        OR (SELECT private.is_admin())
      )
  );
$$;

CREATE OR REPLACE FUNCTION private.can_review_submission(submission_uuid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.task_submissions AS s
    JOIN public.tasks AS t
      ON t.id = s.task_id
    JOIN public.projects AS p
      ON p.id = t.project_id
    WHERE s.id = submission_uuid
      AND (
        p.project_manager_id = (SELECT auth.uid())
        OR p.art_director_id = (SELECT auth.uid())
        OR (SELECT private.is_admin())
      )
  );
$$;


-- Only authenticated users may call these helpers.
REVOKE ALL ON FUNCTION private.my_role() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.my_status() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.is_admin() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.can_access_project(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.can_access_task(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.can_access_submission(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.can_review_submission(uuid) FROM PUBLIC;

GRANT USAGE ON SCHEMA private TO authenticated;

GRANT EXECUTE ON FUNCTION private.my_role() TO authenticated;
GRANT EXECUTE ON FUNCTION private.my_status() TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_access_project(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_access_task(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_access_submission(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_review_submission(uuid) TO authenticated;


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
-- REMOVE CLIENT ACCESS FOR ANONYMOUS USERS
-- ============================================================

REVOKE ALL ON TABLE public.profiles FROM anon;
REVOKE ALL ON TABLE public.projects FROM anon;
REVOKE ALL ON TABLE public.tasks FROM anon;
REVOKE ALL ON TABLE public.task_submissions FROM anon;
REVOKE ALL ON TABLE public.task_reviews FROM anon;
REVOKE ALL ON TABLE public.attendance FROM anon;
REVOKE ALL ON TABLE public.attendance_settings FROM anon;
REVOKE ALL ON TABLE public.notifications FROM anon;


-- Authenticated application access.
GRANT SELECT, INSERT, UPDATE, DELETE
ON public.profiles,
   public.projects,
   public.tasks,
   public.task_submissions,
   public.task_reviews,
   public.attendance,
   public.attendance_settings,
   public.notifications
TO authenticated;


-- ============================================================
-- PROFILES
-- ============================================================

CREATE POLICY "profiles_select_authenticated"
ON public.profiles
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "profiles_update_own"
ON public.profiles
FOR UPDATE
TO authenticated
USING (
  id = (SELECT auth.uid())
)
WITH CHECK (
  id = (SELECT auth.uid())
  AND role = (SELECT private.my_role())
  AND status = (SELECT private.my_status())
);

CREATE POLICY "profiles_update_admin"
ON public.profiles
FOR UPDATE
TO authenticated
USING (
  (SELECT private.is_admin())
)
WITH CHECK (
  (SELECT private.is_admin())
);


-- ============================================================
-- PROJECTS
-- ============================================================

CREATE POLICY "projects_select"
ON public.projects
FOR SELECT
TO authenticated
USING (
  (SELECT private.can_access_project(id))
);

CREATE POLICY "projects_insert_admin"
ON public.projects
FOR INSERT
TO authenticated
WITH CHECK (
  (SELECT private.is_admin())
);

CREATE POLICY "projects_update"
ON public.projects
FOR UPDATE
TO authenticated
USING (
  (SELECT private.is_admin())
  OR project_manager_id = (SELECT auth.uid())
  OR art_director_id = (SELECT auth.uid())
)
WITH CHECK (
  (SELECT private.is_admin())
  OR project_manager_id = (SELECT auth.uid())
  OR art_director_id = (SELECT auth.uid())
);

CREATE POLICY "projects_delete_admin"
ON public.projects
FOR DELETE
TO authenticated
USING (
  (SELECT private.is_admin())
);


-- ============================================================
-- TASKS
-- ============================================================

CREATE POLICY "tasks_select"
ON public.tasks
FOR SELECT
TO authenticated
USING (
  (SELECT private.can_access_task(id))
);

CREATE POLICY "tasks_insert"
ON public.tasks
FOR INSERT
TO authenticated
WITH CHECK (
  (SELECT private.is_admin())
  OR EXISTS (
    SELECT 1
    FROM public.projects AS p
    WHERE p.id = project_id
      AND (
        p.project_manager_id = (SELECT auth.uid())
        OR p.art_director_id = (SELECT auth.uid())
      )
  )
);

CREATE POLICY "tasks_update"
ON public.tasks
FOR UPDATE
TO authenticated
USING (
  (SELECT private.can_access_task(id))
)
WITH CHECK (
  (SELECT private.can_access_task(id))
);

CREATE POLICY "tasks_delete_admin"
ON public.tasks
FOR DELETE
TO authenticated
USING (
  (SELECT private.is_admin())
);


-- ============================================================
-- TASK SUBMISSIONS
-- ============================================================

CREATE POLICY "submissions_select"
ON public.task_submissions
FOR SELECT
TO authenticated
USING (
  (SELECT private.can_access_submission(id))
);

CREATE POLICY "submissions_insert_own"
ON public.task_submissions
FOR INSERT
TO authenticated
WITH CHECK (
  submitted_by = (SELECT auth.uid())
  AND (SELECT private.can_access_task(task_id))
);

CREATE POLICY "submissions_delete_admin"
ON public.task_submissions
FOR DELETE
TO authenticated
USING (
  (SELECT private.is_admin())
);


-- ============================================================
-- TASK REVIEWS
-- ============================================================

CREATE POLICY "reviews_select"
ON public.task_reviews
FOR SELECT
TO authenticated
USING (
  reviewer_id = (SELECT auth.uid())
  OR (SELECT private.is_admin())
  OR EXISTS (
    SELECT 1
    FROM public.task_submissions AS s
    WHERE s.id = submission_id
      AND s.submitted_by = (SELECT auth.uid())
  )
);

CREATE POLICY "reviews_insert"
ON public.task_reviews
FOR INSERT
TO authenticated
WITH CHECK (
  (SELECT private.can_review_submission(submission_id))
  AND reviewer_id = (SELECT auth.uid())
);

CREATE POLICY "reviews_update_admin"
ON public.task_reviews
FOR UPDATE
TO authenticated
USING (
  (SELECT private.is_admin())
)
WITH CHECK (
  (SELECT private.is_admin())
);

CREATE POLICY "reviews_delete_admin"
ON public.task_reviews
FOR DELETE
TO authenticated
USING (
  (SELECT private.is_admin())
);


-- ============================================================
-- ATTENDANCE
-- ============================================================

CREATE POLICY "attendance_select"
ON public.attendance
FOR SELECT
TO authenticated
USING (
  user_id = (SELECT auth.uid())
  OR (SELECT private.is_admin())
);

CREATE POLICY "attendance_insert"
ON public.attendance
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = (SELECT auth.uid())
  OR (SELECT private.is_admin())
);

CREATE POLICY "attendance_update"
ON public.attendance
FOR UPDATE
TO authenticated
USING (
  user_id = (SELECT auth.uid())
  OR (SELECT private.is_admin())
)
WITH CHECK (
  user_id = (SELECT auth.uid())
  OR (SELECT private.is_admin())
);

CREATE POLICY "attendance_delete_admin"
ON public.attendance
FOR DELETE
TO authenticated
USING (
  (SELECT private.is_admin())
);


-- ============================================================
-- ATTENDANCE SETTINGS
-- ============================================================

CREATE POLICY "attendance_settings_select"
ON public.attendance_settings
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "attendance_settings_insert_admin"
ON public.attendance_settings
FOR INSERT
TO authenticated
WITH CHECK (
  (SELECT private.is_admin())
);

CREATE POLICY "attendance_settings_update_admin"
ON public.attendance_settings
FOR UPDATE
TO authenticated
USING (
  (SELECT private.is_admin())
)
WITH CHECK (
  (SELECT private.is_admin())
);

CREATE POLICY "attendance_settings_delete_admin"
ON public.attendance_settings
FOR DELETE
TO authenticated
USING (
  (SELECT private.is_admin())
);


-- ============================================================
-- NOTIFICATIONS
-- ============================================================

CREATE POLICY "notifications_select"
ON public.notifications
FOR SELECT
TO authenticated
USING (
  user_id = (SELECT auth.uid())
  OR (SELECT private.is_admin())
);

CREATE POLICY "notifications_insert_admin"
ON public.notifications
FOR INSERT
TO authenticated
WITH CHECK (
  (SELECT private.is_admin())
);

CREATE POLICY "notifications_update"
ON public.notifications
FOR UPDATE
TO authenticated
USING (
  user_id = (SELECT auth.uid())
  OR (SELECT private.is_admin())
)
WITH CHECK (
  user_id = (SELECT auth.uid())
  OR (SELECT private.is_admin())
);

CREATE POLICY "notifications_delete_admin"
ON public.notifications
FOR DELETE
TO authenticated
USING (
  (SELECT private.is_admin())
);


-- ============================================================
-- POLICY SUPPORTING INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_profiles_role
  ON public.profiles(role);

CREATE INDEX IF NOT EXISTS idx_profiles_status
  ON public.profiles(status);

CREATE INDEX IF NOT EXISTS idx_projects_pm
  ON public.projects(project_manager_id);

CREATE INDEX IF NOT EXISTS idx_projects_ad
  ON public.projects(art_director_id);

CREATE INDEX IF NOT EXISTS idx_tasks_assignee
  ON public.tasks(assignee_id);

CREATE INDEX IF NOT EXISTS idx_attendance_user_date
  ON public.attendance(user_id, date);

CREATE INDEX IF NOT EXISTS idx_notifications_user_read
  ON public.notifications(user_id, is_read);
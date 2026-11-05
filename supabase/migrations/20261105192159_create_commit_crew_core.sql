/*
# Create COMMIT/CREW core placement data

1. New Tables
- `admin_profiles`: authenticated administrator identity and role.
- `students`: student registry, eligibility, contact, placement status, and profile details.
- `companies`: company registration and placement opportunity information.
- `placement_schedules`: interview and placement events with timing, venue, and eligibility rules.
- `placement_applications`: links students to companies and their interview/selection progress.
- `company_documents`: private document metadata associated with a company.
- `legal_registration_records`: internal tracker for a proposed business registration.
- `registration_checklists`: checklist items attached to a legal registration tracker record.

2. Security
- Every table is protected with row-level security.
- All records are scoped to the authenticated administrator who created them.
- The browser receives only authenticated CRUD privileges for user-owned records.
- Verification, role, and audit timestamps are not client-controlled where possible.
- A private `company-documents` storage bucket is created with owner-folder policies.

3. Important Notes
- This application stores placement and internal tracking records; it does not submit legal registrations to MCA.
- The auth trigger creates an administrator profile for new accounts so the first signed-in workspace is usable.
*/

CREATE TABLE IF NOT EXISTS public.admin_profiles (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text NOT NULL DEFAULT 'Nagaraj K H',
  role text NOT NULL DEFAULT 'administrator' CHECK (role IN ('administrator', 'coordinator', 'viewer')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.students (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  usn text NOT NULL,
  college_email text NOT NULL,
  phone text,
  branch text NOT NULL,
  year text,
  semester text,
  cgpa numeric(4,2) NOT NULL CHECK (cgpa >= 0 AND cgpa <= 10),
  technical_skills text[] NOT NULL DEFAULT '{}',
  certifications text[] NOT NULL DEFAULT '{}',
  resume_path text,
  placement_status text NOT NULL DEFAULT 'Available' CHECK (placement_status IN ('Available', 'Shortlisted', 'Interviewing', 'Placed', 'Not Eligible')),
  company_selected text,
  interview_history jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, usn)
);

CREATE TABLE IF NOT EXISTS public.companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  logo_path text,
  company_type text NOT NULL DEFAULT 'Other',
  industry text,
  website text,
  description text,
  year_established integer,
  hr_name text,
  official_email text,
  contact_number text,
  registered_office_address text,
  city text,
  state text,
  pin_code text,
  country text NOT NULL DEFAULT 'India',
  job_roles text[] NOT NULL DEFAULT '{}',
  required_branches text[] NOT NULL DEFAULT '{}',
  required_skills text[] NOT NULL DEFAULT '{}',
  minimum_cgpa numeric(4,2),
  vacancies integer NOT NULL DEFAULT 0 CHECK (vacancies >= 0),
  job_location text,
  salary_package text,
  internship_opportunities text,
  selection_process text,
  placement_drive_date date,
  cin_llpin text,
  pan text,
  gstin text,
  verification_status text NOT NULL DEFAULT 'Pending' CHECK (verification_status IN ('Pending', 'Verified', 'Rejected')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, name)
);

CREATE TABLE IF NOT EXISTS public.placement_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  event_title text NOT NULL,
  company_id uuid REFERENCES public.companies(id) ON DELETE SET NULL,
  company_name text NOT NULL,
  category text NOT NULL DEFAULT 'Interview',
  event_date date NOT NULL,
  start_time time NOT NULL,
  end_time time NOT NULL,
  venue text,
  meeting_link text,
  eligible_branches text[] NOT NULL DEFAULT '{}',
  minimum_cgpa numeric(4,2),
  eligible_students integer NOT NULL DEFAULT 0 CHECK (eligible_students >= 0),
  registration_deadline date,
  description text,
  status text NOT NULL DEFAULT 'Upcoming' CHECK (status IN ('Upcoming', 'Live', 'Completed', 'Cancelled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (end_time > start_time)
);

CREATE TABLE IF NOT EXISTS public.placement_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  schedule_id uuid REFERENCES public.placement_schedules(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'Applied' CHECK (status IN ('Applied', 'Shortlisted', 'Interviewing', 'Selected', 'Rejected')),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (student_id, company_id)
);

CREATE TABLE IF NOT EXISTS public.company_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  document_type text NOT NULL,
  file_name text NOT NULL,
  storage_path text NOT NULL,
  content_type text,
  file_size bigint,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.legal_registration_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  proposed_company_name text NOT NULL,
  business_structure text NOT NULL,
  business_activity text,
  state text,
  founder_count integer NOT NULL DEFAULT 1 CHECK (founder_count > 0),
  founder_details jsonb NOT NULL DEFAULT '[]'::jsonb,
  registered_office_address text,
  application_date date,
  mca_application_number text,
  current_status text NOT NULL DEFAULT 'Planning' CHECK (current_status IN ('Planning', 'Documents Pending', 'Documents Ready', 'Application Submitted', 'Under Review', 'Resubmission Required', 'Approved', 'Registration Completed')),
  certificate_details jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.registration_checklists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  registration_id uuid NOT NULL REFERENCES public.legal_registration_records(id) ON DELETE CASCADE,
  category text NOT NULL,
  label text NOT NULL,
  completed boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (registration_id, label)
);

CREATE INDEX IF NOT EXISTS students_user_branch_idx ON public.students(user_id, branch);
CREATE INDEX IF NOT EXISTS companies_user_status_idx ON public.companies(user_id, verification_status);
CREATE INDEX IF NOT EXISTS schedules_user_date_idx ON public.placement_schedules(user_id, event_date);
CREATE INDEX IF NOT EXISTS applications_user_status_idx ON public.placement_applications(user_id, status);
CREATE INDEX IF NOT EXISTS documents_company_idx ON public.company_documents(company_id);
CREATE INDEX IF NOT EXISTS registration_user_status_idx ON public.legal_registration_records(user_id, current_status);

CREATE OR REPLACE FUNCTION public.handle_new_admin_profile()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.admin_profiles (user_id, display_name)
  VALUES (new.id, COALESCE(new.raw_user_meta_data ->> 'display_name', 'Nagaraj K H'))
  ON CONFLICT (user_id) DO NOTHING;
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_commit_crew ON auth.users;
CREATE TRIGGER on_auth_user_created_commit_crew
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_admin_profile();

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('company-documents', 'company-documents', false, 10485760, ARRAY['application/pdf', 'image/png', 'image/jpeg', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.admin_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.placement_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.placement_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.legal_registration_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registration_checklists ENABLE ROW LEVEL SECURITY;

GRANT SELECT, UPDATE ON public.admin_profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.students, public.companies, public.placement_schedules, public.placement_applications, public.company_documents, public.legal_registration_records, public.registration_checklists TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_admin_profile() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_new_admin_profile() FROM anon;

DROP POLICY IF EXISTS "admin_profiles_select_own" ON public.admin_profiles;
CREATE POLICY "admin_profiles_select_own" ON public.admin_profiles FOR SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "admin_profiles_update_own" ON public.admin_profiles;
CREATE POLICY "admin_profiles_update_own" ON public.admin_profiles FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DO $$
DECLARE table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY['students','companies','placement_schedules','placement_applications','company_documents','legal_registration_records','registration_checklists'] LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I_select_own ON public.%I', table_name, table_name);
    EXECUTE format('CREATE POLICY %I_select_own ON public.%I FOR SELECT TO authenticated USING (auth.uid() = user_id)', table_name, table_name);
    EXECUTE format('DROP POLICY IF EXISTS %I_insert_own ON public.%I', table_name, table_name);
    EXECUTE format('CREATE POLICY %I_insert_own ON public.%I FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id)', table_name, table_name);
    EXECUTE format('DROP POLICY IF EXISTS %I_update_own ON public.%I', table_name, table_name);
    EXECUTE format('CREATE POLICY %I_update_own ON public.%I FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id)', table_name, table_name);
    EXECUTE format('DROP POLICY IF EXISTS %I_delete_own ON public.%I', table_name, table_name);
    EXECUTE format('CREATE POLICY %I_delete_own ON public.%I FOR DELETE TO authenticated USING (auth.uid() = user_id)', table_name, table_name);
  END LOOP;
END $$;

DROP POLICY IF EXISTS "company_documents_storage_select" ON storage.objects;
CREATE POLICY "company_documents_storage_select" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'company-documents' AND (storage.foldername(name))[1] = auth.uid()::text);
DROP POLICY IF EXISTS "company_documents_storage_insert" ON storage.objects;
CREATE POLICY "company_documents_storage_insert" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'company-documents' AND (storage.foldername(name))[1] = auth.uid()::text);
DROP POLICY IF EXISTS "company_documents_storage_update" ON storage.objects;
CREATE POLICY "company_documents_storage_update" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'company-documents' AND (storage.foldername(name))[1] = auth.uid()::text) WITH CHECK (bucket_id = 'company-documents' AND (storage.foldername(name))[1] = auth.uid()::text);
DROP POLICY IF EXISTS "company_documents_storage_delete" ON storage.objects;
CREATE POLICY "company_documents_storage_delete" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'company-documents' AND (storage.foldername(name))[1] = auth.uid()::text);

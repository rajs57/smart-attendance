# Smart Attendance Online — Setup Guide

This package includes a Supabase-ready web app, SQL schema/RLS policies, and your previous HTML as a reference. It is not live until you connect a Supabase project and deploy the frontend.

## 1. Create the online database
1. Create a project at https://supabase.com/ and save the database password privately.
2. Open **SQL Editor → New query**.
3. Copy all of `schema.sql`, run it, and confirm the tables (`profiles`, `students`, `student_requests`, `attendance_records`, `organization_settings`) exist. The `organization_settings` row with `id = 1` stores the shared college name/logo/contact details/theme/brand color.
4. In **Project Settings → API** (or Connect), copy the **Project URL** and the public **anon/publishable key**. Do not use or publish the `service_role` key.

## 2. Configure the app
1. Open `index.html` in a text editor.
2. Near the bottom, replace:
   - `YOUR_SUPABASE_PROJECT_URL` with your project URL (already set to `https://wejxgxtfdgjlycgeqvpi.supabase.co` in this package)
   - `YOUR_SUPABASE_ANON_OR_PUBLISHABLE_KEY` with the public anon/publishable key
3. Save the file.

## 3. Create the first administrator
1. In Supabase, go to **Authentication → Users → Add user** and create the admin email/password. Disable public sign-ups in Authentication settings.
2. Copy that user's UUID from the Users page.
3. In SQL Editor, run this statement after replacing the sample values:

```sql
insert into public.profiles (id, full_name, role, organization)
values ('PASTE_AUTH_USER_UUID_HERE', 'College Admin', 'college_admin', 'Your College Name');
```

For the highest-level account, use `super_admin` as the role. For staff, create another Auth user and insert a profile with role `staff`. Keep role assignment restricted to trusted administrators.

## 4. Test shared college settings and live updates
1. Sign in as an admin and open **Settings**.
2. Change college name, logo URL, address/contact details, theme, or brand color and save.
3. Sign in to a Staff account in another browser/device. The shared college name/theme should update from the same database; Realtime refreshes data while the app is open.
4. If live updates do not appear, open Supabase **Database → Replication** and ensure `organization_settings`, `students`, `student_requests`, and `attendance_records` are enabled for Realtime.

## 5. Publish online
Use any static HTTPS host, such as Netlify, Vercel, or GitHub Pages:
- Upload `index.html` as the site entry point.
- In Supabase Authentication URL settings, set the production site URL and allowed redirect URLs to your deployed HTTPS domain.
- Open the public URL and sign in with the account created in Supabase Auth.

You can test locally with a simple static web server, but do not use demo credentials; the app uses real Supabase Auth once configured.

## Important notes
- The app deliberately has no public sign-up screen. Accounts must be created by an administrator in Supabase Auth.
- The browser only contains the public anon/publishable key. Row Level Security (RLS) policies in `schema.sql` enforce access. Never put a database password or service-role key in `index.html`.
- This is a starter online implementation. Before production use, test every role and policy, enable MFA for admins, configure backups, and add organization-level tenant isolation if multiple colleges will share one project. The current schema is designed for one college per Supabase project. The public website cannot create Supabase Auth users by itself; create accounts in Supabase Auth and add the matching `profiles` row.
- The previous editable demo is included as `demo-reference.html`; the online-ready implementation is `index.html`.

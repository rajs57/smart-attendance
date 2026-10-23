# Smart Attendance Management System — Online Starter

Admin and Staff use the same Supabase backend. Admin can edit college branding/settings, student records, approve staff requests, and review attendance. Staff can mark attendance and request student additions. The app subscribes to Supabase Realtime so open sessions refresh when shared data changes.

## Files
- `index.html` — app entry point for GitHub Pages/static hosting
- `schema.sql` — PostgreSQL tables, RLS policies, and Realtime publication setup
- `SETUP.md` — setup guide for Supabase and hosting
- `demo-reference.html` — previous editable local demo, kept for reference only

## Important
This ZIP is **not connected to a live cloud project yet**. Create your own Supabase project, run `schema.sql`, configure the public project URL and anon/publishable key in `index.html`, then create the first admin account as described in `SETUP.md`. Never put a database password or `service_role` key in this repository.

Designed for one college per Supabase project. Test permissions and backup procedures before using real student data.

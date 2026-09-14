# PucungHub Architecture

Dokumen ini menjelaskan fondasi arsitektur PucungHub v0.1 berdasarkan `docs/PUCUNGHUB_SPEC.txt`.

## Komponen

- **Next.js + React**: UI, routing, dan server-side application logic.
- **Supabase**: backend terkelola untuk Auth, PostgreSQL, Row Level Security, dan Storage.
- **PostgreSQL**: penyimpanan data profile, project, task, submission, review, attendance, dan notification.
- **Supabase Auth**: login, logout, session, dan identitas user.
- **Supabase Storage**: avatar, cover project, attachment, dan file submission.
- **Vercel**: deployment aplikasi Next.js.
- **GitHub**: source control, checkpoint phase, dan dokumentasi.

## Arah Data

Browser menggunakan aplikasi Next.js. Aplikasi berkomunikasi dengan Supabase Auth, PostgreSQL, dan Storage menggunakan policy keamanan yang sesuai. PostgreSQL menjadi sumber data operasional dan RLS menjadi batas akses data.

## Prinsip Phase 0

Phase 0 hanya menyiapkan struktur dan dokumentasi. Belum ada Supabase client, authentication, database schema, migration, middleware, atau fitur bisnis.

## Prinsip Pengembangan

- Mobile first untuk workflow Intern dan Staff.
- Desktop untuk monitoring Admin dan Art Director.
- Komponen UI generik dipisahkan dari fitur bisnis.
- Setiap phase dibuat, diuji, diperbaiki, didokumentasikan, lalu diberi checkpoint Git.
- Requirement di luar MVP v0.1 diperlakukan sebagai future feature.

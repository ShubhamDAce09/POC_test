# IIM Shillong Community Timetable

Personalized core + elective timetable for PGP/PGPEx students.

**Current stack:** Next.js on [Vercel](https://vercel.com) + Postgres on [Neon](https://neon.tech). Firebase is no longer used.

The Flutter Android/iOS project remains in this repo as an optional later client. The product you deploy is `web/`.

## Student flow

1. Sign in / register with an `@iimshillong.ac.in` email.
2. Upload the office `.xlsx` file, or load the bundled sample.
3. Select electives (core subjects are always included).
4. See a personalized timetable.
5. Allow browser notifications for a reminder 15 minutes before class (Asia/Kolkata).

Admin (`ADMIN_EMAILS`, default `shubham.pgpex26@iimshillong.ac.in`) can open **Usage KPIs** in the app. Events live in Neon: `app_open`, `login`, `file_upload`, `subject_selection`, `reminder_trigger`.

## Excel layout

| Day | Start Time | End Time | Course Code | Subject | Type | Faculty | Venue |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Monday | 09:00 | 10:30 | PGPEX-C1 | Managerial Economics | Core | Faculty A | CH-1 |
| Monday | 11:00 | 12:30 | PGPEX-E1 | FinTech Strategy | Elective | Faculty B | CH-2 |

## What you do next

### 1. Neon database

1. Create a project at [neon.tech](https://neon.tech).
2. Copy the connection string (`DATABASE_URL`).
3. Tables are created automatically on first request (`users`, `office_timetable`, `user_electives`, `analytics_events`).

### 2. Vercel project

1. Import this GitHub repo into Vercel.
2. Set **Root Directory** to `web`.
3. Add environment variables:

| Name | Value |
| --- | --- |
| `DATABASE_URL` | Neon connection string |
| `AUTH_SECRET` | long random string (`openssl rand -base64 32`) |
| `ADMIN_EMAILS` | `shubham.pgpex26@iimshillong.ac.in` |

4. Deploy. Open the Vercel URL, register with your institute email, load the sample timetable, then check **Usage KPIs**.

### 3. Local run

```bash
cd web
cp .env.example .env.local
# paste DATABASE_URL and AUTH_SECRET
npm install
npm test
npm run dev
```

## Optional Flutter app

`lib/`, `android/`, and `ios/` are the earlier mobile POC. It still talks to Firebase placeholders. Pointing it at the Vercel API can be a follow-up; the hosted web app is the source of truth for data.

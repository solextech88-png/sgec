# Smart Global Education Consult (SGEC)

Starter codebase for a global education-consultancy platform: a Flutter mobile
app (students, consultants, admins) backed by a Node.js/Express + PostgreSQL
(Prisma) API.

This is a **scaffold**, not a finished product. It is structured so a dev team
can fill in business logic, wire up real integrations (payment, S3/GCS
storage, university partner APIs, e-signature provider, push notifications,
LLM provider), and harden security before going to production. Every stubbed
file has a `// TODO` explaining what real implementation needs to happen.

## Repo layout

```
sgec/
├── backend/            Node.js + Express + Prisma REST API
│   ├── prisma/
│   │   └── schema.prisma   Full data model (users, universities, programmes,
│   │                       documents, consent, applications, chat, etc.)
│   └── src/
│       ├── config/         env + db + storage config
│       ├── middleware/      auth (JWT), role guard, error handler
│       ├── routes/          one file per resource
│       ├── controllers/     business logic per resource
│       └── utils/           helpers (tokens, OTP, S3 signed urls, AI client)
│
└── mobile_app/         Flutter app (student, consultant, admin views gated
                         by role inside one codebase)
    └── lib/
        ├── core/            api client, theme, constants, secure storage
        ├── models/           Dart models mirroring the Prisma schema
        ├── routes/           GoRouter route table incl. role-based redirects
        ├── features/         one folder per feature (auth, documents, ...)
        └── widgets/          shared UI components
```

## Why this architecture

- **One Flutter codebase, three roles.** Rather than 3 separate apps, the
  student/consultant/admin experiences are separate route trees gated by the
  `role` claim on the JWT. This is cheaper to maintain and matches how most
  ed-tech consultancies actually operate (staff need the same app on their
  own phones).
- **Node/Express/Prisma/PostgreSQL** for the backend: relational data (many
  universities → many programmes → many intakes → many applications) fits
  a relational DB far better than document storage. Prisma gives you
  type-safe migrations, which matters once the university/programme catalog
  is being updated by non-engineers via an admin portal.
- **Document storage is abstracted** behind `utils/storage.js` so you can
  point it at S3, GCS, or Azure Blob without touching route code. Never
  store passports/transcripts on the API server's own disk in production.
- **Consent forms** are modeled as immutable, versioned records
  (`ConsentForm` + `ConsentSignature`) with a hash of the exact document text
  the student signed, an IP/timestamp, and a signature image or typed
  signature blob — this is the audit trail a real e-signature/consent flow
  needs. Get this reviewed by a lawyer per target jurisdiction before launch;
  I've built the data model and workflow, not the legal language.
- **AI features** (recommendation, essay review, admission-chance
  prediction) are isolated behind `utils/aiClient.js` so you can swap
  providers/models without touching controllers.

## Getting started

### Backend
```bash
cd backend
cp .env.example .env      # fill in DATABASE_URL, JWT_SECRET, etc.
npm install
npx prisma migrate dev --name init
npm run dev
```

### Mobile app
```bash
cd mobile_app
flutter pub get
flutter run
```
Point `lib/core/api_client.dart`'s `baseUrl` at your running backend
(default assumes `http://10.0.2.2:4000` for the Android emulator).

## What's fully wired vs. stubbed

| Area | Status |
|---|---|
| Auth (register/login, JWT, role middleware) | Working end-to-end against Postgres |
| OTP verification | Working flow, uses a console-logged fake SMS/email sender — swap in Twilio/SendGrid |
| University & programme browsing | Working end-to-end, seeded with sample data |
| Document upload | Working API + Flutter picker, storage adapter stubbed to local disk (swap for S3) |
| Digital consent signing | Full data model + working signature capture screen + PDF text hash; actual legally-binding e-signature integration (DocuSign/HelloSign) is a TODO |
< AI assistant (recommend/compare/review) | Endpoint + Flutter chat UI wired to `aiClient.js`, which currently calls the Anthropic API — swap/extend as needed |
| Consultant dashboard | Basic list/detail views working; workflow automation (auto-assignment, SLA tracking) is a TODO |
| Admin portal (universities/programmes/intakes) | CRUD working; bulk annual-update import (CSV/partner feed) is a TODO |
| Chat (student ↔ consultant) | Data model + REST polling endpoint; swap for WebSocket/Firebase for real-time |
| Notifications | Data model + endpoint; push delivery (FCM/APNs) is a TODO |
| University application submission | Data model + status tracking; actual portal/API integration is per-university and must be built incrementally — start with the 10–20 highest-volume partner universities |

## Security notes for whoever picks this up
- Every document upload endpoint must run antivirus scanning before storage
  in production (e.g., ClamAV sidecar) — not included here.
- Add rate limiting (e.g., `express-rate-limit`) in front of auth/OTP routes
  before launch, and CAPTCHA on public registration.
- Passport numbers, transcripts, and other PII require encryption at rest
  and a documented data-retention/deletion policy per GDPR (EU/UK students)
  and other applicable regimes.
- The JWT secret and DB credentials in `.env.example` are placeholders —
  never commit real secrets.

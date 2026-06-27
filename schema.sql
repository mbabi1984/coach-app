-- ============================================================
--  منصّة إدارة التدريب — مخطّط قاعدة البيانات (نسخة تجريبية لكوتش واحد)
--  Coaching app — Supabase schema (single-coach test build)
--  انسخ هذا الملف كاملاً والصقه في:  Supabase ← SQL Editor ← New query ← Run
-- ============================================================

-- 1) مكتبة التمارين (مشتركة) — Exercise library (shared)
create table if not exists exercises (
  id          bigint generated always as identity primary key,
  name_ar     text not null,
  name_en     text default '',
  muscle      text default 'chest',
  yt          text default '',          -- معرّف فيديو يوتيوب (ID) — YouTube video id
  note_ar     text default '',          -- ملاحظة المدرب على التمرين
  note_en     text default '',
  created_at  timestamptz default now()
);

-- 2) المتدربون — Clients (program/measurements/logs/habits ك JSONB لتبسيط النسخة التجريبية)
create table if not exists clients (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  invite_code   text unique not null,   -- رمز الدعوة الذي يدخله المتدرب
  onboarded     boolean default false,
  age           int,
  height        int,
  weight        numeric,
  gender        text default 'm',
  level         text default 'int',     -- beg | int | adv
  goal          text default 'strength',
  injuries      jsonb default '[]'::jsonb,
  measurements  jsonb default '{}'::jsonb,   -- waist/bf/chest/arm...
  program       jsonb default '{}'::jsonb,   -- { tue: {title_ar,title_en,items:[...]}, ... }
  logs          jsonb default '{}'::jsonb,   -- { "tue-0-0": {reps,weight,done}, ... }
  habits        jsonb default '{}'::jsonb,
  created_at    timestamptz default now()
);

-- 3) الرسائل — Chat messages (يدعم الزمن الحقيقي Realtime)
create table if not exists messages (
  id          bigint generated always as identity primary key,
  client_id   uuid references clients(id) on delete cascade,
  sender      text not null,            -- 'coach' | 'client'
  body        text not null,
  created_at  timestamptz default now()
);
create index if not exists messages_client_idx on messages(client_id, created_at);

-- ============================================================
--  تفعيل الزمن الحقيقي للرسائل — enable realtime on messages
-- ============================================================
alter publication supabase_realtime add table messages;

-- ============================================================
--  سياسات الوصول (RLS) — نسخة تجريبية مفتوحة
--  ملاحظة أمان: هذه السياسات مفتوحة لأغراض الاختبار الخاص فقط.
--  لا تضع بيانات حسّاسة. عند التوسّع لاحقاً نستبدلها بمصادقة حقيقية.
-- ============================================================
alter table exercises enable row level security;
alter table clients   enable row level security;
alter table messages  enable row level security;

create policy "test_all_exercises" on exercises for all using (true) with check (true);
create policy "test_all_clients"   on clients   for all using (true) with check (true);
create policy "test_all_messages"  on messages  for all using (true) with check (true);

-- ============================================================
--  بيانات أولية للمكتبة — seed a few exercises (اختياري)
-- ============================================================
insert into exercises (name_ar, name_en, muscle, yt, note_ar) values
 ('ضغط الصدر بالبار','Barbell Bench Press','chest','rxD321l2svE','حافظ على لوح الكتف مسحوب ولا تقفل المرفق بالأعلى.'),
 ('القرفصاء الخلفي','Back Squat','legs','ultWZbUMPL8','انزل لحد ما الفخذ يوازي الأرض وادفع من الكعب.'),
 ('الرفعة المميتة','Deadlift','back','op9kVnSso6Q',''),
 ('ضغط الكتف واقف','Overhead Press','shoulders','2yjwXTZQDDI',''),
 ('العقلة','Pull-up','back','eGo4IYlbE5g',''),
 ('تفتيح بالدمبل','Dumbbell Fly','chest','eozdVDA78K0','حركة واسعة وبطيئة، حسّ بالعضلة.')
on conflict do nothing;

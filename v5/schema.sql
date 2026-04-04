-- ═══════════════════════════════════════════════════════
-- Library of Morenita — Full Database Schema
-- Paste this entire file into Supabase SQL Editor and Run
-- ═══════════════════════════════════════════════════════

-- ── PROFILES ──
create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  display_name text,
  handle text unique,
  bio text,
  avatar_url text,
  location text,
  role text default 'reader' check (role in ('librarian','curator','fellow','reader')),
  scroll_count_this_week int default 0,
  scroll_reset_date timestamptz default now(),
  created_at timestamptz default now()
);

-- Auto-create profile on signup
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, display_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'reader')
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

-- ── TAGS ──
create table if not exists tags (
  id serial primary key,
  name text unique not null,
  color text default '#8B4A2A'
);

-- Add constellation column if needed
alter table tags add column if not exists constellation text;

insert into tags (name, color, constellation) values
  ('oral-tradition', '#DDB96A', 'Knowing')
  ('indigenous-science', '#DDB96A', 'Knowing')
  ('mysticism', '#DDB96A', 'Knowing')
  ('philosophy', '#DDB96A', 'Knowing')
  ('cosmology', '#DDB96A', 'Knowing')
  ('herbalism', '#8BA683', 'Body')
  ('beauty-ritual', '#8BA683', 'Body')
  ('food-sovereignty', '#8BA683', 'Body')
  ('ancestral-medicine', '#8BA683', 'Body')
  ('ecology', '#8BA683', 'Body')
  ('textiles', '#C47A55', 'Craft')
  ('ceramics', '#C47A55', 'Craft')
  ('architecture', '#C47A55', 'Craft')
  ('natural-dye', '#C47A55', 'Craft')
  ('printmaking', '#C47A55', 'Craft')
  ('literature', '#4A6B8A', 'Story')
  ('photography', '#4A6B8A', 'Story')
  ('art-history', '#4A6B8A', 'Story')
  ('film', '#4A6B8A', 'Story')
  ('oral-poetry', '#4A6B8A', 'Story')
  ('music', '#7A4A8B', 'Sound')
  ('dance', '#7A4A8B', 'Sound')
  ('sound-healing', '#7A4A8B', 'Sound')
  ('percussion', '#7A4A8B', 'Sound')
  ('resistance', '#9B4A3A', 'Power')
  ('diaspora', '#9B4A3A', 'Power')
  ('decolonization', '#9B4A3A', 'Power')
  ('land', '#9B4A3A', 'Power')
  ('memory', '#9B4A3A', 'Power')
  ('west-africa', '#5A9E6A', 'Place')
  ('latin-america', '#5A9E6A', 'Place')
  ('south-asia', '#5A9E6A', 'Place')
  ('east-asia', '#5A9E6A', 'Place')
  ('caribbean', '#5A9E6A', 'Place')
  ('pacific', '#5A9E6A', 'Place')
  ('middle-east', '#5A9E6A', 'Place')
  ('ancestral', '#C49A3C', 'Time')
  ('contemporary', '#C49A3C', 'Time')
  ('speculative', '#C49A3C', 'Time')
  ('solarpunk', '#4A8B8A', 'Future')
  ('open-source', '#4A8B8A', 'Future')
  ('biomimicry', '#4A8B8A', 'Future')
  ('appropriate-tech', '#4A8B8A', 'Future')
  ('community-infrastructure', '#4A8B8A', 'Future')
on conflict (name) do update set constellation = excluded.constellation, color = excluded.color;

-- ── ARTICLES ──
create table if not exists articles (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  body text,
  excerpt text,
  author_id uuid references profiles(id) on delete set null,
  status text default 'draft' check (status in ('draft','submitted','approved','published')),
  tags text[] default '{}',
  read_time text,
  cover_image text,
  type text default 'article' check (type in ('article','quote','image')),
  created_at timestamptz default now(),
  published_at timestamptz
);

-- ── COLLECTIONS (boards) ──
create table if not exists collections (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) on delete cascade,
  title text not null,
  description text,
  cover_image text,
  is_public boolean default false,
  created_at timestamptz default now()
);

create table if not exists collection_items (
  id uuid default gen_random_uuid() primary key,
  collection_id uuid references collections(id) on delete cascade,
  article_id uuid references articles(id) on delete cascade,
  item_order int default 0,
  added_at timestamptz default now()
);

-- ── CURRICULUM TRACKS ──
create table if not exists curriculum_tracks (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text,
  proposed_by uuid references profiles(id) on delete set null,
  approved_by uuid references profiles(id) on delete set null,
  status text default 'proposed' check (status in ('proposed','approved','published')),
  cover_image text,
  tags text[] default '{}',
  created_at timestamptz default now()
);

create table if not exists track_lessons (
  id uuid default gen_random_uuid() primary key,
  track_id uuid references curriculum_tracks(id) on delete cascade,
  article_id uuid references articles(id) on delete cascade,
  week_number int default 1,
  lesson_order int default 0
);

-- ── SAVES ──
create table if not exists saves (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) on delete cascade,
  article_id uuid references articles(id) on delete cascade,
  saved_at timestamptz default now(),
  unique(user_id, article_id)
);

-- ── SCROLL LOG ──
create table if not exists scroll_log (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) on delete cascade,
  article_id uuid references articles(id) on delete cascade,
  viewed_at timestamptz default now()
);

-- Increment scroll count function
create or replace function increment_scroll_count(user_id_input uuid)
returns void as $$
  update profiles
  set scroll_count_this_week = scroll_count_this_week + 1
  where id = user_id_input;
$$ language sql security definer;

-- ── USER PROGRESS (Academy) ──
create table if not exists user_progress (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) on delete cascade,
  track_id uuid references curriculum_tracks(id) on delete cascade,
  lesson_id uuid references track_lessons(id) on delete cascade,
  completed_at timestamptz default now(),
  unique(user_id, lesson_id)
);

-- ── ROW LEVEL SECURITY ──
alter table profiles enable row level security;
alter table articles enable row level security;
alter table collections enable row level security;
alter table collection_items enable row level security;
alter table saves enable row level security;
alter table scroll_log enable row level security;
alter table user_progress enable row level security;
alter table curriculum_tracks enable row level security;

-- Profiles: users can read all, update only their own
create policy "Profiles are viewable by everyone" on profiles for select using (true);
create policy "Users can update own profile" on profiles for update using (auth.uid() = id);

-- Articles: published ones are public; authors can see their own drafts
create policy "Published articles are public" on articles for select using (status = 'published' or auth.uid() = author_id);
create policy "Authors can insert articles" on articles for insert with check (auth.uid() = author_id);
create policy "Authors can update own articles" on articles for update using (auth.uid() = author_id);

-- Collections: public ones visible to all; private only to owner
create policy "Public collections visible to all" on collections for select using (is_public = true or auth.uid() = user_id);
create policy "Users can manage own collections" on collections for all using (auth.uid() = user_id);

-- Saves: users manage their own
create policy "Users manage own saves" on saves for all using (auth.uid() = user_id);

-- Scroll log: users manage their own
create policy "Users manage own scroll log" on scroll_log for all using (auth.uid() = user_id);

-- Progress: users manage their own
create policy "Users manage own progress" on user_progress for all using (auth.uid() = user_id);

-- Curriculum: published tracks public; proposed visible to librarians/curators
create policy "Published tracks are public" on curriculum_tracks for select using (status = 'published');

-- Tags: public read
create policy "Tags are public" on tags for select using (true);

-- ── SEED: Make Amelia a Librarian ──
-- Run this AFTER you sign up with missameliava@gmail.com
-- update profiles set role = 'librarian' where email = 'missameliava@gmail.com';

-- ── REFLECTIONS (quote annotations) ──
create table if not exists reflections (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) on delete cascade,
  quote_id text not null,
  text text,
  is_public boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, quote_id)
);
alter table reflections enable row level security;
create policy "Public reflections viewable by all" on reflections for select using (is_public = true or auth.uid() = user_id);
create policy "Users manage own reflections" on reflections for all using (auth.uid() = user_id);

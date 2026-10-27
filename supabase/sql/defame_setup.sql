-- Reviewed additive installation. Existing rows are copied, never deleted.
-- All df_* tables are server-only. Clients use the authenticated Edge API.
begin;
create table if not exists public.df_accounts (
  id uuid primary key references auth.users(id),
  username text not null unique check (username ~ '^[A-Za-z0-9_]{3,24}$'),
  display_name text not null default '', bio text not null default '',
  age_verified boolean not null default false,
  identity_verified boolean not null default false,
  is_moderator boolean not null default false,
  suspended boolean not null default false,
  deletion_requested_at timestamptz,
  region text, nearby_opt_in boolean not null default false,
  notifications boolean not null default true,
  created_at timestamptz not null default now()
);
create unique index if not exists df_username_lower on public.df_accounts(lower(username));
create table if not exists public.df_communities (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.df_accounts(id),
  name text not null unique, description text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);
create table if not exists public.df_members (
  community_id uuid not null references public.df_communities(id),
  user_id uuid not null references public.df_accounts(id),
  primary key(community_id, user_id)
);
create table if not exists public.df_posts (
  id uuid primary key default gen_random_uuid(), author_id uuid not null references public.df_accounts(id),
  request_id text not null, kind text not null default 'experience' check (kind in ('post','experience')),
  is_anonymous boolean not null default true, category text not null,
  subject_name text, title text not null, body text not null,
  region text, community_id uuid references public.df_communities(id), poll jsonb,
  moderation_status text not null default 'pending' check(moderation_status in ('pending','approved','rejected','removed')),
  moderation_note text, created_at timestamptz not null default now(), expires_at timestamptz,
  deleted_at timestamptz, unique(author_id,request_id)
);
create index if not exists df_posts_feed on public.df_posts(moderation_status, created_at desc, id);
create index if not exists df_posts_author on public.df_posts(author_id,created_at desc);
create index if not exists df_posts_community on public.df_posts(community_id,created_at desc);
create table if not exists public.df_media (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.df_accounts(id),
  post_id uuid unique references public.df_posts(id), storage_path text not null unique,
  kind text not null check(kind in ('image','video')), mime text not null,
  created_at timestamptz not null default now()
);
create index if not exists df_media_user on public.df_media(user_id);
create table if not exists public.df_comments (
  id uuid primary key default gen_random_uuid(), post_id uuid not null references public.df_posts(id),
  author_id uuid not null references public.df_accounts(id), parent_id uuid references public.df_comments(id),
  body text not null, moderation_status text not null default 'pending'
    check(moderation_status in ('pending','approved','rejected','removed')),
  created_at timestamptz not null default now(), deleted_at timestamptz
);
create index if not exists df_comments_post on public.df_comments(post_id,created_at,id);
create index if not exists df_comments_author on public.df_comments(author_id);
create index if not exists df_comments_parent on public.df_comments(parent_id);
create table if not exists public.df_votes (
  user_id uuid not null references public.df_accounts(id), post_id uuid not null references public.df_posts(id),
  value text not null check(value in ('like','dislike')), primary key(user_id,post_id)
);
create index if not exists df_votes_post on public.df_votes(post_id);
create table if not exists public.df_comment_votes (
  user_id uuid not null references public.df_accounts(id), comment_id uuid not null references public.df_comments(id),
  value text not null check(value in ('like','dislike')), primary key(user_id,comment_id)
);
create index if not exists df_comment_votes_comment on public.df_comment_votes(comment_id);
create table if not exists public.df_poll_votes (
  user_id uuid not null references public.df_accounts(id), post_id uuid not null references public.df_posts(id),
  option integer not null check(option between 0 and 5), primary key(user_id,post_id)
);
create index if not exists df_poll_votes_post on public.df_poll_votes(post_id);
create table if not exists public.df_blocks (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.df_accounts(id),
  blocked_id uuid not null references public.df_accounts(id), created_at timestamptz not null default now(),
  check(user_id <> blocked_id), unique(user_id,blocked_id)
);
create index if not exists df_blocks_blocked on public.df_blocks(blocked_id);
create table if not exists public.df_reports (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.df_accounts(id),
  post_id uuid not null references public.df_posts(id), comment_id uuid references public.df_comments(id),
  reason text not null, details text not null, priority integer not null default 0,
  status text not null default 'pending', resolution text, created_at timestamptz not null default now()
);
create index if not exists df_reports_queue on public.df_reports(status,priority desc,created_at);
create index if not exists df_reports_user on public.df_reports(user_id);
create index if not exists df_reports_post on public.df_reports(post_id);
create index if not exists df_reports_comment on public.df_reports(comment_id);
create table if not exists public.df_responses (
  id uuid primary key default gen_random_uuid(), post_id uuid not null references public.df_posts(id),
  user_id uuid not null references public.df_accounts(id), body text not null,
  subject_verified boolean not null default false,
  status text not null default 'pending', created_at timestamptz not null default now()
);
create index if not exists df_responses_post on public.df_responses(post_id);
create index if not exists df_responses_user on public.df_responses(user_id);
create table if not exists public.df_activity (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.df_accounts(id),
  post_id uuid references public.df_posts(id), title text not null, body text not null,
  is_read boolean not null default false, created_at timestamptz not null default now()
);
create index if not exists df_activity_user on public.df_activity(user_id,created_at desc);
create index if not exists df_activity_post on public.df_activity(post_id);
create or replace view public.df_post_stats with (security_invoker = true) as
select p.*,
  (select count(*)::integer from public.df_votes v where v.post_id=p.id and v.value='like') as likes,
  (select count(*)::integer from public.df_votes v where v.post_id=p.id and v.value='dislike') as dislikes,
  (select count(*)::integer from public.df_comments c where c.post_id=p.id and c.moderation_status='approved' and c.deleted_at is null) as comment_count
from public.df_posts p;
revoke all on public.df_post_stats from anon,authenticated;
grant select on public.df_post_stats to service_role;
create or replace function public.df_feed(uid uuid, query_text text, sort_mode text,
  target_author uuid default null, target_community uuid default null, only_mine boolean default false,
  page_number integer default 0)
returns setof public.df_post_stats language sql stable security invoker set search_path = '' as $$
  select p.* from public.df_post_stats p join public.df_accounts a on a.id=p.author_id
  where p.deleted_at is null and a.deletion_requested_at is null and not a.suspended
    and ((only_mine and p.author_id=uid) or (not only_mine and p.moderation_status='approved'
      and (p.expires_at is null or p.expires_at>now())))
    and (target_author is null or (p.author_id=target_author and not p.is_anonymous))
    and (target_community is null or p.community_id=target_community)
    and (p.community_id is null or exists(select 1 from public.df_communities c where c.id=p.community_id and c.status='approved'))
    and not exists(select 1 from public.df_blocks b where
      (b.user_id=uid and b.blocked_id=p.author_id) or (b.blocked_id=uid and b.user_id=p.author_id))
    and (query_text='' or position(lower(query_text) in lower(p.title||' '||p.body||' '||p.category))>0
      or (not p.is_anonymous and position(lower(query_text) in lower(a.username))>0))
    and (sort_mode<>'Nearby' or exists(select 1 from public.df_accounts me where me.id=uid
      and me.nearby_opt_in and me.region is not null and lower(me.region)=lower(p.region)))
  order by case when sort_mode='Popular' then p.likes-p.dislikes else 0 end desc,
    p.created_at desc,p.id
  limit 21 offset greatest(0,least(page_number,500))*20;
$$;
revoke all on function public.df_feed(uuid,text,text,uuid,uuid,boolean,integer) from public,anon,authenticated;
grant execute on function public.df_feed(uuid,text,text,uuid,uuid,boolean,integer) to service_role;
create table if not exists public.df_verifications (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.df_accounts(id),
  provider_ref text unique, status text not null default 'pending',
  created_at timestamptz not null default now(), completed_at timestamptz
);
create index if not exists df_verifications_user on public.df_verifications(user_id);
create table if not exists public.df_audit (
  id bigint generated always as identity primary key, actor_id uuid,
  action text not null, target_id uuid, note text not null, created_at timestamptz not null default now()
);
create table if not exists public.df_limits (
  user_id uuid not null, bucket text not null, rate_window timestamptz not null,
  hits integer not null default 0, primary key(user_id,bucket,rate_window)
);
create table if not exists public.df_consents (
  user_id uuid not null references public.df_accounts(id), version text not null,
  accepted_at timestamptz not null default now(), primary key(user_id,version)
);

create or replace function public.df_complete_verification(session_id uuid, provider_id text,
  over_18 boolean, identity_checked boolean)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare target uuid;
begin
  update public.df_verifications set status=case when over_18 then 'approved' else 'rejected' end,
    completed_at=now()
    where id=session_id and provider_ref=provider_id and status='pending'
    returning user_id into target;
  if target is null then return false; end if;
  if over_18 then
    update public.df_accounts set age_verified=true, identity_verified=identity_checked where id=target;
  end if;
  insert into public.df_audit(actor_id,action,target_id,note)
    values(target,'verification_completed',session_id,case when over_18 then '18+ confirmed by provider' else 'Verification rejected' end);
  return true;
end; $$;
revoke all on function public.df_complete_verification(uuid,text,boolean,boolean) from public,anon,authenticated;
grant execute on function public.df_complete_verification(uuid,text,boolean,boolean) to service_role;

-- Store a post and claim its attachment in one transaction. Retries return the same row.
create or replace function public.df_publish(payload jsonb, attachment_id uuid default null)
returns public.df_posts language plpgsql security invoker set search_path = '' as $$
declare result public.df_posts; attachment public.df_media;
begin
  perform pg_advisory_xact_lock(hashtextextended((payload->>'author_id')||':'||(payload->>'request_id'),0));
  select * into result from public.df_posts where author_id=(payload->>'author_id')::uuid and request_id=payload->>'request_id';
  if result.id is not null then return result; end if;
  if attachment_id is not null then
    select * into attachment from public.df_media where id=attachment_id for update;
    if attachment.id is null or attachment.user_id<>(payload->>'author_id')::uuid or attachment.post_id is not null then
      raise exception 'Attachment is unavailable';
    end if;
  end if;
  insert into public.df_posts(author_id,request_id,title,body,subject_name,is_anonymous,category,kind,region,community_id,poll,
    moderation_status,moderation_note,created_at,expires_at)
  values((payload->>'author_id')::uuid,payload->>'request_id',payload->>'title',payload->>'body',payload->>'subject_name',
    (payload->>'is_anonymous')::boolean,payload->>'category',payload->>'kind',payload->>'region',
    (payload->>'community_id')::uuid,nullif(payload->'poll','null'::jsonb),payload->>'moderation_status',payload->>'moderation_note',
    (payload->>'created_at')::timestamptz,(payload->>'expires_at')::timestamptz) returning * into result;
  if attachment_id is not null then update public.df_media set post_id=result.id where id=attachment_id; end if;
  return result;
end; $$;
revoke all on function public.df_publish(jsonb,uuid) from public,anon,authenticated;
grant execute on function public.df_publish(jsonb,uuid) to service_role;

-- Atomic rate limits; never callable with a client key.
create or replace function public.df_consume_limit(uid uuid, bucket_name text, max_hits integer)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare current_hits integer;
begin
  insert into public.df_limits(user_id,bucket,rate_window,hits)
  values(uid,bucket_name,date_trunc('minute',now()),1)
  on conflict(user_id,bucket,rate_window) do update set hits=public.df_limits.hits+1
  returning hits into current_hits;
  return current_hits <= max_hits;
end; $$;
revoke all on function public.df_consume_limit(uuid,text,integer) from public, anon, authenticated;
grant execute on function public.df_consume_limit(uuid,text,integer) to service_role;

-- Import existing data. Simulated age verification is deliberately not trusted.
insert into public.df_accounts(id,username,display_name,bio,created_at)
select id, case when username ~ '^[A-Za-z0-9_]{3,24}$' then username
  else 'user_' || left(replace(id::text,'-',''),16) end,
  coalesce(display_name,''),coalesce(bio,''),created_at from public.profiles
on conflict(id) do nothing;
insert into public.df_posts(id,author_id,request_id,is_anonymous,category,subject_name,title,body,
  created_at,expires_at,moderation_status)
select e.id,e.author_id,'import-'||e.id::text,e.is_anonymous,e.category,e.subject_name,e.title,e.body,
  e.created_at,case when e.is_anonymous then e.created_at + interval '72 hours' else null end,'pending'
from public.experiences e join public.df_accounts a on a.id=e.author_id on conflict do nothing;
insert into public.df_posts(id,author_id,request_id,kind,is_anonymous,category,title,body,created_at,expires_at)
select p.id,p.author_id,'import-'||p.id::text,'post',p.is_anonymous,'Other',left(p.caption,120),p.caption,p.created_at,
  case when p.is_anonymous then p.created_at + interval '72 hours' else null end
from public.posts p join public.df_accounts a on a.id=p.author_id on conflict do nothing;
insert into public.df_comments(id,post_id,author_id,body,created_at)
select c.id,c.experience_id,c.author_id,c.body,c.created_at from public.experience_comments c
join public.df_accounts a on a.id=c.author_id join public.df_posts p on p.id=c.experience_id on conflict do nothing;
insert into public.df_votes(user_id,post_id,value)
select r.user_id,r.experience_id,r.reaction from public.experience_reactions r
join public.df_accounts a on a.id=r.user_id join public.df_posts p on p.id=r.experience_id on conflict do nothing;
insert into public.df_votes(user_id,post_id,value)
select r.user_id,r.post_id,r.reaction from public.post_reactions r
join public.df_accounts a on a.id=r.user_id join public.df_posts p on p.id=r.post_id on conflict do nothing;
insert into public.df_comment_votes(user_id,comment_id,value)
select r.user_id,r.comment_id,r.reaction from public.experience_comment_reactions r
join public.df_accounts a on a.id=r.user_id join public.df_comments c on c.id=r.comment_id on conflict do nothing;

-- Signup and profile edits share the same case-insensitive unique index.
-- Metadata supplies a display identifier only, never a verification or role claim.
create schema if not exists defame_private;
revoke all on schema defame_private from public,anon,authenticated;
create or replace function defame_private.register_account()
returns trigger language plpgsql security definer set search_path = '' as $$
declare requested text;
begin
  if tg_table_schema<>'auth' or tg_table_name<>'users' or pg_trigger_depth()<1 then
    raise exception 'Registration trigger only';
  end if;
  requested := new.raw_user_meta_data->>'username';
  if requested is null or requested !~ '^[A-Za-z0-9_]{3,24}$' then
    raise exception 'Username must contain 3-24 letters, numbers or underscores';
  end if;
  insert into public.df_accounts(id,username) values(new.id,requested);
  return new;
end; $$;
revoke all on function defame_private.register_account() from public,anon,authenticated;
drop trigger if exists defame_register_account on auth.users;
create trigger defame_register_account after insert on auth.users
  for each row execute function defame_private.register_account();

do $$ declare item record; begin
  for item in select tablename from pg_tables where schemaname='public' and left(tablename,3)='df_' loop
    execute format('alter table public.%I enable row level security',item.tablename);
    execute format('revoke all on public.%I from anon, authenticated',item.tablename);
    execute format('grant all on public.%I to service_role',item.tablename);
  end loop;
end $$;
grant usage,select on sequence public.df_audit_id_seq to service_role;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('defame-media','defame-media',false,8388608,array['image/jpeg','image/png','image/webp','video/mp4','video/quicktime'])
on conflict(id) do nothing;
commit;

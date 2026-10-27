-- Run only after API deployment/testing and explicit live approval.
-- Old app builds need updating; original records are retained.
begin;
revoke all on public.profiles, public.experiences, public.experience_comments,
  public.experience_reactions, public.experience_comment_reactions,
  public.posts, public.post_images, public.post_reactions from anon, authenticated;
alter table public.profiles enable row level security;
alter table public.experiences enable row level security;
alter table public.experience_comments enable row level security;
alter table public.experience_reactions enable row level security;
alter table public.experience_comment_reactions enable row level security;
alter table public.posts enable row level security;
alter table public.post_images enable row level security;
alter table public.post_reactions enable row level security;
alter function public.get_top_experience_comments(uuid,integer) set search_path = public, pg_temp;
commit;

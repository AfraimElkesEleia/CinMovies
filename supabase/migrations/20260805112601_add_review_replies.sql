create table public.review_replies (
  id uuid primary key default gen_random_uuid(),
  review_id uuid not null,
  user_id uuid not null,
  body text not null,
  created_at timestamptz not null default now(),
  constraint review_replies_review_id_user_reviews_fkey
    foreign key (review_id)
    references public.user_reviews (id)
    on delete cascade,
  constraint review_replies_user_id_profiles_fkey
    foreign key (user_id)
    references public.profiles (id)
    on delete cascade,
  constraint review_replies_user_id_fkey
    foreign key (user_id)
    references auth.users (id)
    on delete cascade,
  constraint review_replies_body_length_check
    check (char_length(btrim(body)) between 1 and 1000)
);

create table public.reply_reactions (
  reply_id uuid not null,
  user_id uuid not null,
  reaction text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (reply_id, user_id),
  constraint reply_reactions_reply_id_review_replies_fkey
    foreign key (reply_id)
    references public.review_replies (id)
    on delete cascade,
  constraint reply_reactions_user_id_fkey
    foreign key (user_id)
    references auth.users (id)
    on delete cascade,
  constraint reply_reactions_reaction_check
    check (reaction in ('like', 'dislike'))
);

create index review_replies_review_created_at_idx
  on public.review_replies (review_id, created_at, id);

create index reply_reactions_reply_reaction_idx
  on public.reply_reactions (reply_id, reaction);

alter table public.review_replies enable row level security;
alter table public.reply_reactions enable row level security;

create policy "review replies public select"
on public.review_replies for select to anon, authenticated
using (true);

create policy "review replies permanent user insert"
on public.review_replies for insert to authenticated
with check (
  (select auth.uid()) = user_id
  and not coalesce(
    ((select auth.jwt()) ->> 'is_anonymous')::boolean,
    false
  )
  and exists (
    select 1
    from public.user_reviews review
    where review.id = review_id
  )
);

create policy "review replies owner delete"
on public.review_replies for delete to authenticated
using (
  (select auth.uid()) = user_id
  and not coalesce(
    ((select auth.jwt()) ->> 'is_anonymous')::boolean,
    false
  )
);

create policy "reply reactions public select"
on public.reply_reactions for select to anon, authenticated
using (true);

create policy "reply reactions permanent user insert"
on public.reply_reactions for insert to authenticated
with check (
  (select auth.uid()) = user_id
  and not coalesce(
    ((select auth.jwt()) ->> 'is_anonymous')::boolean,
    false
  )
  and exists (
    select 1
    from public.review_replies reply
    where reply.id = reply_id
      and reply.user_id <> (select auth.uid())
  )
);

create policy "reply reactions permanent user update"
on public.reply_reactions for update to authenticated
using (
  (select auth.uid()) = user_id
  and not coalesce(
    ((select auth.jwt()) ->> 'is_anonymous')::boolean,
    false
  )
)
with check (
  (select auth.uid()) = user_id
  and not coalesce(
    ((select auth.jwt()) ->> 'is_anonymous')::boolean,
    false
  )
  and exists (
    select 1
    from public.review_replies reply
    where reply.id = reply_id
      and reply.user_id <> (select auth.uid())
  )
);

create policy "reply reactions owner delete"
on public.reply_reactions for delete to authenticated
using (
  (select auth.uid()) = user_id
  and not coalesce(
    ((select auth.jwt()) ->> 'is_anonymous')::boolean,
    false
  )
);

revoke all on public.review_replies, public.reply_reactions
  from anon, authenticated;
grant select on public.review_replies, public.reply_reactions to anon;
grant select on public.review_replies, public.reply_reactions
  to authenticated;
grant insert, delete on public.review_replies to authenticated;
grant insert, update, delete on public.reply_reactions to authenticated;

create function public.get_review_reply_counts(p_review_ids uuid[])
returns table (review_id uuid, reply_count integer)
language sql
stable
set search_path = public
as $$
  select reply.review_id, count(*)::integer as reply_count
  from public.review_replies reply
  where reply.review_id = any(coalesce(p_review_ids, '{}'::uuid[]))
  group by reply.review_id;
$$;

revoke all on function public.get_review_reply_counts(uuid[]) from public;
grant execute on function public.get_review_reply_counts(uuid[])
  to anon, authenticated;

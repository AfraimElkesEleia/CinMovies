drop policy if exists "ai sessions permanent owner select"
  on public.ai_chat_sessions;
drop policy if exists "ai sessions permanent owner insert"
  on public.ai_chat_sessions;
drop policy if exists "ai sessions permanent owner update"
  on public.ai_chat_sessions;
drop policy if exists "ai sessions permanent owner delete"
  on public.ai_chat_sessions;

create policy "ai sessions permanent owner select"
on public.ai_chat_sessions for select to authenticated
using (
  (select auth.uid()) = user_id
  and not coalesce(
    ((select auth.jwt()) ->> 'is_anonymous')::boolean,
    false
  )
);

create policy "ai sessions permanent owner insert"
on public.ai_chat_sessions for insert to authenticated
with check (
  (select auth.uid()) = user_id
  and not coalesce(
    ((select auth.jwt()) ->> 'is_anonymous')::boolean,
    false
  )
);

create policy "ai sessions permanent owner update"
on public.ai_chat_sessions for update to authenticated
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
);

create policy "ai sessions permanent owner delete"
on public.ai_chat_sessions for delete to authenticated
using (
  (select auth.uid()) = user_id
  and not coalesce(
    ((select auth.jwt()) ->> 'is_anonymous')::boolean,
    false
  )
);

drop policy if exists "ai messages permanent owner select"
  on public.ai_chat_messages;
drop policy if exists "ai messages permanent owner insert"
  on public.ai_chat_messages;
drop policy if exists "ai messages permanent owner delete"
  on public.ai_chat_messages;

create policy "ai messages permanent owner select"
on public.ai_chat_messages for select to authenticated
using (
  (select auth.uid()) = user_id
  and not coalesce(
    ((select auth.jwt()) ->> 'is_anonymous')::boolean,
    false
  )
);

create policy "ai messages permanent owner insert"
on public.ai_chat_messages for insert to authenticated
with check (
  (select auth.uid()) = user_id
  and not coalesce(
    ((select auth.jwt()) ->> 'is_anonymous')::boolean,
    false
  )
  and exists (
    select 1
    from public.ai_chat_sessions session
    where session.id = session_id
      and session.user_id = (select auth.uid())
  )
);

create policy "ai messages permanent owner delete"
on public.ai_chat_messages for delete to authenticated
using (
  (select auth.uid()) = user_id
  and not coalesce(
    ((select auth.jwt()) ->> 'is_anonymous')::boolean,
    false
  )
);

drop policy if exists "ai message movies permanent owner select"
  on public.ai_message_movies;
drop policy if exists "ai message movies permanent owner insert"
  on public.ai_message_movies;
drop policy if exists "ai message movies permanent owner delete"
  on public.ai_message_movies;

create policy "ai message movies permanent owner select"
on public.ai_message_movies for select to authenticated
using (
  exists (
    select 1
    from public.ai_chat_messages message
    where message.id = message_id
      and message.user_id = (select auth.uid())
      and not coalesce(
        ((select auth.jwt()) ->> 'is_anonymous')::boolean,
        false
      )
  )
);

create policy "ai message movies permanent owner insert"
on public.ai_message_movies for insert to authenticated
with check (
  exists (
    select 1
    from public.ai_chat_messages message
    where message.id = message_id
      and message.user_id = (select auth.uid())
      and not coalesce(
        ((select auth.jwt()) ->> 'is_anonymous')::boolean,
        false
      )
  )
);

create policy "ai message movies permanent owner delete"
on public.ai_message_movies for delete to authenticated
using (
  exists (
    select 1
    from public.ai_chat_messages message
    where message.id = message_id
      and message.user_id = (select auth.uid())
      and not coalesce(
        ((select auth.jwt()) ->> 'is_anonymous')::boolean,
        false
      )
  )
);

alter table public.ai_chat_messages
  add column if not exists request_id uuid,
  add column if not exists suggested_replies text[] not null default '{}';

alter table public.ai_message_movies
  add column if not exists reason text not null default '';

create unique index if not exists ai_chat_messages_session_request_role_key
  on public.ai_chat_messages (session_id, request_id, role);

create index if not exists ai_chat_messages_session_created_at_idx
  on public.ai_chat_messages (session_id, created_at);

create index if not exists ai_chat_sessions_user_updated_at_idx
  on public.ai_chat_sessions (user_id, updated_at desc);

create or replace function public.persist_movie_chat_exchange(
  p_session_id uuid,
  p_request_id uuid,
  p_user_content text,
  p_assistant_content text,
  p_suggested_replies text[] default '{}',
  p_movies jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
set search_path = public, auth
as $$
declare
  v_user_id uuid := auth.uid();
  v_is_anonymous boolean := coalesce(
    (auth.jwt() ->> 'is_anonymous')::boolean,
    false
  );
  v_user_message public.ai_chat_messages;
  v_assistant_message public.ai_chat_messages;
  v_movie jsonb;
  v_movie_id uuid;
  v_rank integer := 0;
  v_title text;
begin
  if v_user_id is null or v_is_anonymous then
    raise exception 'Authenticated account required' using errcode = '42501';
  end if;
  if p_session_id is null or p_request_id is null then
    raise exception 'Invalid identifiers' using errcode = '22023';
  end if;
  if nullif(trim(p_user_content), '') is null
    or char_length(trim(p_user_content)) > 1000
    or nullif(trim(p_assistant_content), '') is null then
    raise exception 'Invalid message content' using errcode = '22023';
  end if;
  if jsonb_typeof(coalesce(p_movies, '[]'::jsonb)) <> 'array'
    or jsonb_array_length(coalesce(p_movies, '[]'::jsonb)) > 5 then
    raise exception 'Invalid movie collection' using errcode = '22023';
  end if;

  select *
  into v_assistant_message
  from public.ai_chat_messages
  where session_id = p_session_id
    and request_id = p_request_id
    and role = 'assistant'
    and user_id = v_user_id;

  if found then
    select *
    into v_user_message
    from public.ai_chat_messages
    where session_id = p_session_id
      and request_id = p_request_id
      and role = 'user'
      and user_id = v_user_id;

    return jsonb_build_object(
      'userMessageId', v_user_message.id,
      'userCreatedAt', v_user_message.created_at,
      'assistantMessageId', v_assistant_message.id,
      'assistantCreatedAt', v_assistant_message.created_at
    );
  end if;

  v_title := left(trim(p_user_content), 60);
  insert into public.ai_chat_sessions (id, user_id, title, preview)
  values (p_session_id, v_user_id, v_title, trim(p_user_content))
  on conflict (id) do nothing;

  if not exists (
    select 1
    from public.ai_chat_sessions
    where id = p_session_id and user_id = v_user_id
  ) then
    raise exception 'Conversation not found' using errcode = '42501';
  end if;

  insert into public.ai_chat_messages (
    session_id,
    user_id,
    role,
    content,
    request_id
  )
  values (
    p_session_id,
    v_user_id,
    'user',
    trim(p_user_content),
    p_request_id
  )
  on conflict (session_id, request_id, role)
  do update set content = excluded.content
  returning * into v_user_message;

  insert into public.ai_chat_messages (
    session_id,
    user_id,
    role,
    content,
    request_id,
    suggested_replies
  )
  values (
    p_session_id,
    v_user_id,
    'assistant',
    trim(p_assistant_content),
    p_request_id,
    coalesce(p_suggested_replies, '{}')
  )
  returning * into v_assistant_message;

  for v_movie in
    select value from jsonb_array_elements(coalesce(p_movies, '[]'::jsonb))
  loop
    if jsonb_typeof(v_movie) <> 'object'
      or coalesce((v_movie ->> 'tmdbId')::integer, 0) <= 0
      or nullif(trim(v_movie ->> 'title'), '') is null then
      raise exception 'Invalid movie item' using errcode = '22023';
    end if;

    v_movie_id := public.cache_movie(
      p_tmdb_id := (v_movie ->> 'tmdbId')::integer,
      p_title := v_movie ->> 'title',
      p_original_title := nullif(v_movie ->> 'originalTitle', ''),
      p_overview := nullif(v_movie ->> 'overview', ''),
      p_poster_path := nullif(v_movie ->> 'posterPath', ''),
      p_backdrop_path := nullif(v_movie ->> 'backdropPath', ''),
      p_release_date := nullif(v_movie ->> 'releaseDate', '')::date,
      p_runtime_minutes := nullif(v_movie ->> 'runtime', '')::integer,
      p_age_rating := nullif(v_movie ->> 'ageRating', ''),
      p_vote_average := nullif(v_movie ->> 'voteAverage', '')::numeric,
      p_vote_count := nullif(v_movie ->> 'voteCount', '')::integer,
      p_popularity := nullif(v_movie ->> 'popularity', '')::numeric,
      p_genre_names := array(
        select jsonb_array_elements_text(
          coalesce(v_movie -> 'genres', '[]'::jsonb)
        )
      )
    );

    insert into public.ai_message_movies (
      message_id,
      movie_id,
      rank,
      reason
    )
    values (
      v_assistant_message.id,
      v_movie_id,
      v_rank,
      left(coalesce(v_movie ->> 'reason', ''), 280)
    );
    v_rank := v_rank + 1;
  end loop;

  update public.ai_chat_sessions
  set
    preview = left(trim(p_assistant_content), 240),
    updated_at = now()
  where id = p_session_id and user_id = v_user_id;

  return jsonb_build_object(
    'userMessageId', v_user_message.id,
    'userCreatedAt', v_user_message.created_at,
    'assistantMessageId', v_assistant_message.id,
    'assistantCreatedAt', v_assistant_message.created_at
  );
end;
$$;

revoke all on function public.persist_movie_chat_exchange(
  uuid,
  uuid,
  text,
  text,
  text[],
  jsonb
) from public, anon;
grant execute on function public.persist_movie_chat_exchange(
  uuid,
  uuid,
  text,
  text,
  text[],
  jsonb
) to authenticated;

drop policy if exists "ai sessions owner select" on public.ai_chat_sessions;
drop policy if exists "ai sessions owner insert" on public.ai_chat_sessions;
drop policy if exists "ai sessions owner update" on public.ai_chat_sessions;
drop policy if exists "ai sessions owner delete" on public.ai_chat_sessions;

create policy "ai sessions permanent owner select"
on public.ai_chat_sessions for select to authenticated
using (
  auth.uid() = user_id
  and not coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false)
);

create policy "ai sessions permanent owner insert"
on public.ai_chat_sessions for insert to authenticated
with check (
  auth.uid() = user_id
  and not coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false)
);

create policy "ai sessions permanent owner update"
on public.ai_chat_sessions for update to authenticated
using (
  auth.uid() = user_id
  and not coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false)
)
with check (
  auth.uid() = user_id
  and not coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false)
);

create policy "ai sessions permanent owner delete"
on public.ai_chat_sessions for delete to authenticated
using (
  auth.uid() = user_id
  and not coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false)
);

drop policy if exists "ai messages owner select" on public.ai_chat_messages;
drop policy if exists "ai messages owner insert" on public.ai_chat_messages;
drop policy if exists "ai messages owner delete" on public.ai_chat_messages;

create policy "ai messages permanent owner select"
on public.ai_chat_messages for select to authenticated
using (
  auth.uid() = user_id
  and not coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false)
);

create policy "ai messages permanent owner insert"
on public.ai_chat_messages for insert to authenticated
with check (
  auth.uid() = user_id
  and not coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false)
  and exists (
    select 1
    from public.ai_chat_sessions session
    where session.id = session_id and session.user_id = auth.uid()
  )
);

create policy "ai messages permanent owner delete"
on public.ai_chat_messages for delete to authenticated
using (
  auth.uid() = user_id
  and not coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false)
);

drop policy if exists "ai message movies owner select"
  on public.ai_message_movies;
drop policy if exists "ai message movies owner insert"
  on public.ai_message_movies;
drop policy if exists "ai message movies owner delete"
  on public.ai_message_movies;

create policy "ai message movies permanent owner select"
on public.ai_message_movies for select to authenticated
using (
  exists (
    select 1
    from public.ai_chat_messages message
    where message.id = message_id
      and message.user_id = auth.uid()
      and not coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false)
  )
);

create policy "ai message movies permanent owner insert"
on public.ai_message_movies for insert to authenticated
with check (
  exists (
    select 1
    from public.ai_chat_messages message
    where message.id = message_id
      and message.user_id = auth.uid()
      and not coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false)
  )
);

create policy "ai message movies permanent owner delete"
on public.ai_message_movies for delete to authenticated
using (
  exists (
    select 1
    from public.ai_chat_messages message
    where message.id = message_id
      and message.user_id = auth.uid()
      and not coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false)
  )
);

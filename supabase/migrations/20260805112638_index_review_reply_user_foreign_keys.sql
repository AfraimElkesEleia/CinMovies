create index if not exists review_replies_user_id_idx
  on public.review_replies (user_id);

create index if not exists reply_reactions_user_id_idx
  on public.reply_reactions (user_id);

CREATE EXTENSION IF NOT EXISTS "pg_graphql";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "plpgsql";
CREATE EXTENSION IF NOT EXISTS "supabase_vault";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";
BEGIN;

--
-- PostgreSQL database dump
--


-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--



--
-- Name: app_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.app_role AS ENUM (
    'admin',
    'moderator',
    'user'
);


--
-- Name: generate_short_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_short_id() RETURNS text
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
  chars TEXT := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..6 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$;


--
-- Name: get_or_create_short_id(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_or_create_short_id(p_article_id uuid) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_short_id TEXT;
BEGIN
  -- Try to find existing
  SELECT short_id INTO v_short_id FROM moderation_short_ids WHERE article_id = p_article_id;
  
  IF v_short_id IS NOT NULL THEN
    RETURN v_short_id;
  END IF;
  
  -- Generate new unique short ID
  LOOP
    v_short_id := generate_short_id();
    BEGIN
      INSERT INTO moderation_short_ids (short_id, article_id) VALUES (v_short_id, p_article_id);
      RETURN v_short_id;
    EXCEPTION WHEN unique_violation THEN
      -- Try again with new short ID
    END;
  END LOOP;
END;
$$;


--
-- Name: has_role(uuid, public.app_role); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.has_role(_user_id uuid, _role public.app_role) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND role = _role
  )
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


SET default_table_access_method = heap;

--
-- Name: admin_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    key text NOT NULL,
    value text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: article_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.article_comments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    article_id uuid NOT NULL,
    author_id uuid NOT NULL,
    body text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: article_favorites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.article_favorites (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    article_id uuid NOT NULL,
    user_profile_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: article_likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.article_likes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    article_id uuid NOT NULL,
    user_profile_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: article_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.article_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    article_id uuid NOT NULL,
    reporter_profile_id uuid NOT NULL,
    reason text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    reviewed_at timestamp with time zone,
    reviewed_by_telegram_id bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: articles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.articles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    author_id uuid,
    category_id text,
    title text NOT NULL,
    preview text,
    body text NOT NULL,
    media_url text,
    media_type text,
    is_anonymous boolean DEFAULT false,
    status text DEFAULT 'pending'::text,
    rejection_reason text,
    likes_count integer DEFAULT 0,
    comments_count integer DEFAULT 0,
    favorites_count integer DEFAULT 0,
    rep_score integer DEFAULT 0,
    allow_comments boolean DEFAULT true,
    telegram_message_id bigint,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    topic text,
    sources text[],
    pending_edit jsonb,
    edited_at timestamp with time zone,
    CONSTRAINT articles_media_type_check CHECK ((media_type = ANY (ARRAY['image'::text, 'youtube'::text]))),
    CONSTRAINT articles_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'pending'::text, 'approved'::text, 'rejected'::text])))
);


--
-- Name: moderation_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.moderation_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    article_id uuid NOT NULL,
    moderator_telegram_id bigint NOT NULL,
    action character varying(20) NOT NULL,
    reason text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT moderation_logs_action_check CHECK (((action)::text = ANY (ARRAY[('approved'::character varying)::text, ('rejected'::character varying)::text])))
);


--
-- Name: moderation_short_ids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.moderation_short_ids (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    short_id character varying(8) NOT NULL,
    article_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    expires_at timestamp with time zone DEFAULT (now() + '7 days'::interval)
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_profile_id uuid NOT NULL,
    type text NOT NULL,
    message text NOT NULL,
    article_id uuid,
    from_user_id uuid,
    is_read boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: pending_rejections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pending_rejections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_telegram_id bigint NOT NULL,
    article_id uuid NOT NULL,
    short_id character varying(8) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: playlists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.playlists (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    service text NOT NULL,
    category text NOT NULL,
    title text NOT NULL,
    url text NOT NULL,
    cover_urls text[] DEFAULT '{}'::text[],
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT playlists_category_check CHECK ((category = ANY (ARRAY['motivation'::text, 'workout'::text, 'self-development'::text]))),
    CONSTRAINT playlists_service_check CHECK ((service = ANY (ARRAY['spotify'::text, 'soundcloud'::text, 'yandex'::text])))
);


--
-- Name: podcasts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.podcasts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    youtube_url text NOT NULL,
    youtube_id text NOT NULL,
    title text NOT NULL,
    description text,
    thumbnail_url text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    telegram_id bigint,
    username text,
    first_name text,
    last_name text,
    avatar_url text,
    reputation integer DEFAULT 0,
    is_premium boolean DEFAULT false,
    telegram_channel text,
    website text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    show_avatar boolean DEFAULT true NOT NULL,
    show_name boolean DEFAULT true NOT NULL,
    show_username boolean DEFAULT true NOT NULL,
    premium_expires_at timestamp with time zone,
    is_blocked boolean DEFAULT false NOT NULL,
    blocked_at timestamp with time zone
);


--
-- Name: reputation_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reputation_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    from_user_id uuid,
    article_id uuid,
    value integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT reputation_history_value_check CHECK ((value = ANY (ARRAY['-1'::integer, 1])))
);


--
-- Name: support_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.support_questions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_telegram_id bigint NOT NULL,
    user_profile_id uuid,
    question text NOT NULL,
    answer text,
    answered_by_telegram_id bigint,
    admin_message_id bigint,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    answered_at timestamp with time zone
);


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    role public.app_role NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: admin_settings admin_settings_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_settings
    ADD CONSTRAINT admin_settings_key_key UNIQUE (key);


--
-- Name: admin_settings admin_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_settings
    ADD CONSTRAINT admin_settings_pkey PRIMARY KEY (id);


--
-- Name: article_comments article_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_comments
    ADD CONSTRAINT article_comments_pkey PRIMARY KEY (id);


--
-- Name: article_favorites article_favorites_article_id_user_profile_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_favorites
    ADD CONSTRAINT article_favorites_article_id_user_profile_id_key UNIQUE (article_id, user_profile_id);


--
-- Name: article_favorites article_favorites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_favorites
    ADD CONSTRAINT article_favorites_pkey PRIMARY KEY (id);


--
-- Name: article_likes article_likes_article_id_user_profile_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_likes
    ADD CONSTRAINT article_likes_article_id_user_profile_id_key UNIQUE (article_id, user_profile_id);


--
-- Name: article_likes article_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_likes
    ADD CONSTRAINT article_likes_pkey PRIMARY KEY (id);


--
-- Name: article_reports article_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_reports
    ADD CONSTRAINT article_reports_pkey PRIMARY KEY (id);


--
-- Name: articles articles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_pkey PRIMARY KEY (id);


--
-- Name: moderation_logs moderation_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderation_logs
    ADD CONSTRAINT moderation_logs_pkey PRIMARY KEY (id);


--
-- Name: moderation_short_ids moderation_short_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderation_short_ids
    ADD CONSTRAINT moderation_short_ids_pkey PRIMARY KEY (id);


--
-- Name: moderation_short_ids moderation_short_ids_short_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderation_short_ids
    ADD CONSTRAINT moderation_short_ids_short_id_key UNIQUE (short_id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: pending_rejections pending_rejections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pending_rejections
    ADD CONSTRAINT pending_rejections_pkey PRIMARY KEY (id);


--
-- Name: playlists playlists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.playlists
    ADD CONSTRAINT playlists_pkey PRIMARY KEY (id);


--
-- Name: podcasts podcasts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.podcasts
    ADD CONSTRAINT podcasts_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_telegram_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_telegram_id_key UNIQUE (telegram_id);


--
-- Name: reputation_history reputation_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reputation_history
    ADD CONSTRAINT reputation_history_pkey PRIMARY KEY (id);


--
-- Name: support_questions support_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_questions
    ADD CONSTRAINT support_questions_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_user_id_role_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_role_key UNIQUE (user_id, role);


--
-- Name: idx_article_comments_article; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_article_comments_article ON public.article_comments USING btree (article_id);


--
-- Name: idx_article_favorites_article; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_article_favorites_article ON public.article_favorites USING btree (article_id);


--
-- Name: idx_article_favorites_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_article_favorites_user ON public.article_favorites USING btree (user_profile_id);


--
-- Name: idx_article_likes_article; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_article_likes_article ON public.article_likes USING btree (article_id);


--
-- Name: idx_article_likes_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_article_likes_user ON public.article_likes USING btree (user_profile_id);


--
-- Name: idx_article_reports_article_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_article_reports_article_id ON public.article_reports USING btree (article_id);


--
-- Name: idx_article_reports_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_article_reports_status ON public.article_reports USING btree (status);


--
-- Name: idx_moderation_logs_article; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_moderation_logs_article ON public.moderation_logs USING btree (article_id);


--
-- Name: idx_moderation_short_ids_article_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_moderation_short_ids_article_id ON public.moderation_short_ids USING btree (article_id);


--
-- Name: idx_moderation_short_ids_short_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_moderation_short_ids_short_id ON public.moderation_short_ids USING btree (short_id);


--
-- Name: idx_notifications_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_created_at ON public.notifications USING btree (created_at DESC);


--
-- Name: idx_notifications_user_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user_profile_id ON public.notifications USING btree (user_profile_id);


--
-- Name: idx_pending_rejections_admin; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_pending_rejections_admin ON public.pending_rejections USING btree (admin_telegram_id);


--
-- Name: idx_profiles_is_blocked; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_is_blocked ON public.profiles USING btree (is_blocked);


--
-- Name: articles update_articles_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_articles_updated_at BEFORE UPDATE ON public.articles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: playlists update_playlists_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_playlists_updated_at BEFORE UPDATE ON public.playlists FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: podcasts update_podcasts_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_podcasts_updated_at BEFORE UPDATE ON public.podcasts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: profiles update_profiles_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: article_comments article_comments_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_comments
    ADD CONSTRAINT article_comments_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: article_comments article_comments_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_comments
    ADD CONSTRAINT article_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: article_favorites article_favorites_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_favorites
    ADD CONSTRAINT article_favorites_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: article_favorites article_favorites_user_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_favorites
    ADD CONSTRAINT article_favorites_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: article_likes article_likes_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_likes
    ADD CONSTRAINT article_likes_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: article_likes article_likes_user_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_likes
    ADD CONSTRAINT article_likes_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: article_reports article_reports_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_reports
    ADD CONSTRAINT article_reports_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: article_reports article_reports_reporter_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_reports
    ADD CONSTRAINT article_reports_reporter_profile_id_fkey FOREIGN KEY (reporter_profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: articles articles_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: moderation_logs moderation_logs_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderation_logs
    ADD CONSTRAINT moderation_logs_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: moderation_short_ids moderation_short_ids_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderation_short_ids
    ADD CONSTRAINT moderation_short_ids_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_from_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_from_user_id_fkey FOREIGN KEY (from_user_id) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: notifications notifications_user_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: pending_rejections pending_rejections_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pending_rejections
    ADD CONSTRAINT pending_rejections_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: profiles profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: reputation_history reputation_history_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reputation_history
    ADD CONSTRAINT reputation_history_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;


--
-- Name: reputation_history reputation_history_from_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reputation_history
    ADD CONSTRAINT reputation_history_from_user_id_fkey FOREIGN KEY (from_user_id) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: reputation_history reputation_history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reputation_history
    ADD CONSTRAINT reputation_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: support_questions support_questions_user_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_questions
    ADD CONSTRAINT support_questions_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.profiles(id);


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: articles Admins can update any article; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update any article" ON public.articles FOR UPDATE USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: articles Admins can view all articles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can view all articles" ON public.articles FOR SELECT USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: user_roles Admins can view all roles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can view all roles" ON public.user_roles FOR SELECT USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: articles Approved articles are viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Approved articles are viewable by everyone" ON public.articles FOR SELECT USING ((status = 'approved'::text));


--
-- Name: article_comments Comments are viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Comments are viewable by everyone" ON public.article_comments FOR SELECT USING (true);


--
-- Name: article_favorites Favorites are viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Favorites are viewable by everyone" ON public.article_favorites FOR SELECT USING (true);


--
-- Name: article_likes Likes are viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Likes are viewable by everyone" ON public.article_likes FOR SELECT USING (true);


--
-- Name: admin_settings Only admins can access settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only admins can access settings" ON public.admin_settings USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: playlists Playlists are viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Playlists are viewable by everyone" ON public.playlists FOR SELECT USING (true);


--
-- Name: podcasts Podcasts are viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Podcasts are viewable by everyone" ON public.podcasts FOR SELECT USING (true);


--
-- Name: profiles Profiles are viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);


--
-- Name: articles Service role can delete articles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role can delete articles" ON public.articles FOR DELETE USING (true);


--
-- Name: articles Service role can insert articles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role can insert articles" ON public.articles FOR INSERT TO service_role WITH CHECK (true);


--
-- Name: profiles Service role can insert profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role can insert profiles" ON public.profiles FOR INSERT TO service_role WITH CHECK (true);


--
-- Name: article_comments Service role can manage comments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role can manage comments" ON public.article_comments USING (true) WITH CHECK (true);


--
-- Name: article_favorites Service role can manage favorites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role can manage favorites" ON public.article_favorites USING (true) WITH CHECK (true);


--
-- Name: article_likes Service role can manage likes; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role can manage likes" ON public.article_likes USING (true) WITH CHECK (true);


--
-- Name: notifications Service role can manage notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role can manage notifications" ON public.notifications USING (true) WITH CHECK (true);


--
-- Name: playlists Service role can manage playlists; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role can manage playlists" ON public.playlists USING (true) WITH CHECK (true);


--
-- Name: podcasts Service role can manage podcasts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role can manage podcasts" ON public.podcasts USING (true) WITH CHECK (true);


--
-- Name: article_reports Service role can manage reports; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role can manage reports" ON public.article_reports USING (true) WITH CHECK (true);


--
-- Name: articles Service role can update articles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role can update articles" ON public.articles FOR UPDATE TO service_role USING (true) WITH CHECK (true);


--
-- Name: profiles Service role can update profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role can update profiles" ON public.profiles FOR UPDATE TO service_role USING (true) WITH CHECK (true);


--
-- Name: moderation_logs Service role only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role only" ON public.moderation_logs USING (false);


--
-- Name: moderation_short_ids Service role only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role only" ON public.moderation_short_ids USING (false);


--
-- Name: pending_rejections Service role only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role only" ON public.pending_rejections USING (false);


--
-- Name: reputation_history Service role only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role only" ON public.reputation_history TO service_role USING (true) WITH CHECK (true);


--
-- Name: support_questions Service role only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role only" ON public.support_questions USING (false) WITH CHECK (true);


--
-- Name: notifications Users can view own notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (true);


--
-- Name: user_roles Users can view own roles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own roles" ON public.user_roles FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: article_reports Users can view their own reports; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own reports" ON public.article_reports FOR SELECT USING ((reporter_profile_id IN ( SELECT profiles.id
   FROM public.profiles
  WHERE (profiles.telegram_id IS NOT NULL))));


--
-- Name: admin_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: article_comments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.article_comments ENABLE ROW LEVEL SECURITY;

--
-- Name: article_favorites; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.article_favorites ENABLE ROW LEVEL SECURITY;

--
-- Name: article_likes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.article_likes ENABLE ROW LEVEL SECURITY;

--
-- Name: article_reports; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.article_reports ENABLE ROW LEVEL SECURITY;

--
-- Name: articles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;

--
-- Name: moderation_logs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.moderation_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: moderation_short_ids; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.moderation_short_ids ENABLE ROW LEVEL SECURITY;

--
-- Name: notifications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

--
-- Name: pending_rejections; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pending_rejections ENABLE ROW LEVEL SECURITY;

--
-- Name: playlists; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.playlists ENABLE ROW LEVEL SECURITY;

--
-- Name: podcasts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.podcasts ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: reputation_history; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.reputation_history ENABLE ROW LEVEL SECURITY;

--
-- Name: support_questions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.support_questions ENABLE ROW LEVEL SECURITY;

--
-- Name: user_roles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--




COMMIT;
# CLAUDE.md

Vokabelheft: a vocabulary trainer for German speakers, originally English for kids; now supports multiple vocabulary sets ("decks") in any language, assigned per person. Static PWA hosted on GitHub Pages, data in Supabase (Frankfurt region). Kids log in with username + 6-digit PIN; only the admin edits vocabulary.

## Stack and constraints

- **No build step, no package manager, no framework.** Plain HTML/CSS/vanilla JS. Each page has one inline `<script>` wrapped in an IIFE. Edit files directly; deploy = push to the Pages branch.
- **No third-party requests besides Supabase.** The Supabase JS client is vendored as [lib/supabase.js](lib/supabase.js) (v2.117.3, minified UMD, exposes `window.supabase`). Don't swap it for a CDN link and don't edit it by hand.
- **UI copy, code comments and user docs are in German.** Keep it that way. The audience is children, so messages are short, friendly and use "du".
- No tests or linter. To try it locally, serve the folder (e.g. `python3 -m http.server`) and open `index.html` / `admin.html`; it talks to the real Supabase project in [config.js](config.js).

## Files

| File | Role |
|---|---|
| [index.html](index.html) | Kids' app: login, practice (write / flashcards), word list, profile |
| [admin.html](admin.html) | Admin: kids overview, edit/delete/add words, JSON import with preview |
| [config.js](config.js) | `window.VOKABELHEFT_CONFIG` = Supabase URL, publishable (anon) key, `emailDomain`. The anon key is public by design; never put the service_role key here |
| [style.css](style.css) | Shared styles for both pages |
| [sw.js](sw.js) | Service worker, network-first with cache fallback for same-origin GETs only |
| [supabase/schema.sql](supabase/schema.sql) | Tables, RLS policies, signup trigger, `progress_overview` view. Idempotent; run in SQL Editor |
| [supabase/seed.sql](supabase/seed.sql) | Initial 131 words (Units 1–6). Re-runnable |
| [README.md](README.md) | German setup guide for the owner (Supabase, Pages, iPad, adding words) |
| `vocab.json`, `ANLEITUNG.md` | **Legacy** from the earlier offline-only/Netlify version. Not loaded by the current app |

## Data model (Supabase)

- `decks(id text pk, name, lang, lang_name, sort)`. `lang` is a BCP-47 code for speech synthesis, `lang_name` the label in the UI ("Was heißt das auf Französisch?"). The default deck is `englisch`.
- `deck_access(user_id, deck_id)`: which person sees which deck. Admins see all decks via `can_see_deck()` (security definer). A new user sees nothing until assigned.
- `vocab(id text pk, deck → decks, unit text, en, de, sort int)`. **`en` holds the foreign-language word for every deck** (historical name, also used in the import JSON). `id` is a stable slug like `u3-my-family` (`"u" + slug(unit) + "-" + slug(en)`, deduped with `-2`, `-3`…). **Ids must stay stable**: progress references them, and deleting a word cascades its progress away.
- `profiles(id → auth.users, username, display_name, role 'kid'|'admin')`. Created automatically by the `on_auth_user_created` trigger from the email's local part.
- `progress(user_id, word_id, box 1–5, right_count, wrong_count, last_seen)`, pk `(user_id, word_id)`.
- `progress_overview` view (security_invoker) feeds the admin kids table.
- RLS: kids read decks/vocab they have `deck_access` for, read their own profile, read/write their own progress. Admin (`is_admin()`, security definer) writes vocab, reads all, updates display names. `anon` gets nothing.

Auth: users are created by hand in the Supabase dashboard as `<username>@vokabelheft.local` (signups disabled, no email confirmation). The app appends `CFG.emailDomain` to the typed username. Admin login also accepts a full email.

If you change the schema, update `schema.sql` so it stays idempotent (`if not exists`, `drop policy if exists` before `create policy`), and mention the manual migration step in README.md, since there's no migration tooling.

## index.html internals

- **Offline-first state in localStorage**, all keys prefixed `vh.` via the `LS` helper, all per user: `u.<uid>.profile|vocab|decks|deck|progress|queue|migrated` and `u.<uid>.units.<deckId>`. (The old device-wide `vh.vocab` key is deleted on login, since different users may see different decks.)
- **Decks**: `vocab` holds all words the user may see; `words()` filters to the current `deckId`, `curDeck()` gives its language. Deck chips only show when there's more than one deck. `ensureDeck()` falls back to the first deck when the saved one disappeared. Supabase auth session uses storageKey `vh.auth`.
- **Load**: show cached data immediately, then `refreshFromServer()` fetches profile/vocab/progress in parallel. Queued local results override server rows.
- **Save**: `record()` updates `progress` and puts the row into `queue`; `flush()` upserts the queue (debounced 1.5 s, also on `online` and when the page is hidden). Entries are only removed from the queue if they didn't change during the upload. The header pill shows "gespeichert" or "N wartet auf Internet". Logout warns once if the queue isn't empty.
- **Leitner boxes 1–5**: correct → box+1, "near" (typo) → unchanged, wrong → box 1. Box ≥ 4 counts as "sitzt".
- **Round selection** (`pickRound`): 10 words from the selected units, weighted random sampling (`random^(1/w)`) with `w = 2^(5-box)`, ×1.5 for unseen words, ×0.3 if seen in the last 10 minutes.
- **Answer checking** (`judge`): `norm()` lowercases, strips punctuation, unifies apostrophes; for English decks only it also expands contractions (`CONTR`) and maps US→UK spellings (color/favorite/mom). Alternatives in `en` are separated by ` / `. Levenshtein distance 1 (len ≥ 4) or 2 (len ≥ 12) counts as `"near"`.
- Views are `<section id="view-*">` toggled via `show()`. `S` holds the running session; when it's non-null, the app doesn't refresh vocab on visibility change.
- `checkMigration()` / `migrateFrom()` import progress from the old local-only version (`vh.profiles`, `vh.p.<id>`) once per user.
- Speech: `speechSynthesis` with the deck's `lang` (exact voice match, else same language prefix), reads only the first alternative.

## admin.html internals

- Checks `profiles.role === 'admin'` client-side for the UI. Actual enforcement is RLS.
- Sections: Vokabelsets (create/rename/delete; delete refused while the deck has words), Kinder (per-kid deck checkboxes write `deck_access`), import, word table (filtered by deck, then unit).
- Inline edits save on `change`. Delete needs two clicks ("Wirklich?").
- **Import** goes into the deck chosen in `importDeck` and accepts a JSON array or `{unit?, words:[...]}`, with or without ```` ``` ```` fences. Each word needs `en`, `de`, optionally `unit` and `id`. It matches existing words in that deck by `id` or by `unit|en` (case-insensitive) and classifies them as `neu` / `ändern` / `gleich`, then upserts everything except `gleich`. This is the format the owner gets from Claude when they photograph new textbook pages.

## When changing things

- **Bump `CACHE` in [sw.js](sw.js)** (`vokabelheft-db-vN`) whenever you add or rename app files, and keep the `APP` list in sync. Otherwise installed iPad PWAs keep serving stale assets.
- Keep both pages working offline-tolerant and iPad Safari/home-screen compatible (no APIs that fail in standalone mode, wrap storage in try/catch as the existing code does).
- Escape any user/DB text inserted via `innerHTML` with `esc()`.
- Privacy is a stated goal (README "Wer darf was"): store only username, display name and per-word progress. Don't add analytics, real emails, or external resources.

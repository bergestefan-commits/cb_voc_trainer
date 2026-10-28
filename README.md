# Vokabelheft

Englisch-Vokabeltrainer für Kinder. Die Web-App liegt auf GitHub Pages, Vokabeln und Lernstand in Supabase (Region Frankfurt).
Die Kinder melden sich mit Benutzername und PIN an. Neue Vokabeln pflegt nur der Admin.

## Was wo liegt

| Datei | Zweck |
|---|---|
| `index.html` | App für die Kinder (Üben, Wörter, Profil) |
| `admin.html` | Verwaltung: Vokabeln importieren und bearbeiten, Übersicht der Kinder |
| `config.js` | Supabase-Adresse und öffentlicher Schlüssel, **musst du ausfüllen** |
| `style.css`, `sw.js`, `manifest.webmanifest`, `icon-*.png` | Aussehen, Offline-Modus, App-Symbol |
| `lib/supabase.js` | Supabase-Bibliothek (v2.117.3), lokal abgelegt, damit nichts von fremden Servern geladen wird |
| `supabase/schema.sql` | Tabellen und Zugriffsregeln |
| `supabase/seed.sql` | Die 131 Vokabeln aus Unit 1–6 |

---

zukraj-tewpen-4dAbbo


## 1. Supabase einrichten (ca. 15 Minuten)

1. Auf https://supabase.com ein Konto anlegen und **New project** wählen.
   - Region: **Central EU (Frankfurt)**
   - Ein starkes Datenbank-Passwort vergeben und gut aufbewahren.
2. **SQL Editor → New query**: Inhalt von `supabase/schema.sql` einfügen und auf **Run** klicken.
   Danach das Gleiche mit `supabase/seed.sql`.
3. **Authentication → Sign In / Providers → Email**:
   - **Allow new users to sign up**: aus. Dann kann sich niemand selbst registrieren, nur du legst Konten an.
   - **Confirm email**: aus. Die Adressen sind ja nicht echt.
4. **Dein Admin-Konto:** Unter **Authentication → Users → Add user → Create new user**
   - E-Mail: `stefan@vokabelheft.local`, Passwort: ein starkes Passwort, **Auto Confirm User** anhaken.
   - Danach im SQL Editor ausführen:
     ```sql
     update public.profiles set role = 'admin' where username = 'stefan';
     ```
5. **Kinder anlegen** (für jedes Kind):
   - **Add user → Create new user**, E-Mail: `clara@vokabelheft.local`, Passwort: eine **6-stellige PIN**, **Auto Confirm User** anhaken.
   - Der Benutzername ist der Teil vor dem @, der Anzeigename wird automatisch „Clara“. Ändern kannst du ihn in `admin.html`.
6. **Project Settings → API Keys**: Die **Project URL** und den **publishable** bzw. **anon public** Key kopieren
   und in `config.js` eintragen. Den **secret/service_role** Key **niemals** dort eintragen.

## 2. Auf GitHub Pages veröffentlichen

1. Neues Repository anlegen, z. B. `vokabelheft`, und alle Dateien dieses Ordners hochladen.
2. **Settings → Pages → Build and deployment → Deploy from a branch → `main` / `(root)`**.
3. Nach ein bis zwei Minuten ist die App erreichbar unter `https://<dein-github-name>.github.io/vokabelheft/`.
   Hast du für deine Website eine eigene Domain eingerichtet, liegt die App unter `https://<deine-domain>/vokabelheft/`.

Der Schlüssel in `config.js` ist öffentlich lesbar. Das ist so vorgesehen: Ohne Login sieht man damit nichts,
und die Zugriffsregeln in der Datenbank legen fest, wer was darf.

## 3. Aufs iPad

1. Die Adresse in **Safari** öffnen, dann **Teilen → Zum Home-Bildschirm**.
2. Die App über das neue Symbol öffnen und mit Benutzername und PIN anmelden.
3. Der Login bleibt gespeichert. Teilen sich mehrere Kinder ein iPad: unter **Ich → Abmelden**, dann meldet sich das nächste an.
4. Gibt es auf dem iPad noch Lernstand aus der alten Version ohne Datenbank, fragt die App nach dem ersten Login einmal, ob er übernommen werden soll.

## 4. Neue Vokabeln

1. Schick Claude Fotos der neuen Heftseiten. Du bekommst eine JSON-Liste zurück.
2. Öffne `…/vokabelheft/admin.html`, melde dich als `stefan` an und füge die Liste unter **Vokabeln importieren** ein.
3. Mit **Vorschau** prüfen, dann **Importieren**. Die Kinder bekommen die Wörter beim nächsten Öffnen der App.

Einzelne Wörter kannst du in der Tabelle direkt korrigieren oder löschen.
Mehrere richtige Antworten trennst du mit ` / `, z. B. `grandad / grandfather`.

## Wer darf was

| | Vokabeln | Profile | Lernstand |
|---|---|---|---|
| Kind | lesen | nur eigenes lesen | nur eigenen lesen und schreiben |
| Admin | lesen und schreiben | alle lesen, Namen ändern | alle lesen |
| Nicht angemeldet | nichts | nichts | nichts |

Gespeichert werden pro Kind nur Benutzername, Anzeigename und Lernstand pro Wort (Stufe, richtig/falsch, zuletzt geübt).
Keine echten E-Mail-Adressen, keine Fotos, keine Geräte-Daten.

## Wenn Supabase pausiert

Kostenlose Supabase-Projekte werden nach einer Woche ohne Nutzung pausiert. Die App läuft dann trotzdem weiter:
Die Vokabeln sind auf dem iPad zwischengespeichert, und neue Ergebnisse warten, bis die Datenbank wieder erreichbar ist
(oben rechts steht dann „… wartet auf Internet“). Zum Fortsetzen im Supabase-Dashboard auf **Restore project** klicken.

## Sicherung

Ab und zu unter **Table Editor → vocab / progress → Export → CSV** eine Kopie ziehen.

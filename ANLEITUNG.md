# Vokabelheft – so bringst du die App aufs Tablet

## 1. Einmal hochladen (kostenlos, ca. 5 Minuten)
1. Öffne https://app.netlify.com/drop am Computer.
2. Zieh den ganzen Ordner `vokabel-app` (entpackt) in das Feld.
3. Netlify zeigt dir eine Adresse, z. B. `https://xyz-123.netlify.app`.
   Unter „Site configuration → Change site name“ kannst du sie umbenennen, z. B. `claras-vokabeln`.
   Ein kostenloses Netlify-Konto brauchst du, damit die Seite dauerhaft bleibt. Das ist dein Konto, nicht Claras.

## 2. Auf Claras Gerät installieren
- **iPad/iPhone:** Adresse in Safari öffnen → Teilen-Symbol → „Zum Home-Bildschirm“.
- **Android:** Adresse in Chrome öffnen → Menü ⋮ → „App installieren“ / „Zum Startbildschirm“.

Ab dann funktioniert die App auch offline. Beim ersten Start gibt Clara ihren Vornamen ein.
Freundinnen öffnen denselben Link auf ihrem Gerät und legen ihr eigenes Profil an.

## 3. Neue Vokabeln hinzufügen
Neue Heftseiten fotografierst du in Claude. Claude erzeugt daraus eine neue `vocab.json`.
Ersetze die Datei im Ordner und zieh den Ordner erneut in Netlify
(„Deploys“ → Ordner in das Feld ziehen). Alle Geräte bekommen die neuen Wörter beim nächsten Öffnen mit Internet.
Der Lernstand bleibt dabei erhalten.

## Gut zu wissen
- Lernstand und Namen werden nur auf dem jeweiligen Gerät gespeichert, nirgends sonst.
- Wird die App vom Gerät gelöscht oder werden die Browserdaten gelöscht, ist der Lernstand weg.
  Die Vokabeln kommen beim nächsten Öffnen wieder.
- Auf iPad/iPhone die App immer über das Symbol auf dem Home-Bildschirm öffnen, nicht über Safari.
  Nur dort bleiben die Daten dauerhaft gespeichert.

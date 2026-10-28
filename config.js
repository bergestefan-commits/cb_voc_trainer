// Trage hier die Werte aus Supabase ein:
// Project Settings → API → "Project URL" und "anon public" Key.
// Der anon-Key darf öffentlich sein: Die Zugriffsregeln in der Datenbank schützen die Daten.
window.VOKABELHEFT_CONFIG = {
  supabaseUrl: "https://DEIN-PROJEKT.supabase.co",
  supabaseAnonKey: "DEIN-ANON-KEY",
  // Kinder werden in Supabase als <benutzername>@vokabelheft.local angelegt.
  emailDomain: "vokabelheft.local"
};

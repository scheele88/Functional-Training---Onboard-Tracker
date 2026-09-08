// Supabase connection settings for the Olefins Section Onboarding & Qualification Tracker.
// This file is intentionally separate from index.html so the credentials can be committed
// to a public GitHub repo without exposing anything sensitive — the Supabase "anon" key is
// safe to publish; it only grants the access defined by the database's Row Level Security
// policies (see migration.sql), which for this app allow read/write to the onb_people and
// onb_settings tables only. There is no server-side secret in this app.

window.SUPABASE_URL = "https://wybpexwcrngodkvrrifr.supabase.co";
window.SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5YnBleHdjcm5nb2RrdnJyaWZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcwMjgzOTksImV4cCI6MjEwMjYwNDM5OX0.s4wQQyZH9zwS5QVyfz8TCH4BhA-Qa0J4GgXLgI70I5c";

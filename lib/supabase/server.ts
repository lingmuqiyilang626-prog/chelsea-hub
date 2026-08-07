import "server-only";

import { createClient } from "@supabase/supabase-js";

function getRequiredEnvironmentVariable(name: string) {
  const value = process.env[name];

  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
}

export function createServerSupabaseClient() {
  return createClient(
    getRequiredEnvironmentVariable("SUPABASE_URL"),
    getRequiredEnvironmentVariable("SUPABASE_PUBLISHABLE_KEY"),
    {
      auth: {
        autoRefreshToken: false,
        detectSessionInUrl: false,
        persistSession: false,
      },
    },
  );
}

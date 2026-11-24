import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

serve(async (req: Request) => {
  if (req.method !== "POST" && req.method !== "GET") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  try {
    console.log("[ScheduleShiftReminders] Evaluating upcoming confirmed shifts in Asia/Kolkata...");
    const { data, error } = await supabase.rpc("schedule_shift_reminders");

    if (error) {
      console.error("[ScheduleShiftReminders] RPC error:", error);
      return new Response(JSON.stringify({ success: false, error: error.message }), { status: 500 });
    }

    console.log("[ScheduleShiftReminders] Result:", data);

    return new Response(JSON.stringify({ success: true, result: data }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("[ScheduleShiftReminders] Fatal error:", msg);
    return new Response(JSON.stringify({ success: false, error: msg }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

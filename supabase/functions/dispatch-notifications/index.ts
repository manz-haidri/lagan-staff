// Follow this setup guide to integrate the Supabase Edge Function with FCM HTTP v1
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
const FCM_SERVICE_ACCOUNT = Deno.env.get("FCM_SERVICE_ACCOUNT") || "";

interface DeviceTokenItem {
  device_id: string;
  fcm_token: string;
  platform: string;
}

interface OutboxBatchItem {
  outbox_id: string;
  event_key: string;
  event_type: string;
  recipient_user_id: string;
  title: string;
  body: string;
  payload: Record<string, unknown>;
  notification_channel: string;
  attempt_count: number;
  device_tokens: DeviceTokenItem[];
}

interface DeviceAttemptResult {
  device_id: string;
  fcm_message_id?: string;
  attempt_status: "accepted" | "failed" | "invalid_token";
  error_code?: string;
  error_message?: string;
  deactivate_token?: boolean;
}

/**
 * Generate Google OAuth2 Access Token from Service Account JSON using Web Crypto API
 */
async function getGoogleOAuth2AccessToken(serviceAccountJson: string): Promise<{ token: string; projectId: string }> {
  const sa = JSON.parse(serviceAccountJson);
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encodeBase64Url = (obj: Record<string, unknown>) => {
    const jsonStr = JSON.stringify(obj);
    const bytes = new TextEncoder().encode(jsonStr);
    let binary = "";
    bytes.forEach((b) => (binary += String.fromCharCode(b)));
    return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  };

  const strHeader = encodeBase64Url(header);
  const strClaim = encodeBase64Url(claim);
  const unsignedToken = `${strHeader}.${strClaim}`;

  // Clean PEM private key
  const pem = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");

  const binaryDer = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedToken)
  );

  let binarySig = "";
  new Uint8Array(signature).forEach((b) => (binarySig += String.fromCharCode(b)));
  const strSig = btoa(binarySig).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  const signedJwt = `${unsignedToken}.${strSig}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: signedJwt,
    }),
  });

  if (!tokenRes.ok) {
    const errorBody = await tokenRes.text();
    throw new Error(`Google OAuth2 token exchange failed: ${tokenRes.status} ${errorBody}`);
  }

  const tokenData = await tokenRes.json();
  return { token: tokenData.access_token, projectId: sa.project_id };
}

serve(async (req: Request) => {
  // Only accept POST
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  try {
    // 1. Claim pending outbox batch atomically
    const { data: batch, error: claimError } = await supabase.rpc("claim_pending_outbox_batch", {
      p_batch_size: 50,
    });

    if (claimError) {
      console.error("[Dispatch] Claim outbox error:", claimError);
      return new Response(JSON.stringify({ success: false, error: claimError.message }), { status: 500 });
    }

    const items: OutboxBatchItem[] = (batch || []) as OutboxBatchItem[];
    if (items.length === 0) {
      return new Response(JSON.stringify({ success: true, processed: 0, message: "No pending outbox notifications." }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    console.log(`[Dispatch] Processing ${items.length} outbox notifications.`);

    // 2. Validate Firebase credentials
    let accessToken = "";
    let fcmProjectId = "";
    let fcmConfigured = false;

    if (FCM_SERVICE_ACCOUNT && FCM_SERVICE_ACCOUNT.trim().startsWith("{")) {
      try {
        const authResult = await getGoogleOAuth2AccessToken(FCM_SERVICE_ACCOUNT);
        accessToken = authResult.token;
        fcmProjectId = authResult.projectId;
        fcmConfigured = true;
      } catch (authErr) {
        console.warn("[Dispatch] FCM Service Account auth error:", authErr);
      }
    }

    let successCount = 0;
    let failedCount = 0;

    // 3. Process each notification in batch
    for (const item of items) {
      const activeDevices = item.device_tokens || [];
      const deviceResults: DeviceAttemptResult[] = [];

      // If user has no registered active devices, mark as sent (in-app notification already persisted)
      if (activeDevices.length === 0) {
        await supabase.rpc("record_outbox_result", {
          p_outbox_id: item.outbox_id,
          p_status: "sent",
          p_error: "In-app record created. No active physical FCM device registered.",
          p_device_results: [],
        });
        successCount++;
        continue;
      }

      // If FCM service account is not yet configured in environment (preview/dry-run)
      if (!fcmConfigured) {
        for (const dev of activeDevices) {
          deviceResults.push({
            device_id: dev.device_id,
            attempt_status: "accepted",
            fcm_message_id: `demo-fcm-mock-${Date.now()}`,
          });
        }
        await supabase.rpc("record_outbox_result", {
          p_outbox_id: item.outbox_id,
          p_status: "sent",
          p_error: null,
          p_device_results: deviceResults,
        });
        successCount++;
        continue;
      }

      // FCM HTTP v1 dispatch to all active registered devices of user
      let anySuccess = false;
      let lastErrMsg = "";

      for (const dev of activeDevices) {
        try {
          const fcmPayload = {
            message: {
              token: dev.fcm_token,
              notification: {
                title: item.title,
                body: item.body,
              },
              data: {
                event_type: item.event_type,
                entity_type: String(item.payload.entity_type || ""),
                entity_id: String(item.payload.entity_id || ""),
                job_id: String(item.payload.job_id || ""),
                channel_id: item.notification_channel || "job_alerts",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
              },
              android: {
                priority: "high",
                notification: {
                  channel_id: item.notification_channel || "job_alerts",
                  default_sound: true,
                  default_vibrate_timings: true,
                },
              },
            },
          };

          const fcmRes = await fetch(
            `https://fcm.googleapis.com/v1/projects/${fcmProjectId}/messages:send`,
            {
              method: "POST",
              headers: {
                Authorization: `Bearer ${accessToken}`,
                "Content-Type": "application/json",
              },
              body: JSON.stringify(fcmPayload),
            }
          );

          if (fcmRes.ok) {
            const fcmData = await fcmRes.json();
            deviceResults.push({
              device_id: dev.device_id,
              fcm_message_id: fcmData.name,
              attempt_status: "accepted",
            });
            anySuccess = true;
          } else {
            const errBody = await fcmRes.text();
            let parsedErr: { error?: { status?: string; message?: string } } = {};
            try {
              parsedErr = JSON.parse(errBody);
            } catch {
              // ignore
            }

            const errStatus = parsedErr.error?.status || `HTTP_${fcmRes.status}`;
            const isInvalidToken =
              errStatus === "UNREGISTERED" ||
              errStatus === "INVALID_ARGUMENT" ||
              errBody.includes("Requested entity was not found");

            deviceResults.push({
              device_id: dev.device_id,
              attempt_status: isInvalidToken ? "invalid_token" : "failed",
              error_code: errStatus,
              error_message: parsedErr.error?.message || errBody,
              deactivate_token: isInvalidToken,
            });
            lastErrMsg = parsedErr.error?.message || errBody;
          }
        } catch (dispatchErr: unknown) {
          const msg = dispatchErr instanceof Error ? dispatchErr.message : String(dispatchErr);
          deviceResults.push({
            device_id: dev.device_id,
            attempt_status: "failed",
            error_code: "NETWORK_ERROR",
            error_message: msg,
          });
          lastErrMsg = msg;
        }
      }

      if (anySuccess) {
        await supabase.rpc("record_outbox_result", {
          p_outbox_id: item.outbox_id,
          p_status: "sent",
          p_error: null,
          p_device_results: deviceResults,
        });
        successCount++;
      } else {
        await supabase.rpc("record_outbox_result", {
          p_outbox_id: item.outbox_id,
          p_status: "retry_scheduled",
          p_error: lastErrMsg || "FCM dispatch rejected across all registered devices.",
          p_device_results: deviceResults,
        });
        failedCount++;
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        processed: items.length,
        dispatched: successCount,
        retries_scheduled: failedCount,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("[Dispatch] Fatal runner error:", msg);
    return new Response(JSON.stringify({ success: false, error: msg }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

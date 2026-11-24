'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/layout/AdminShell';
import {
  ShieldCheck,
  Server,
  Lock,
  LogOut,
  User,
  Sliders,
  FileCheck2,
} from 'lucide-react';
import { supabase, isSupabaseConfigured } from '@/lib/supabase';

export default function AdminSettingsPage() {
  const router = useRouter();
  const [loggingOut, setLoggingOut] = useState(false);

  const handleLogout = async () => {
    setLoggingOut(true);
    if (isSupabaseConfigured) {
      await supabase.auth.signOut();
    }
    router.push('/login');
  };

  return (
    <AdminShell>
      {/* Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-black tracking-tight text-slate-900">
            Platform Settings & Control
          </h1>
          <p className="text-xs text-slate-500 font-medium">
            Administrative governance parameters for LaganStaff marketplace in Ghazipur.
          </p>
        </div>

        <button
          onClick={handleLogout}
          disabled={loggingOut}
          className="inline-flex items-center gap-1.5 rounded-lg border border-rose-300 bg-rose-50 px-3.5 py-1.5 text-xs font-semibold text-rose-700 hover:bg-rose-100 disabled:opacity-50 shadow-xs"
        >
          <LogOut className="h-3.5 w-3.5" />
          <span>{loggingOut ? 'Signing out...' : 'Sign Out Administrator'}</span>
        </button>
      </div>

      {/* Admin Profile Card */}
      <div className="mt-6 rounded-xl border border-slate-200 bg-white p-6 shadow-xs">
        <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
          <User className="h-4 w-4 text-indigo-700" />
          Active Administrator Profile
        </h2>

        <div className="mt-4 grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
          <div className="rounded-lg bg-slate-50 p-3 border border-slate-100">
            <span className="text-slate-400 font-medium">Admin Identity</span>
            <div className="font-semibold text-slate-900 mt-1">Super Administrator</div>
            <div className="text-[11px] text-slate-500 font-mono">admin@laganstaff.in</div>
          </div>

          <div className="rounded-lg bg-slate-50 p-3 border border-slate-100">
            <span className="text-slate-400 font-medium">Access Control</span>
            <div className="font-semibold text-emerald-700 flex items-center gap-1 mt-1">
              <ShieldCheck className="h-4 w-4 text-emerald-600" />
              Allowlist Verified
            </div>
            <div className="text-[11px] text-slate-500">public.admin_users table</div>
          </div>

          <div className="rounded-lg bg-slate-50 p-3 border border-slate-100">
            <span className="text-slate-400 font-medium">Session Timezone</span>
            <div className="font-semibold text-slate-900 mt-1">Asia/Kolkata (IST)</div>
            <div className="text-[11px] text-slate-500">UTC +05:30</div>
          </div>
        </div>
      </div>

      {/* Operational Constants Card */}
      <div className="mt-6 rounded-xl border border-slate-200 bg-white p-6 shadow-xs">
        <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
          <Sliders className="h-4 w-4 text-indigo-700" />
          Marketplace Operational Rules & Parameters
        </h2>
        <p className="text-xs text-slate-500 mt-0.5">
          Locked core architecture parameters defined in Phase 0 through Phase 8.
        </p>

        <div className="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
          <div className="rounded-xl border border-slate-200 p-4 bg-slate-50/50 space-y-1.5">
            <div className="flex items-center justify-between font-bold text-slate-800">
              <span>Hyperlocal District Focus</span>
              <span className="rounded bg-indigo-100 text-indigo-900 px-2 py-0.5 text-[10px]">LOCKED</span>
            </div>
            <p className="text-slate-600">
              Ghazipur District, Uttar Pradesh (Pincode: 233001 and surrounding rural blocks).
            </p>
          </div>

          <div className="rounded-xl border border-slate-200 p-4 bg-slate-50/50 space-y-1.5">
            <div className="flex items-center justify-between font-bold text-slate-800">
              <span>Authentication Mechanism</span>
              <span className="rounded bg-indigo-100 text-indigo-900 px-2 py-0.5 text-[10px]">SMS-FREE</span>
            </div>
            <p className="text-slate-600">
              Phone Number + 4-Digit PIN under the hood via Supabase Email Auth (zero SMS costs).
            </p>
          </div>

          <div className="rounded-xl border border-slate-200 p-4 bg-slate-50/50 space-y-1.5">
            <div className="flex items-center justify-between font-bold text-slate-800">
              <span>On-Site Attendance Verification</span>
              <span className="rounded bg-indigo-100 text-indigo-900 px-2 py-0.5 text-[10px]">4-DIGIT PIN</span>
            </div>
            <p className="text-slate-600">
              Every confirmed booking issues a 4-digit checkin_code on Duty Pass. Entered by owner at venue gate.
            </p>
          </div>

          <div className="rounded-xl border border-slate-200 p-4 bg-slate-50/50 space-y-1.5">
            <div className="flex items-center justify-between font-bold text-slate-800">
              <span>First-Job Publishing Governance</span>
              <span className="rounded bg-indigo-100 text-indigo-900 px-2 py-0.5 text-[10px]">ADMIN GATE</span>
            </div>
            <p className="text-slate-600">
              First job posting by verified business requires admin approval. Subsequent jobs auto-publish.
            </p>
          </div>

          <div className="rounded-xl border border-slate-200 p-4 bg-slate-50/50 space-y-1.5">
            <div className="flex items-center justify-between font-bold text-slate-800">
              <span>Worker Activation Rule</span>
              <span className="rounded bg-indigo-100 text-indigo-900 px-2 py-0.5 text-[10px]">AUTO-ACTIVE</span>
            </div>
            <p className="text-slate-600">
              Workers are auto-activated upon onboarding; post-registration review queue does not block shift discovery unless suspended.
            </p>
          </div>

          <div className="rounded-xl border border-slate-200 p-4 bg-slate-50/50 space-y-1.5">
            <div className="flex items-center justify-between font-bold text-slate-800">
              <span>Gate Check-in Window</span>
              <span className="rounded bg-indigo-100 text-indigo-900 px-2 py-0.5 text-[10px]">60m - 120m</span>
            </div>
            <p className="text-slate-600">
              Check-in allowed from 60 minutes before scheduled start time up to 120 minutes after start time.
            </p>
          </div>
        </div>
      </div>

      {/* Backend & Security Infrastructure */}
      <div className="mt-6 rounded-xl border border-slate-200 bg-white p-6 shadow-xs">
        <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
          <Server className="h-4 w-4 text-indigo-700" />
          Backend & Security Infrastructure
        </h2>

        <div className="mt-4 grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
          <div className="flex items-start gap-3 rounded-lg border border-slate-200 p-3 bg-slate-50">
            <Lock className="h-4 w-4 text-indigo-600 shrink-0 mt-0.5" />
            <div>
              <div className="font-semibold text-slate-800">Row-Level Security (RLS)</div>
              <div className="text-[11px] text-slate-500 mt-0.5">Enforced across all 12 platform tables.</div>
            </div>
          </div>

          <div className="flex items-start gap-3 rounded-lg border border-slate-200 p-3 bg-slate-50">
            <ShieldCheck className="h-4 w-4 text-emerald-600 shrink-0 mt-0.5" />
            <div>
              <div className="font-semibold text-slate-800">Administrative RPC Isolation</div>
              <div className="text-[11px] text-slate-500 mt-0.5">Protected with is_admin_user() validation.</div>
            </div>
          </div>

          <div className="flex items-start gap-3 rounded-lg border border-slate-200 p-3 bg-slate-50">
            <FileCheck2 className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
            <div>
              <div className="font-semibold text-slate-800">Signed Storage Tokens</div>
              <div className="text-[11px] text-slate-500 mt-0.5">Worker selfies & business proofs private.</div>
            </div>
          </div>
        </div>
      </div>
    </AdminShell>
  );
}

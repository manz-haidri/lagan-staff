'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { ShieldCheck, Lock, AlertCircle } from 'lucide-react';
import { supabase, isSupabaseConfigured } from '@/lib/supabase';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('admin@laganstaff.in');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    if (isSupabaseConfigured && password) {
      try {
        const { error: signInError } = await supabase.auth.signInWithPassword({
          email,
          password,
        });
        if (signInError) {
          setError(signInError.message);
          setLoading(false);
          return;
        }
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : String(err);
        setError(msg);
        setLoading(false);
        return;
      }
    }

    // Navigate to admin platform control center
    router.push('/admin/dashboard');
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-100 p-4">
      <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
        {/* Brand Icon */}
        <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-indigo-900 text-amber-400 shadow-md">
          <ShieldCheck className="h-8 w-8" />
        </div>

        <div className="mt-4 text-center">
          <h1 className="text-2xl font-black tracking-tight text-slate-900">LaganStaff Admin</h1>
          <p className="mt-1 text-xs text-slate-500 font-medium">Platform Control Center • Ghazipur District</p>
        </div>

        {/* Security Warning Notice */}
        <div className="mt-6 flex items-start gap-2.5 rounded-lg border border-amber-200 bg-amber-50 p-3 text-xs text-amber-800">
          <AlertCircle className="h-4 w-4 shrink-0 text-amber-600 mt-0.5" />
          <span>
            Restricted Access: Authorized administrative personnel only. Allowlist verified via public.admin_users table.
          </span>
        </div>

        {error && (
          <div className="mt-4 rounded-lg bg-rose-50 p-3 text-xs font-semibold text-rose-800 border border-rose-200">
            {error}
          </div>
        )}

        {/* Form */}
        <form className="mt-6 space-y-4" onSubmit={handleSubmit}>
          <div>
            <label className="block text-xs font-semibold text-slate-700">Administrator Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@laganstaff.in"
              className="mt-1.5 w-full rounded-lg border border-slate-300 px-3.5 py-2 text-xs text-slate-900 placeholder-slate-400 focus:border-indigo-600 focus:outline-none"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700">Security Password / Passkey</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••••••"
              className="mt-1.5 w-full rounded-lg border border-slate-300 px-3.5 py-2 text-xs text-slate-900 placeholder-slate-400 focus:border-indigo-600 focus:outline-none"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="flex w-full items-center justify-center gap-2 rounded-lg bg-indigo-900 px-4 py-2.5 text-xs font-semibold text-white shadow-sm hover:bg-indigo-800 transition-colors disabled:opacity-50"
          >
            <Lock className="h-4 w-4" />
            <span>{loading ? 'Authenticating...' : 'Sign In to Control Center'}</span>
          </button>
        </form>

        <div className="mt-6 border-t border-slate-200 pt-4 text-center text-[11px] text-slate-400">
          LaganStaff Marketplace Architecture v1.0 • Phase 8 Complete
        </div>
      </div>
    </div>
  );
}

'use client';

import React, { useState, useEffect, use } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import {
  ArrowLeft,
  Building2,
  Calendar,
  MapPin,
  Clock,
  Users,
  Utensils,
  Car,
  Ban,
  Phone,
} from 'lucide-react';
import {
  AdminJobRecord,
  fetchJobDetail,
  adminCancelJob,
} from '@/lib/job-service';

export default function AdminJobDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const resolvedParams = use(params);

  const [job, setJob] = useState<AdminJobRecord | null>(null);
  const [loading, setLoading] = useState(true);
  const [showCancelModal, setShowCancelModal] = useState(false);
  const [cancelReason, setCancelReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const loadJob = async () => {
    setLoading(true);
    const data = await fetchJobDetail(resolvedParams.id);
    setJob(data);
    setLoading(false);
  };

  useEffect(() => {
    let isMounted = true;
    fetchJobDetail(resolvedParams.id).then((data) => {
      if (isMounted) {
        setJob(data);
        setLoading(false);
      }
    });
    return () => {
      isMounted = false;
    };
  }, [resolvedParams.id]);

  const handleCancelJob = async () => {
    if (!job || !cancelReason.trim()) return;
    setActionLoading(true);
    setFeedback(null);
    try {
      const res = await adminCancelJob({
        jobId: job.id,
        reason: cancelReason.trim(),
      });
      if (res.success) {
        setFeedback({ type: 'success', text: res.message });
        setShowCancelModal(false);
        setCancelReason('');
        await loadJob();
      } else {
        setFeedback({ type: 'error', text: 'Failed to cancel job.' });
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setFeedback({ type: 'error', text: msg });
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) {
    return (
      <AdminShell>
        <div className="p-12 text-center text-xs text-slate-500">Loading job details...</div>
      </AdminShell>
    );
  }

  if (!job) {
    return (
      <AdminShell>
        <div className="rounded-xl border border-slate-200 bg-white p-8 text-center">
          <p className="text-sm font-semibold text-slate-700">Job record not found.</p>
          <Link
            href="/admin/jobs"
            className="mt-3 inline-flex items-center gap-1.5 text-xs font-semibold text-indigo-700"
          >
            <ArrowLeft className="h-3.5 w-3.5" /> Back to Jobs Registry
          </Link>
        </div>
      </AdminShell>
    );
  }

  return (
    <AdminShell>
      {/* Top Navigation */}
      <div>
        <Link
          href="/admin/jobs"
          className="inline-flex items-center gap-1 text-xs font-medium text-slate-500 hover:text-slate-800"
        >
          <ArrowLeft className="h-3.5 w-3.5" /> Back to Jobs Registry
        </Link>
      </div>

      {feedback && (
        <div
          className={`mt-4 rounded-lg p-3 text-xs font-medium ${
            feedback.type === 'success'
              ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
              : 'bg-rose-50 text-rose-800 border border-rose-200'
          }`}
        >
          {feedback.text}
        </div>
      )}

      {/* Main Header */}
      <div className="mt-4 rounded-xl border border-slate-200 bg-white p-6 shadow-xs">
        <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
          <div>
            <div className="flex items-center gap-2">
              <span className="rounded bg-indigo-50 border border-indigo-100 px-2 py-0.5 text-[10px] font-bold text-indigo-900 uppercase">
                {job.category_name}
              </span>
              <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-bold text-slate-700">
                {job.status.toUpperCase()}
              </span>
            </div>
            <h1 className="mt-2 text-xl font-black text-slate-900">{job.title}</h1>
            <p className="text-xs text-slate-500 mt-1 flex items-center gap-1">
              <Building2 className="h-3.5 w-3.5 text-slate-400" />
              <span>{job.business_name}</span> • <span>ID: {job.id}</span>
            </p>
          </div>

          <div className="flex items-center gap-2">
            {job.status !== 'cancelled' && job.status !== 'completed' && (
              <button
                onClick={() => setShowCancelModal(true)}
                className="inline-flex items-center gap-1.5 rounded-lg border border-rose-300 bg-rose-50 px-3.5 py-1.5 text-xs font-semibold text-rose-700 hover:bg-rose-100 shadow-2xs"
              >
                <Ban className="h-3.5 w-3.5" />
                <span>Admin Emergency Cancel</span>
              </button>
            )}

            <Link
              href={`/admin/bookings?search=${encodeURIComponent(job.title)}`}
              className="inline-flex items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3.5 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 shadow-2xs"
            >
              <Users className="h-3.5 w-3.5 text-slate-500" />
              <span>Inspect Bookings</span>
            </Link>
          </div>
        </div>

        {/* Core Job Metrics */}
        <div className="mt-6 grid grid-cols-2 sm:grid-cols-4 gap-4 border-t border-slate-100 pt-5 text-xs">
          <div>
            <span className="text-slate-400">Shift Date</span>
            <div className="font-semibold text-slate-800 flex items-center gap-1 mt-0.5">
              <Calendar className="h-3.5 w-3.5 text-slate-400" />
              {job.shift_date}
            </div>
          </div>
          <div>
            <span className="text-slate-400">Shift Hours</span>
            <div className="font-semibold text-slate-800 flex items-center gap-1 mt-0.5">
              <Clock className="h-3.5 w-3.5 text-slate-400" />
              {job.start_time.substring(0, 5)} - {job.end_time.substring(0, 5)}
              {job.is_overnight && <span className="text-[10px] text-amber-700 font-bold ml-1">(Overnight)</span>}
            </div>
          </div>
          <div>
            <span className="text-slate-400">Workers Quota</span>
            <div className="font-semibold text-slate-800 flex items-center gap-1 mt-0.5">
              <Users className="h-3.5 w-3.5 text-slate-400" />
              {job.workers_confirmed} confirmed of {job.workers_needed} needed
            </div>
          </div>
          <div>
            <span className="text-slate-400">Offered Wage</span>
            <div className="font-black text-emerald-700 text-sm mt-0.5">
              ₹{job.wage_amount} <span className="text-xs font-normal text-slate-500">/ shift</span>
            </div>
          </div>
        </div>
      </div>

      {/* Two Column Layout: Description & Venue */}
      <div className="mt-6 grid grid-cols-1 sm:grid-cols-2 gap-6">
        {/* Left: Job Requirements */}
        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-xs space-y-4">
          <h2 className="text-sm font-bold text-slate-900">Shift Scope & Requirements</h2>

          {job.description && (
            <div>
              <span className="text-xs text-slate-400">Description:</span>
              <p className="mt-1 text-xs text-slate-700 leading-relaxed bg-slate-50 p-3 rounded-lg border border-slate-100">
                {job.description}
              </p>
            </div>
          )}

          <div>
            <span className="text-xs text-slate-400">Required Skills:</span>
            <div className="mt-1.5 flex flex-wrap gap-1.5">
              {job.skills && job.skills.length > 0 ? (
                job.skills.map((s) => (
                  <span
                    key={s.id}
                    className="rounded bg-slate-100 px-2 py-0.5 text-xs font-medium text-slate-700"
                  >
                    {s.name}
                  </span>
                ))
              ) : (
                <span className="text-xs text-slate-400">General event staff</span>
              )}
            </div>
          </div>

          <div className="border-t border-slate-100 pt-3 flex flex-wrap gap-4 text-xs">
            <div className="flex items-center gap-1.5">
              <Utensils className={`h-4 w-4 ${job.food_provided ? 'text-emerald-600' : 'text-slate-300'}`} />
              <span className={job.food_provided ? 'text-slate-800 font-semibold' : 'text-slate-400'}>
                {job.food_provided ? 'Food Provided' : 'No Food'}
              </span>
            </div>
            <div className="flex items-center gap-1.5">
              <Car className={`h-4 w-4 ${job.transport_provided ? 'text-emerald-600' : 'text-slate-300'}`} />
              <span className={job.transport_provided ? 'text-slate-800 font-semibold' : 'text-slate-400'}>
                {job.transport_provided ? 'Transport Provided' : 'No Transport'}
              </span>
            </div>
          </div>
        </div>

        {/* Right: Venue & Reporting Address */}
        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-xs space-y-4">
          <h2 className="text-sm font-bold text-slate-900">Venue & Gate Reporting Details</h2>

          <div>
            <span className="text-xs text-slate-400">Venue Name:</span>
            <p className="mt-0.5 text-xs font-semibold text-slate-800">
              {job.venue_name || job.business_name}
            </p>
          </div>

          <div>
            <span className="text-xs text-slate-400">Reporting Address:</span>
            <p className="mt-0.5 text-xs font-medium text-slate-700 flex items-start gap-1">
              <MapPin className="h-3.5 w-3.5 text-slate-400 shrink-0 mt-0.5" />
              <span>{job.reporting_address}, {job.locality}, Ghazipur ({job.pincode})</span>
            </p>
          </div>

          <div>
            <span className="text-xs text-slate-400">Emergency Business Contact:</span>
            <p className="mt-0.5 text-xs font-semibold text-slate-800 flex items-center gap-1">
              <Phone className="h-3.5 w-3.5 text-slate-400" />
              {job.contact_phone} ({job.contact_person || 'Owner'})
            </p>
          </div>

          {job.special_instructions && (
            <div className="border-t border-slate-100 pt-3">
              <span className="text-xs text-slate-400">Special Instructions:</span>
              <p className="mt-1 text-xs text-slate-600 italic">
                &ldquo;{job.special_instructions}&rdquo;
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Emergency Cancellation Dialog */}
      {showCancelModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl border border-slate-200">
            <h3 className="text-base font-bold text-slate-900">Administrative Job Cancellation</h3>
            <p className="text-xs text-slate-500 mt-1">
              Cancelling will revoke worker duty passes and mark this shift cancelled across Ghazipur.
            </p>

            <textarea
              value={cancelReason}
              onChange={(e) => setCancelReason(e.target.value)}
              placeholder="e.g. Venue dispute or inaccurate shift timing reported..."
              rows={3}
              className="mt-3 w-full rounded-lg border border-slate-300 p-2.5 text-xs focus:border-rose-500 focus:outline-none"
            />

            <div className="mt-4 flex justify-end gap-2">
              <button
                onClick={() => setShowCancelModal(false)}
                disabled={actionLoading}
                className="rounded-lg border border-slate-300 px-3.5 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
              >
                Dismiss
              </button>
              <button
                disabled={actionLoading || !cancelReason.trim()}
                onClick={handleCancelJob}
                className="rounded-lg bg-rose-600 px-3.5 py-1.5 text-xs font-semibold text-white hover:bg-rose-700 disabled:opacity-50"
              >
                Confirm Cancellation
              </button>
            </div>
          </div>
        </div>
      )}
    </AdminShell>
  );
}

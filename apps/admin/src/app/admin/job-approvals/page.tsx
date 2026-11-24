'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import {
  Building2,
  Calendar,
  Clock,
  IndianRupee,
  MapPin,
  Users,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  RefreshCw,
  Eye,
  Utensils,
  Car,
} from 'lucide-react';
import {
  AdminJobRecord,
  fetchJobApprovalsQueue,
  adminReviewFirstJob,
} from '@/lib/job-service';

export default function AdminJobApprovalsPage() {
  const [queue, setQueue] = useState<AdminJobRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Reject Modal State
  const [rejectingJob, setRejectingJob] = useState<AdminJobRecord | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');

  const loadData = () => {
    fetchJobApprovalsQueue()
      .then((data) => {
        setQueue(data);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message || 'Error loading job approvals queue');
        setLoading(false);
      });
  };

  useEffect(() => {
    let isMounted = true;
    fetchJobApprovalsQueue().then((data) => {
      if (isMounted) {
        setQueue(data);
        setLoading(false);
      }
    });
    return () => {
      isMounted = false;
    };
  }, []);

  const handleApprove = async (job: AdminJobRecord) => {
    if (job.business_verification_status !== 'verified') {
      setError(
        `Business "${job.business_name}" is not verified yet. Please verify business first.`
      );
      return;
    }

    setActionLoading(job.id);
    setError(null);
    setSuccess(null);

    try {
      const res = await adminReviewFirstJob({
        jobId: job.id,
        action: 'approve',
      });
      setSuccess(res.message);
      loadData();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setError(msg);
    } finally {
      setActionLoading(null);
    }
  };

  const handleRejectSubmit = async () => {
    if (!rejectingJob || !rejectionReason.trim()) return;

    setActionLoading(rejectingJob.id);
    setError(null);
    setSuccess(null);

    try {
      const res = await adminReviewFirstJob({
        jobId: rejectingJob.id,
        action: 'reject',
        rejectionReason: rejectionReason.trim(),
      });
      setSuccess(res.message);
      setRejectingJob(null);
      setRejectionReason('');
      loadData();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setError(msg);
    } finally {
      setActionLoading(null);
    }
  };

  return (
    <AdminShell>
      {/* Top Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              First-Job Approval Queue
            </h1>
            <span className="rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-bold text-amber-900">
              {queue.length} Pending
            </span>
          </div>
          <p className="text-xs text-slate-500 font-medium">
            Review first job posts from newly verified businesses before enabling auto-publishing.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => {
              setLoading(true);
              loadData();
            }}
            className="inline-flex items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 shadow-xs"
          >
            <RefreshCw className={`h-3.5 w-3.5 ${loading ? 'animate-spin' : ''}`} />
            <span>Refresh</span>
          </button>
          <Link
            href="/admin/jobs"
            className="inline-flex items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 shadow-xs"
          >
            <span>All Jobs</span>
          </Link>
        </div>
      </div>

      {/* Alert Notices */}
      {error && (
        <div className="mt-4 flex items-center gap-2 rounded-xl border border-rose-200 bg-rose-50 p-4 text-xs font-semibold text-rose-800">
          <AlertTriangle className="h-4 w-4 shrink-0 text-rose-600" />
          <span>{error}</span>
        </div>
      )}

      {success && (
        <div className="mt-4 flex items-center gap-2 rounded-xl border border-emerald-200 bg-emerald-50 p-4 text-xs font-semibold text-emerald-800">
          <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-600" />
          <span>{success}</span>
        </div>
      )}

      {/* Queue Cards */}
      <div className="mt-6 space-y-4">
        {loading ? (
          <div className="rounded-xl border border-slate-200 bg-white p-12 text-center text-xs text-slate-400 shadow-xs">
            Loading approval queue...
          </div>
        ) : queue.length === 0 ? (
          <div className="rounded-xl border border-slate-200 bg-white p-12 text-center shadow-xs">
            <CheckCircle2 className="mx-auto h-10 w-10 text-emerald-500 mb-2" />
            <h3 className="text-sm font-bold text-slate-900">Queue is Clear!</h3>
            <p className="mt-1 text-xs text-slate-500">
              No pending first-job submissions requiring admin inspection in Ghazipur.
            </p>
          </div>
        ) : (
          queue.map((job) => (
            <div
              key={job.id}
              className="rounded-xl border border-slate-200 bg-white p-5 shadow-xs transition hover:border-slate-300"
            >
              <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                <div className="space-y-1.5 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="rounded bg-indigo-50 border border-indigo-100 px-2 py-0.5 text-[10px] font-bold text-indigo-900 uppercase">
                      {job.category_name}
                    </span>
                    {job.is_first_job && (
                      <span className="rounded-full bg-amber-50 border border-amber-200 px-2 py-0.5 text-[10px] font-bold text-amber-800">
                        First Job Submission
                      </span>
                    )}
                    <span
                      className={`rounded-full px-2 py-0.5 text-[10px] font-semibold ${
                        job.business_verification_status === 'verified'
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : 'bg-rose-50 text-rose-700 border border-rose-200'
                      }`}
                    >
                      Business: {job.business_verification_status}
                    </span>
                  </div>

                  <h3 className="text-base font-bold text-slate-900">{job.title}</h3>

                  <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-slate-600">
                    <span className="flex items-center gap-1 font-semibold text-slate-800">
                      <Building2 className="h-3.5 w-3.5 text-slate-400" />
                      {job.business_name}
                    </span>
                    <span className="flex items-center gap-1">
                      <MapPin className="h-3.5 w-3.5 text-slate-400" />
                      {job.venue_name || job.locality}, Ghazipur
                    </span>
                    <span className="flex items-center gap-1">
                      <Calendar className="h-3.5 w-3.5 text-slate-400" />
                      {job.shift_date} ({job.start_time.substring(0, 5)} - {job.end_time.substring(0, 5)})
                    </span>
                  </div>

                  {job.description && (
                    <p className="mt-2 text-xs text-slate-600 bg-slate-50 p-2.5 rounded-lg border border-slate-100">
                      {job.description}
                    </p>
                  )}

                  <div className="flex flex-wrap items-center gap-4 text-xs font-medium text-slate-700 pt-1">
                    <span className="flex items-center gap-1">
                      <Users className="h-3.5 w-3.5 text-slate-400" />
                      Workers Needed: <strong>{job.workers_needed}</strong>
                    </span>
                    <span className="flex items-center gap-1 font-black text-emerald-700">
                      Wage: ₹{job.wage_amount} / shift
                    </span>
                    {job.food_provided && (
                      <span className="flex items-center gap-1 text-emerald-700">
                        <Utensils className="h-3.5 w-3.5" /> Food
                      </span>
                    )}
                    {job.transport_provided && (
                      <span className="flex items-center gap-1 text-emerald-700">
                        <Car className="h-3.5 w-3.5" /> Transport
                      </span>
                    )}
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="flex flex-row sm:flex-col items-end gap-2 shrink-0">
                  <div className="flex items-center gap-2">
                    <button
                      disabled={actionLoading === job.id}
                      onClick={() => handleApprove(job)}
                      className="inline-flex items-center gap-1.5 rounded-lg bg-emerald-600 px-3.5 py-1.5 text-xs font-semibold text-white shadow-xs hover:bg-emerald-700 disabled:opacity-50"
                    >
                      <CheckCircle2 className="h-3.5 w-3.5" />
                      <span>Approve Job</span>
                    </button>

                    <button
                      disabled={actionLoading === job.id}
                      onClick={() => {
                        setRejectingJob(job);
                        setRejectionReason('');
                      }}
                      className="inline-flex items-center gap-1.5 rounded-lg border border-rose-300 bg-rose-50 px-3 py-1.5 text-xs font-semibold text-rose-700 hover:bg-rose-100 disabled:opacity-50"
                    >
                      <XCircle className="h-3.5 w-3.5" />
                      <span>Reject</span>
                    </button>
                  </div>

                  <Link
                    href={`/admin/job-approvals/${job.id}`}
                    className="inline-flex items-center gap-1 text-xs font-semibold text-indigo-900 hover:underline pt-1"
                  >
                    <Eye className="h-3 w-3" />
                    <span>Deep Inspection</span>
                  </Link>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Reject Reason Modal */}
      {rejectingJob && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl border border-slate-200">
            <h3 className="text-base font-bold text-slate-900">Reject First-Job Submission</h3>
            <p className="text-xs text-slate-500 mt-1">
              Provide actionable guidance for <strong>{rejectingJob.business_name}</strong> to revise their job post.
            </p>

            <textarea
              rows={3}
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              placeholder="e.g. Unrealistic reporting hours or wage below Ghazipur baseline..."
              className="mt-3 w-full rounded-lg border border-slate-300 p-2.5 text-xs focus:border-rose-500 focus:outline-none"
            />

            <div className="mt-4 flex justify-end gap-2">
              <button
                onClick={() => {
                  setRejectingJob(null);
                  setRejectionReason('');
                }}
                className="rounded-lg border border-slate-300 px-3.5 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
              >
                Cancel
              </button>
              <button
                disabled={actionLoading === rejectingJob.id || !rejectionReason.trim()}
                onClick={handleRejectSubmit}
                className="rounded-lg bg-rose-600 px-3.5 py-1.5 text-xs font-semibold text-white hover:bg-rose-700 disabled:opacity-50"
              >
                Confirm Rejection
              </button>
            </div>
          </div>
        </div>
      )}
    </AdminShell>
  );
}

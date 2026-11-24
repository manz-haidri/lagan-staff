'use client';

import React, { useState, useEffect, use } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/layout/AdminShell';
import {
  ArrowLeft,
  Building2,
  Calendar,
  MapPin,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  Utensils,
  Car,
  ShieldCheck,
  FileText,
} from 'lucide-react';
import {
  AdminJobRecord,
  fetchJobDetail,
  adminReviewFirstJob,
} from '@/lib/job-service';

export default function AdminJobApprovalDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const resolvedParams = use(params);
  const router = useRouter();

  const [job, setJob] = useState<AdminJobRecord | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Reject Modal
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [rejectionReason, setRejectionReason] = useState('');
  const [internalNotes, setInternalNotes] = useState('');

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

  const handleApprove = async () => {
    if (!job) return;
    if (job.business_verification_status !== 'verified') {
      setError(
        `Business "${job.business_name}" is not verified yet. Please verify business first.`
      );
      return;
    }

    setActionLoading(true);
    setError(null);
    setSuccess(null);

    try {
      const res = await adminReviewFirstJob({
        jobId: job.id,
        action: 'approve',
      });
      setSuccess(res.message);
      setJob((prev) => (prev ? { ...prev, status: 'published' } : null));
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setError(msg);
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = async () => {
    if (!job || !rejectionReason.trim()) return;

    setActionLoading(true);
    setError(null);
    setSuccess(null);

    try {
      const res = await adminReviewFirstJob({
        jobId: job.id,
        action: 'reject',
        rejectionReason: rejectionReason.trim(),
        internalNotes: internalNotes.trim() || undefined,
      });
      setSuccess(res.message);
      setShowRejectModal(false);
      setJob((prev) => (prev ? { ...prev, status: 'rejected' } : null));
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setError(msg);
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
          <p className="text-sm font-semibold text-slate-700">Job submission not found.</p>
          <Link
            href="/admin/job-approvals"
            className="mt-3 inline-flex items-center gap-1.5 text-xs font-semibold text-indigo-700"
          >
            <ArrowLeft className="h-3.5 w-3.5" /> Back to Approvals Queue
          </Link>
        </div>
      </AdminShell>
    );
  }

  return (
    <AdminShell>
      <div>
        <Link
          href="/admin/job-approvals"
          className="inline-flex items-center gap-1 text-xs font-medium text-slate-500 hover:text-slate-800"
        >
          <ArrowLeft className="h-3.5 w-3.5" /> Back to Approvals Queue
        </Link>
      </div>

      {/* Header Bar */}
      <div className="mt-4 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between rounded-xl border border-slate-200 bg-white p-6 shadow-xs">
        <div>
          <div className="flex items-center gap-2">
            <span className="rounded bg-indigo-50 border border-indigo-100 px-2 py-0.5 text-[10px] font-bold text-indigo-900 uppercase">
              {job.category_name}
            </span>
            <span className="rounded-full bg-amber-50 border border-amber-200 px-2 py-0.5 text-[10px] font-bold text-amber-800">
              First Job Approval Review
            </span>
          </div>
          <h1 className="mt-2 text-xl font-black text-slate-900">{job.title}</h1>
          <p className="text-xs text-slate-500 mt-0.5">
            {job.business_name} • Submitted for review
          </p>
        </div>

        {/* Action Controls */}
        <div className="flex items-center gap-2">
          {job.status === 'pending_admin_approval' && (
            <>
              <button
                disabled={actionLoading}
                onClick={handleApprove}
                className="inline-flex items-center gap-1.5 rounded-lg bg-emerald-600 px-4 py-2 text-xs font-semibold text-white shadow-xs hover:bg-emerald-700 disabled:opacity-50"
              >
                <CheckCircle2 className="h-4 w-4" />
                <span>Approve & Publish</span>
              </button>
              <button
                disabled={actionLoading}
                onClick={() => setShowRejectModal(true)}
                className="inline-flex items-center gap-1.5 rounded-lg border border-rose-300 bg-rose-50 px-4 py-2 text-xs font-semibold text-rose-700 hover:bg-rose-100 disabled:opacity-50"
              >
                <XCircle className="h-4 w-4" />
                <span>Reject</span>
              </button>
            </>
          )}

          {job.status === 'published' && (
            <span className="inline-flex items-center gap-1.5 rounded-lg bg-emerald-50 border border-emerald-200 px-3.5 py-1.5 text-xs font-bold text-emerald-800">
              <CheckCircle2 className="h-4 w-4" /> Approved & Live in App
            </span>
          )}

          {job.status === 'rejected' && (
            <span className="inline-flex items-center gap-1.5 rounded-lg bg-rose-50 border border-rose-200 px-3.5 py-1.5 text-xs font-bold text-rose-800">
              <XCircle className="h-4 w-4" /> Rejected
            </span>
          )}
        </div>
      </div>

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

      {/* Grid Content */}
      <div className="mt-6 grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left 2 Cols: Job Details */}
        <div className="lg:col-span-2 space-y-6">
          {/* Shift & Quota Card */}
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-xs">
            <h3 className="text-sm font-bold text-slate-900 border-b pb-3 border-slate-100 flex items-center gap-2">
              <Calendar className="h-4 w-4 text-indigo-700" />
              <span>Shift Details & Wage</span>
            </h3>

            <div className="mt-4 grid grid-cols-2 sm:grid-cols-4 gap-4 text-xs">
              <div className="rounded-lg bg-slate-50 p-3">
                <div className="text-slate-400 font-medium">Shift Date</div>
                <div className="mt-1 font-bold text-slate-800 text-sm">{job.shift_date}</div>
              </div>
              <div className="rounded-lg bg-slate-50 p-3">
                <div className="text-slate-400 font-medium">Hours</div>
                <div className="mt-1 font-bold text-slate-800 text-sm">
                  {job.start_time.substring(0, 5)} - {job.end_time.substring(0, 5)}
                </div>
              </div>
              <div className="rounded-lg bg-slate-50 p-3">
                <div className="text-slate-400 font-medium">Workers Needed</div>
                <div className="mt-1 font-bold text-slate-800 text-sm">{job.workers_needed} staff</div>
              </div>
              <div className="rounded-lg bg-emerald-50 p-3">
                <div className="text-emerald-700 font-medium">Offered Wage</div>
                <div className="mt-1 font-black text-emerald-800 text-sm">₹{job.wage_amount} / shift</div>
              </div>
            </div>
          </div>

          {/* Description & Scope */}
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-xs space-y-4">
            <h3 className="text-sm font-bold text-slate-900 border-b pb-3 border-slate-100 flex items-center gap-2">
              <FileText className="h-4 w-4 text-indigo-700" />
              <span>Job Narrative & Instructions</span>
            </h3>

            <div className="text-xs text-slate-700 leading-relaxed whitespace-pre-wrap">
              {job.description || 'No detailed description specified.'}
            </div>

            {/* Special Instructions */}
            {job.special_instructions && (
              <div className="rounded-lg bg-amber-50 border border-amber-200 p-3 text-xs text-amber-900">
                <span className="font-bold">Special Notes: </span> {job.special_instructions}
              </div>
            )}
          </div>

          {/* Venue and Amenities */}
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-xs space-y-4">
            <h3 className="text-sm font-bold text-slate-900 border-b pb-3 border-slate-100 flex items-center gap-2">
              <MapPin className="h-4 w-4 text-indigo-700" />
              <span>Venue & Facilitation</span>
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
              <div className="space-y-1">
                <span className="text-slate-400 font-medium">Venue:</span>
                <p className="font-bold text-slate-800">{job.venue_name || job.business_name}</p>
                <p className="text-slate-600">{job.reporting_address}</p>
                <p className="text-slate-500">{job.locality}, {job.city} ({job.pincode})</p>
              </div>

              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <Utensils className="h-4 w-4 text-indigo-700" />
                  <span className="font-bold text-slate-800">
                    Food: {job.food_provided ? 'Provided' : 'Not Provided'}
                  </span>
                </div>
                <div className="flex items-center gap-2 pt-2">
                  <Car className="h-4 w-4 text-blue-600" />
                  <span className="font-bold text-slate-800">
                    Transport: {job.transport_provided ? 'Provided' : 'Not Provided'}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Right Col: Business Status */}
        <div className="space-y-6">
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-xs space-y-4">
            <h3 className="text-sm font-bold text-slate-900 border-b pb-3 border-slate-100 flex items-center gap-2">
              <Building2 className="h-4 w-4 text-indigo-700" />
              <span>Business Context</span>
            </h3>

            <div className="space-y-2 text-xs">
              <div>
                <span className="text-slate-400 font-medium">Business Name:</span>
                <p className="font-bold text-slate-900 text-sm mt-0.5">{job.business_name}</p>
              </div>
              <div>
                <span className="text-slate-400 font-medium">Category:</span>
                <p className="font-semibold text-slate-700 capitalize">{job.business_category.replace('_', ' ')}</p>
              </div>
              <div>
                <span className="text-slate-400 font-medium">Verification Status:</span>
                <div className="mt-1 flex items-center gap-1.5 font-bold text-emerald-700">
                  <ShieldCheck className="h-4 w-4 text-emerald-600" />
                  <span>{job.business_verification_status.toUpperCase()}</span>
                </div>
              </div>
              <div className="pt-2 border-t border-slate-100">
                <span className="text-slate-400 font-medium">Contact Person:</span>
                <p className="font-semibold text-slate-800">{job.contact_person || 'Owner'}</p>
                <p className="text-slate-600 font-mono">{job.contact_phone}</p>
              </div>
            </div>

            <Link
              href={`/admin/businesses/${job.business_id}`}
              className="mt-4 block w-full rounded-lg border border-slate-200 bg-slate-50 py-2 text-center text-xs font-semibold text-indigo-900 hover:bg-slate-100 transition-colors"
            >
              Inspect Business Dossier →
            </Link>
          </div>
        </div>
      </div>

      {/* Reject Modal */}
      {showRejectModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl border border-slate-200">
            <h3 className="text-base font-bold text-slate-900">Reject First-Job Submission</h3>
            <p className="text-xs text-slate-500 mt-1">
              Provide actionable guidance for the employer to revise their shift posting.
            </p>

            <textarea
              rows={3}
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              placeholder="e.g. Wage amount is below local standard or shift hours are unsafe..."
              className="mt-3 w-full rounded-lg border border-slate-300 p-2.5 text-xs focus:border-rose-500 focus:outline-none"
            />

            <div className="mt-4 flex justify-end gap-2">
              <button
                onClick={() => setShowRejectModal(false)}
                className="rounded-lg border border-slate-300 px-3.5 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
              >
                Cancel
              </button>
              <button
                disabled={actionLoading || !rejectionReason.trim()}
                onClick={handleReject}
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

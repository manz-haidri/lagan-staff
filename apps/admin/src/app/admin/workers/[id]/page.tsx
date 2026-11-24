'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { AdminShell } from '@/components/layout/AdminShell';
import {
  fetchAdminWorkerDetail,
  reviewWorker,
  suspendWorker,
  reactivateWorker,
  getWorkerSelfieSignedUrl,
  AdminWorkerRecord,
} from '@/lib/worker-service';
import {
  ArrowLeft,
  User,
  MapPin,
  Calendar,
  CheckCircle2,
  ShieldAlert,
  Briefcase,
  Camera,
} from 'lucide-react';

export default function AdminWorkerDetailPage() {
  const params = useParams();
  const workerId = params.id as string;

  const [worker, setWorker] = useState<AdminWorkerRecord | null>(null);
  const [loading, setLoading] = useState(true);
  const [signedSelfieUrl, setSignedSelfieUrl] = useState<string | null>(null);

  // Action dialog states
  const [showSuspendModal, setShowSuspendModal] = useState(false);
  const [suspendReason, setSuspendReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  useEffect(() => {
    async function load() {
      setLoading(true);
      const data = await fetchAdminWorkerDetail(workerId);
      setWorker(data);
      if (data?.selfie_url) {
        const url = await getWorkerSelfieSignedUrl(data.selfie_url);
        setSignedSelfieUrl(url);
      }
      setLoading(false);
    }
    load();
  }, [workerId]);

  const handleReview = async (newStatus: 'reviewed' | 'needs_attention') => {
    if (!worker) return;
    setActionLoading(true);
    setFeedback(null);
    const res = await reviewWorker(worker.id, newStatus, 'Reviewed by administrator');
    if (res.success) {
      setWorker({ ...worker, review_status: newStatus });
      setFeedback({ type: 'success', text: `Review status updated to "${newStatus}".` });
    } else {
      setFeedback({ type: 'error', text: res.error || 'Failed to update review status.' });
    }
    setActionLoading(false);
  };

  const handleSuspend = async () => {
    if (!worker || !suspendReason.trim()) return;
    setActionLoading(true);
    setFeedback(null);
    const res = await suspendWorker(worker.id, suspendReason.trim());
    if (res.success) {
      setWorker({ ...worker, account_status: 'suspended', review_notes: suspendReason.trim() });
      setShowSuspendModal(false);
      setSuspendReason('');
      setFeedback({ type: 'success', text: 'Worker account suspended successfully.' });
    } else {
      setFeedback({ type: 'error', text: res.error || 'Failed to suspend worker.' });
    }
    setActionLoading(false);
  };

  const handleReactivate = async () => {
    if (!worker) return;
    setActionLoading(true);
    setFeedback(null);
    const res = await reactivateWorker(worker.id);
    if (res.success) {
      setWorker({ ...worker, account_status: 'active' });
      setFeedback({ type: 'success', text: 'Worker account reactivated successfully.' });
    } else {
      setFeedback({ type: 'error', text: res.error || 'Failed to reactivate worker.' });
    }
    setActionLoading(false);
  };

  if (loading) {
    return (
      <AdminShell>
        <div className="p-12 text-center text-xs text-slate-500">Loading worker profile...</div>
      </AdminShell>
    );
  }

  if (!worker) {
    return (
      <AdminShell>
        <div className="rounded-xl border border-slate-200 bg-white p-8 text-center">
          <p className="text-sm font-semibold text-slate-700">Worker record not found.</p>
          <Link
            href="/admin/workers"
            className="mt-3 inline-flex items-center gap-1.5 text-xs font-semibold text-indigo-700"
          >
            <ArrowLeft className="h-3.5 w-3.5" /> Back to Workers Directory
          </Link>
        </div>
      </AdminShell>
    );
  }

  return (
    <AdminShell>
      {/* Back button */}
      <div>
        <Link
          href="/admin/workers"
          className="inline-flex items-center gap-1 text-xs font-medium text-slate-500 hover:text-slate-800"
        >
          <ArrowLeft className="h-3.5 w-3.5" /> Back to Workers Directory
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

      {/* Main Profile Header */}
      <div className="mt-4 rounded-xl border border-slate-200 bg-white p-6 shadow-xs">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            {signedSelfieUrl ? (
              <img
                src={signedSelfieUrl}
                alt={worker.full_name}
                className="h-16 w-16 rounded-full object-cover border-2 border-slate-200"
              />
            ) : (
              <div className="flex h-16 w-16 items-center justify-center rounded-full bg-slate-100 text-slate-500 border border-slate-200">
                <User className="h-8 w-8" />
              </div>
            )}
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-black text-slate-900">{worker.full_name}</h1>
                {worker.account_status === 'active' ? (
                  <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-semibold text-emerald-700 border border-emerald-200">
                    <CheckCircle2 className="h-3 w-3" /> Active
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1 rounded-full bg-rose-50 px-2 py-0.5 text-[11px] font-semibold text-rose-700 border border-rose-200">
                    <ShieldAlert className="h-3 w-3" /> Suspended
                  </span>
                )}
              </div>
              <p className="text-xs text-slate-500 font-mono mt-0.5">{worker.mobile_number}</p>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex flex-wrap items-center gap-2">
            {worker.account_status === 'active' ? (
              <button
                onClick={() => setShowSuspendModal(true)}
                disabled={actionLoading}
                className="rounded-lg border border-rose-300 bg-rose-50 px-3 py-1.5 text-xs font-semibold text-rose-700 hover:bg-rose-100"
              >
                Suspend Account
              </button>
            ) : (
              <button
                onClick={handleReactivate}
                disabled={actionLoading}
                className="rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-emerald-700 shadow-xs"
              >
                Reactivate Account
              </button>
            )}

            <button
              onClick={() => handleReview('reviewed')}
              disabled={actionLoading || worker.review_status === 'reviewed'}
              className="rounded-lg bg-indigo-900 px-3 py-1.5 text-xs font-semibold text-white hover:bg-indigo-800 disabled:opacity-50 shadow-xs"
            >
              Mark Reviewed
            </button>
            <button
              onClick={() => handleReview('needs_attention')}
              disabled={actionLoading || worker.review_status === 'needs_attention'}
              className="rounded-lg border border-amber-300 bg-amber-50 px-3 py-1.5 text-xs font-semibold text-amber-800 hover:bg-amber-100 disabled:opacity-50"
            >
              Flag Attention
            </button>
          </div>
        </div>

        {/* Details Grid */}
        <div className="mt-6 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4 border-t border-slate-100 pt-5 text-xs">
          <div>
            <span className="text-slate-400 font-medium">Locality / City:</span>
            <div className="font-semibold text-slate-800 flex items-center gap-1 mt-0.5">
              <MapPin className="h-3.5 w-3.5 text-slate-400" />
              {worker.locality}, {worker.city || 'Ghazipur'} {worker.pincode ? `(${worker.pincode})` : ''}
            </div>
          </div>
          <div>
            <span className="text-slate-400 font-medium">Post-Registration Review:</span>
            <div className="font-semibold text-slate-800 mt-0.5 capitalize">
              {worker.review_status.replace('_', ' ')}
            </div>
          </div>
          <div>
            <span className="text-slate-400 font-medium">Registered On:</span>
            <div className="font-semibold text-slate-800 flex items-center gap-1 mt-0.5">
              <Calendar className="h-3.5 w-3.5 text-slate-400" />
              {new Date(worker.created_at).toLocaleDateString('en-IN', { timeZone: 'Asia/Kolkata' })}
            </div>
          </div>
          <div>
            <span className="text-slate-400 font-medium">Shifts Completed:</span>
            <div className="font-semibold text-slate-800 flex items-center gap-1 mt-0.5">
              <Briefcase className="h-3.5 w-3.5 text-slate-400" />
              {worker.shifts_completed || 0} shifts
            </div>
          </div>
        </div>

        {worker.review_notes && (
          <div className="mt-4 rounded-lg bg-slate-50 p-3 text-xs text-slate-700 border border-slate-200">
            <span className="font-bold text-slate-800">Admin Notes: </span>
            {worker.review_notes}
          </div>
        )}
      </div>

      {/* Skills Section */}
      <div className="mt-6 rounded-xl border border-slate-200 bg-white p-6 shadow-xs">
        <h2 className="text-sm font-bold text-slate-900">Registered Skills & Categories</h2>
        <p className="text-xs text-slate-500 mt-0.5">
          Job opportunities matching these skills will be visible in the worker&apos;s mobile application.
        </p>

        <div className="mt-4 flex flex-wrap gap-2">
          {worker.skills && worker.skills.length > 0 ? (
            worker.skills.map((skill, idx) => (
              <span
                key={idx}
                className="rounded-lg bg-indigo-50 border border-indigo-100 px-3 py-1.5 text-xs font-medium text-indigo-900"
              >
                {skill}
              </span>
            ))
          ) : (
            <p className="text-xs text-slate-400">No skills specified yet.</p>
          )}
        </div>
      </div>

      {/* Verification Selfie Inspection */}
      <div className="mt-6 rounded-xl border border-slate-200 bg-white p-6 shadow-xs">
        <div className="flex items-center gap-2">
          <Camera className="h-4 w-4 text-slate-500" />
          <h2 className="text-sm font-bold text-slate-900">Onboarding Selfie (Identity Inspection)</h2>
        </div>
        <p className="text-xs text-slate-500 mt-0.5">
          Private capture uploaded during mobile registration. Accessible exclusively to administrators via temporary signed token.
        </p>

        <div className="mt-4">
          {signedSelfieUrl ? (
            <div className="inline-block rounded-xl border border-slate-200 p-2 bg-slate-50">
              <img
                src={signedSelfieUrl}
                alt="Worker Selfie"
                className="max-h-72 rounded-lg object-contain shadow-xs"
              />
            </div>
          ) : (
            <div className="rounded-lg border border-dashed border-slate-300 p-8 text-center text-xs text-slate-400 bg-slate-50">
              No private selfie uploaded for this worker record.
            </div>
          )}
        </div>
      </div>

      {/* Suspend Confirmation Modal */}
      {showSuspendModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl border border-slate-200">
            <h3 className="text-base font-bold text-slate-900">Suspend Worker Account</h3>
            <p className="text-xs text-slate-500 mt-1">
              Please enter an official reason. Suspended workers cannot discover jobs or accept duty passes.
            </p>

            <textarea
              value={suspendReason}
              onChange={(e) => setSuspendReason(e.target.value)}
              placeholder="e.g. Consecutive no-shows reported by Banquet owners..."
              rows={3}
              className="mt-3 w-full rounded-lg border border-slate-300 p-2.5 text-xs focus:border-indigo-600 focus:outline-none"
            />

            <div className="mt-4 flex justify-end gap-2">
              <button
                onClick={() => setShowSuspendModal(false)}
                disabled={actionLoading}
                className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
              >
                Cancel
              </button>
              <button
                onClick={handleSuspend}
                disabled={actionLoading || !suspendReason.trim()}
                className="rounded-lg bg-rose-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-rose-700 disabled:opacity-50"
              >
                Confirm Suspension
              </button>
            </div>
          </div>
        </div>
      )}
    </AdminShell>
  );
}

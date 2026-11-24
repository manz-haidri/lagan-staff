'use client';

import React, { useEffect, useState, use } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import {
  fetchAdminComplaintDetail,
  resolveComplaint,
  addComplaintNote,
  formatComplaintCategory,
  AdminComplaintRecord,
} from '@/lib/complaint-service';
import {
  ArrowLeft,
  Clock,
  CheckCircle2,
  XCircle,
  MessageSquare,
  User,
  Building2,
  Send,
  FileText,
} from 'lucide-react';

export default function AdminComplaintDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const resolvedParams = use(params);
  const complaintId = resolvedParams.id;

  const [complaint, setComplaint] = useState<AdminComplaintRecord | null>(null);
  const [loading, setLoading] = useState(true);
  const [newNote, setNewNote] = useState('');
  const [noteLoading, setNoteLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // Decision Dialog State
  const [decisionModal, setDecisionModal] = useState<'resolve' | 'dismiss' | null>(null);
  const [resolutionRemarks, setResolutionRemarks] = useState('');

  const loadComplaint = async () => {
    setLoading(true);
    const data = await fetchAdminComplaintDetail(complaintId);
    setComplaint(data);
    setLoading(false);
  };

  useEffect(() => {
    let isMounted = true;
    fetchAdminComplaintDetail(complaintId).then((data) => {
      if (isMounted) {
        setComplaint(data);
        setLoading(false);
      }
    });
    return () => {
      isMounted = false;
    };
  }, [complaintId]);

  const handleAddNote = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newNote.trim()) return;

    setNoteLoading(true);
    const res = await addComplaintNote(complaintId, newNote.trim());
    if (res.success) {
      setNewNote('');
      await loadComplaint();
      setFeedback({ type: 'success', text: 'Internal investigation note appended.' });
    } else {
      setFeedback({ type: 'error', text: res.error || 'Failed to add note.' });
    }
    setNoteLoading(false);
  };

  const handleStatusChange = async (status: 'under_review' | 'resolved' | 'dismissed', notes?: string) => {
    setActionLoading(true);
    setFeedback(null);

    const res = await resolveComplaint(complaintId, status, notes);
    if (res.success) {
      setDecisionModal(null);
      setResolutionRemarks('');
      await loadComplaint();
      setFeedback({ type: 'success', text: `Ticket status updated to "${status}".` });
    } else {
      setFeedback({ type: 'error', text: res.error || 'Failed to update ticket status.' });
    }
    setActionLoading(false);
  };

  if (loading) {
    return (
      <AdminShell>
        <div className="p-12 text-center text-xs text-slate-500">Loading complaint investigation...</div>
      </AdminShell>
    );
  }

  if (!complaint) {
    return (
      <AdminShell>
        <div className="rounded-xl border border-slate-200 bg-white p-8 text-center">
          <p className="text-sm font-semibold text-slate-700">Complaint record not found.</p>
          <Link
            href="/admin/complaints"
            className="mt-3 inline-flex items-center gap-1.5 text-xs font-semibold text-indigo-700"
          >
            <ArrowLeft className="h-3.5 w-3.5" /> Back to Complaints
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
          href="/admin/complaints"
          className="inline-flex items-center gap-1 text-xs font-medium text-slate-500 hover:text-slate-800"
        >
          <ArrowLeft className="h-3.5 w-3.5" /> Back to Complaints Queue
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

      {/* Ticket Header */}
      <div className="mt-4 rounded-xl border border-slate-200 bg-white p-6 shadow-xs">
        <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
          <div>
            <div className="flex items-center gap-2">
              <span className="rounded bg-slate-100 px-2 py-0.5 text-[10px] font-bold text-slate-700 uppercase">
                {complaint.category.replace('_', ' ')}
              </span>
              <span className="font-mono text-xs text-slate-400">ID: {complaint.id}</span>
            </div>
            <h1 className="mt-2 text-xl font-black text-slate-900">
              {formatComplaintCategory(complaint.category)}
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">
              Submitted on {new Date(complaint.submitted_at).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })}
            </p>
          </div>

          {/* Decision Buttons */}
          <div className="flex flex-wrap items-center gap-2">
            {complaint.complaint_status !== 'under_review' && complaint.complaint_status !== 'resolved' && (
              <button
                disabled={actionLoading}
                onClick={() => handleStatusChange('under_review', 'Investigating dispute facts')}
                className="inline-flex items-center gap-1.5 rounded-lg border border-blue-300 bg-blue-50 px-3 py-1.5 text-xs font-semibold text-blue-700 hover:bg-blue-100 disabled:opacity-50"
              >
                <Clock className="h-3.5 w-3.5" />
                <span>Mark Under Review</span>
              </button>
            )}

            {complaint.complaint_status !== 'resolved' && (
              <button
                disabled={actionLoading}
                onClick={() => setDecisionModal('resolve')}
                className="inline-flex items-center gap-1.5 rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white shadow-xs hover:bg-emerald-700 disabled:opacity-50"
              >
                <CheckCircle2 className="h-3.5 w-3.5" />
                <span>Resolve Dispute</span>
              </button>
            )}

            {complaint.complaint_status !== 'dismissed' && (
              <button
                disabled={actionLoading}
                onClick={() => setDecisionModal('dismiss')}
                className="inline-flex items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50"
              >
                <XCircle className="h-3.5 w-3.5" />
                <span>Dismiss</span>
              </button>
            )}
          </div>
        </div>

        {/* Reporter vs Reported Target */}
        <div className="mt-6 grid grid-cols-1 sm:grid-cols-2 gap-4 border-t border-slate-100 pt-5 text-xs">
          <div className="rounded-lg bg-slate-50 p-3 border border-slate-100">
            <span className="text-slate-400 font-medium">Submitted By (Reporter):</span>
            <div className="font-semibold text-slate-900 flex items-center gap-1 mt-1">
              <User className="h-3.5 w-3.5 text-slate-500" />
              {complaint.submitted_by_name}
            </div>
          </div>

          <div className="rounded-lg bg-slate-50 p-3 border border-slate-100">
            <span className="text-slate-400 font-medium">Reported Entity / Target:</span>
            <div className="font-semibold text-rose-700 flex items-center gap-1 mt-1">
              <Building2 className="h-3.5 w-3.5 text-rose-500" />
              {complaint.reported_user_name || complaint.business_name || 'Platform Incident'}
            </div>
          </div>
        </div>
      </div>

      {/* Grievance Narrative */}
      <div className="mt-6 rounded-xl border border-slate-200 bg-white p-6 shadow-xs space-y-3">
        <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
          <FileText className="h-4 w-4 text-indigo-700" />
          Incident Statement
        </h2>
        <p className="text-xs text-slate-700 leading-relaxed bg-slate-50 p-4 rounded-xl border border-slate-200 whitespace-pre-wrap">
          {complaint.description}
        </p>

        {complaint.admin_notes && (
          <div className="mt-3 rounded-lg bg-amber-50 p-3 text-xs text-amber-900 border border-amber-200">
            <span className="font-bold">Official Resolution Remarks: </span>
            {complaint.admin_notes}
          </div>
        )}
      </div>

      {/* Internal Admin Investigation Thread */}
      <div className="mt-6 rounded-xl border border-slate-200 bg-white p-6 shadow-xs">
        <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
          <MessageSquare className="h-4 w-4 text-indigo-700" />
          Internal Admin Notes History
        </h2>
        <p className="text-xs text-slate-500 mt-0.5">
          Private administrative investigation log (not visible to worker or business owner).
        </p>

        {/* Existing Notes */}
        <div className="mt-4 space-y-3">
          {complaint.notes_history && complaint.notes_history.length > 0 ? (
            complaint.notes_history.map((n) => (
              <div key={n.id} className="rounded-lg bg-slate-50 p-3 border border-slate-200 text-xs">
                <div className="flex items-center justify-between text-slate-400 text-[11px]">
                  <span className="font-semibold text-slate-700">Administrator Note</span>
                  <span>{new Date(n.created_at).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })}</span>
                </div>
                <p className="mt-1.5 text-slate-800">{n.note}</p>
              </div>
            ))
          ) : (
            <div className="rounded-lg bg-slate-50 p-4 text-center text-xs text-slate-400">
              No internal investigation notes logged yet.
            </div>
          )}
        </div>

        {/* Append Note Form */}
        <form onSubmit={handleAddNote} className="mt-4 flex gap-2">
          <input
            type="text"
            value={newNote}
            onChange={(e) => setNewNote(e.target.value)}
            placeholder="Log call attempt, statement summary, or verification detail..."
            className="flex-1 rounded-lg border border-slate-300 px-3 py-2 text-xs focus:border-indigo-600 focus:outline-none"
          />
          <button
            type="submit"
            disabled={noteLoading || !newNote.trim()}
            className="inline-flex items-center gap-1.5 rounded-lg bg-indigo-900 px-3.5 py-2 text-xs font-semibold text-white hover:bg-indigo-800 disabled:opacity-50"
          >
            <Send className="h-3.5 w-3.5" />
            <span>Add Note</span>
          </button>
        </form>
      </div>

      {/* Decision Dialog Modal */}
      {decisionModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl border border-slate-200">
            <h3 className="text-base font-bold text-slate-900">
              {decisionModal === 'resolve' ? 'Resolve Complaint' : 'Dismiss Complaint'}
            </h3>
            <p className="text-xs text-slate-500 mt-1">
              {decisionModal === 'resolve'
                ? 'Record the resolution details for both parties.'
                : 'State reasons why this grievance is invalid or dismissed.'}
            </p>

            <textarea
              rows={3}
              value={resolutionRemarks}
              onChange={(e) => setResolutionRemarks(e.target.value)}
              placeholder="e.g. Wage discrepancy rectified or complaint unsubstantiated..."
              className="mt-3 w-full rounded-lg border border-slate-300 p-2.5 text-xs focus:border-indigo-600 focus:outline-none"
            />

            <div className="mt-4 flex justify-end gap-2">
              <button
                onClick={() => {
                  setDecisionModal(null);
                  setResolutionRemarks('');
                }}
                disabled={actionLoading}
                className="rounded-lg border border-slate-300 px-3.5 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
              >
                Cancel
              </button>
              <button
                disabled={actionLoading || !resolutionRemarks.trim()}
                onClick={() =>
                  handleStatusChange(
                    decisionModal === 'resolve' ? 'resolved' : 'dismissed',
                    resolutionRemarks.trim()
                  )
                }
                className={`rounded-lg px-3.5 py-1.5 text-xs font-semibold text-white disabled:opacity-50 ${
                  decisionModal === 'resolve'
                    ? 'bg-emerald-600 hover:bg-emerald-700'
                    : 'bg-slate-700 hover:bg-slate-800'
                }`}
              >
                Confirm {decisionModal === 'resolve' ? 'Resolution' : 'Dismissal'}
              </button>
            </div>
          </div>
        </div>
      )}
    </AdminShell>
  );
}

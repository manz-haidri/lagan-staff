'use client';

import React, { useState, useEffect, use } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import {
  ArrowLeft,
  Building2,
  MapPin,
  Phone,
  User,
  FileText,
  ShieldCheck,
  Clock,
  XCircle,
  AlertTriangle,
  Download,
  CheckCircle2,
  ExternalLink,
} from 'lucide-react';
import {
  AdminBusinessRecord,
  AdminAuditLog,
  fetchAdminBusinessDetail,
  performAdminBusinessReview,
  getDocumentSignedUrl,
  formatCategoryName,
} from '@/lib/business-service';

export default function AdminBusinessDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const resolvedParams = use(params);
  const id = resolvedParams.id;

  const [business, setBusiness] = useState<AdminBusinessRecord | null>(null);
  const [auditLogs, setAuditLogs] = useState<AdminAuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionInProgress, setActionInProgress] = useState(false);
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [rejectionReason, setRejectionReason] = useState('');

  const loadData = async () => {
    setLoading(true);
    try {
      const res = await fetchAdminBusinessDetail(id);
      setBusiness(res.business);
      setAuditLogs(res.auditLogs);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let isMounted = true;
    fetchAdminBusinessDetail(id).then((res) => {
      if (isMounted) {
        setBusiness(res.business);
        setAuditLogs(res.auditLogs);
        setLoading(false);
      }
    });
    return () => {
      isMounted = false;
    };
  }, [id]);

  const handleAction = async (action: 'approve' | 'mark_under_review' | 'suspend' | 'reactivate') => {
    setActionInProgress(true);
    try {
      const res = await performAdminBusinessReview({
        businessId: id,
        action,
      });
      if (res.success) {
        await loadData();
      } else {
        alert(`Action failed: ${res.error}`);
      }
    } finally {
      setActionInProgress(false);
    }
  };

  const handleReject = async () => {
    if (rejectionReason.trim().length < 3) {
      alert('Please enter a clear rejection reason.');
      return;
    }

    setActionInProgress(true);
    try {
      const res = await performAdminBusinessReview({
        businessId: id,
        action: 'reject',
        rejectionReason: rejectionReason.trim(),
      });
      if (res.success) {
        setShowRejectModal(false);
        setRejectionReason('');
        await loadData();
      } else {
        alert(`Reject failed: ${res.error}`);
      }
    } finally {
      setActionInProgress(false);
    }
  };

  const handleOpenDoc = async (storagePath: string) => {
    const url = await getDocumentSignedUrl(storagePath);
    if (url) {
      window.open(url, '_blank');
    } else {
      alert('Unable to generate secure download URL.');
    }
  };

  if (loading) {
    return (
      <AdminShell>
        <div className="flex h-64 items-center justify-center text-xs text-slate-500">
          Loading business details...
        </div>
      </AdminShell>
    );
  }

  if (!business) {
    return (
      <AdminShell>
        <div className="p-8 text-center bg-white rounded-xl border border-slate-200">
          <h2 className="text-sm font-bold text-slate-900">Business Record Not Found</h2>
          <p className="mt-1 text-xs text-slate-500">The business ID does not exist in LaganStaff registry.</p>
          <Link
            href="/admin/businesses"
            className="mt-4 inline-flex items-center gap-1 rounded-lg bg-indigo-900 px-3.5 py-1.5 text-xs text-white"
          >
            <ArrowLeft className="h-3.5 w-3.5" /> Back to Businesses
          </Link>
        </div>
      </AdminShell>
    );
  }

  return (
    <AdminShell>
      {/* Back button & Title */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-3">
          <Link
            href="/admin/businesses"
            className="flex h-8 w-8 items-center justify-center rounded-lg border border-slate-300 bg-white text-slate-600 hover:bg-slate-50"
          >
            <ArrowLeft className="h-4 w-4" />
          </Link>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-2xl font-bold tracking-tight text-slate-900">{business.name}</h1>
              <DetailStatusBadge status={business.verification_status} />
            </div>
            <p className="text-xs text-slate-500">
              {formatCategoryName(business.business_type)} • ID: {business.id}
            </p>
          </div>
        </div>

        {/* Action Bar */}
        <div className="flex flex-wrap items-center gap-2">
          {business.verification_status === 'pending' && (
            <button
              disabled={actionInProgress}
              onClick={() => handleAction('mark_under_review')}
              className="inline-flex items-center gap-1.5 rounded-lg border border-blue-300 bg-blue-50 px-3 py-1.5 text-xs font-semibold text-blue-700 hover:bg-blue-100 disabled:opacity-50"
            >
              <Clock className="h-3.5 w-3.5" />
              <span>Mark Under Review</span>
            </button>
          )}

          {business.verification_status !== 'verified' && (
            <button
              disabled={actionInProgress}
              onClick={() => handleAction('approve')}
              className="inline-flex items-center gap-1.5 rounded-lg bg-emerald-600 px-3.5 py-1.5 text-xs font-semibold text-white shadow-xs hover:bg-emerald-700 disabled:opacity-50"
            >
              <CheckCircle2 className="h-3.5 w-3.5" />
              <span>Approve & Verify</span>
            </button>
          )}

          {business.verification_status !== 'rejected' && (
            <button
              disabled={actionInProgress}
              onClick={() => setShowRejectModal(true)}
              className="inline-flex items-center gap-1.5 rounded-lg border border-rose-300 bg-rose-50 px-3 py-1.5 text-xs font-semibold text-rose-700 hover:bg-rose-100 disabled:opacity-50"
            >
              <XCircle className="h-3.5 w-3.5" />
              <span>Reject Application</span>
            </button>
          )}

          {business.verification_status === 'verified' && (
            <button
              disabled={actionInProgress}
              onClick={() => handleAction('suspend')}
              className="inline-flex items-center gap-1.5 rounded-lg border border-amber-300 bg-amber-50 px-3 py-1.5 text-xs font-semibold text-amber-800 hover:bg-amber-100 disabled:opacity-50"
            >
              <AlertTriangle className="h-3.5 w-3.5" />
              <span>Suspend Business</span>
            </button>
          )}

          {business.verification_status === 'suspended' && (
            <button
              disabled={actionInProgress}
              onClick={() => handleAction('reactivate')}
              className="inline-flex items-center gap-1.5 rounded-lg bg-emerald-600 px-3.5 py-1.5 text-xs font-semibold text-white hover:bg-emerald-700 disabled:opacity-50 shadow-xs"
            >
              <ShieldCheck className="h-3.5 w-3.5" />
              <span>Reactivate</span>
            </button>
          )}
        </div>
      </div>

      {/* Rejection Notice Banner if rejected */}
      {business.verification_status === 'rejected' && (
        <div className="mt-6 rounded-xl border border-rose-200 bg-rose-50 p-4">
          <div className="flex items-start gap-2.5">
            <XCircle className="h-5 w-5 text-rose-600 shrink-0 mt-0.5" />
            <div>
              <div className="text-xs font-bold text-rose-900">Application Currently Rejected</div>
              <div className="mt-1 text-xs text-rose-700">
                Reason provided: <span className="font-semibold">{business.rejection_reason}</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Main Grid: Info + Documents + Audit */}
      <div className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Left Column (2 Cols): Details & Location */}
        <div className="space-y-6 lg:col-span-2">
          {/* Card 1: Core Details */}
          <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-xs">
            <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
              <Building2 className="h-4 w-4 text-indigo-700" />
              Business Profile & Contact Details
            </h2>
            <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 text-xs">
              <div>
                <span className="text-slate-400">Business Name</span>
                <p className="mt-0.5 font-semibold text-slate-800">{business.name}</p>
              </div>
              <div>
                <span className="text-slate-400">Industry Category</span>
                <p className="mt-0.5 font-semibold text-slate-800">
                  {formatCategoryName(business.business_type)}
                </p>
              </div>
              <div>
                <span className="text-slate-400">Owner / Authorized Person</span>
                <p className="mt-0.5 font-semibold text-slate-800 flex items-center gap-1">
                  <User className="h-3.5 w-3.5 text-slate-400" />
                  {business.contact_person || 'Owner'}
                </p>
              </div>
              <div>
                <span className="text-slate-400">Primary Contact Phone</span>
                <p className="mt-0.5 font-semibold text-slate-800 flex items-center gap-1">
                  <Phone className="h-3.5 w-3.5 text-slate-400" />
                  +91 {business.contact_phone}
                </p>
              </div>
              {business.gst_or_trade_id && (
                <div>
                  <span className="text-slate-400">GST / Trade License ID</span>
                  <p className="mt-0.5 font-mono font-semibold text-slate-800">
                    {business.gst_or_trade_id}
                  </p>
                </div>
              )}
              <div>
                <span className="text-slate-400">First-Job Approved?</span>
                <p className="mt-0.5 font-semibold text-slate-800">
                  {business.is_first_job_approved ? 'Yes (Auto-Publishing Active)' : 'Pending (Requires First Job Check)'}
                </p>
              </div>
              {business.description && (
                <div className="sm:col-span-2">
                  <span className="text-slate-400">Description / Services</span>
                  <p className="mt-1 text-slate-700 leading-relaxed bg-slate-50 p-2.5 rounded-lg border border-slate-100">
                    {business.description}
                  </p>
                </div>
              )}
            </div>
          </div>

          {/* Card 2: Location & Address */}
          <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-xs">
            <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
              <MapPin className="h-4 w-4 text-indigo-700" />
              Venue & Commercial Location
            </h2>
            <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 text-xs">
              <div>
                <span className="text-slate-400">Locality / Area</span>
                <p className="mt-0.5 font-semibold text-slate-800">{business.locality}</p>
              </div>
              <div>
                <span className="text-slate-400">PIN Code</span>
                <p className="mt-0.5 font-semibold text-slate-800">{business.pincode}</p>
              </div>
              <div>
                <span className="text-slate-400">City & District</span>
                <p className="mt-0.5 font-semibold text-slate-800">
                  {business.city}, {business.district}
                </p>
              </div>
              <div>
                <span className="text-slate-400">State & Country</span>
                <p className="mt-0.5 font-semibold text-slate-800">
                  {business.state}, {business.country}
                </p>
              </div>
              {business.address && (
                <div className="sm:col-span-2">
                  <span className="text-slate-400">Full Business Address</span>
                  <p className="mt-0.5 text-slate-700 font-medium">{business.address}</p>
                </div>
              )}
              {business.latitude && business.longitude && (
                <div className="sm:col-span-2 flex items-center justify-between rounded-lg bg-slate-50 p-3 border border-slate-200">
                  <div className="text-slate-600">
                    GPS Coordinates: <span className="font-mono font-medium">{business.latitude}, {business.longitude}</span>
                  </div>
                  <a
                    href={`https://maps.google.com/?q=${business.latitude},${business.longitude}`}
                    target="_blank"
                    rel="noreferrer"
                    className="inline-flex items-center gap-1 text-indigo-700 font-semibold hover:underline"
                  >
                    <span>View on Google Maps</span>
                    <ExternalLink className="h-3.5 w-3.5" />
                  </a>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Right Column: Submitted Documents & Audit Logs */}
        <div className="space-y-6">
          {/* Attached Proofs */}
          <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-xs">
            <h2 className="text-sm font-bold text-slate-900 flex items-center justify-between">
              <span className="flex items-center gap-2">
                <FileText className="h-4 w-4 text-indigo-700" />
                Submitted Proofs ({business.documents?.length || 0})
              </span>
            </h2>

            <div className="mt-4 space-y-2.5">
              {!business.documents || business.documents.length === 0 ? (
                <div className="rounded-lg bg-slate-50 p-4 text-center text-xs text-slate-400">
                  No documents attached (Optional for MVP).
                </div>
              ) : (
                business.documents.map((doc) => (
                  <div
                    key={doc.id}
                    className="flex items-center justify-between rounded-lg border border-slate-200 bg-slate-50/50 p-3 text-xs"
                  >
                    <div>
                      <div className="font-semibold text-slate-800">
                        {doc.document_type.replace('_', ' ').toUpperCase()}
                      </div>
                      <div className="text-[11px] text-slate-500">
                        {doc.file_name} • {(doc.file_size_bytes / 1024).toFixed(1)} KB
                      </div>
                    </div>
                    <button
                      onClick={() => handleOpenDoc(doc.storage_path)}
                      className="inline-flex items-center gap-1 rounded-md bg-white border border-slate-300 px-2.5 py-1 text-[11px] font-semibold text-indigo-700 shadow-2xs hover:bg-slate-50"
                    >
                      <Download className="h-3 w-3" />
                      View
                    </button>
                  </div>
                ))
              )}
            </div>
          </div>

          {/* Audit Trail */}
          <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-xs">
            <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
              <Clock className="h-4 w-4 text-indigo-700" />
              Verification Timeline
            </h2>

            <div className="mt-4 space-y-3 text-xs">
              <div className="flex items-start gap-2 border-l-2 border-slate-200 pl-3">
                <div>
                  <div className="font-semibold text-slate-800">Profile Created</div>
                  <div className="text-[11px] text-slate-400">
                    {new Date(business.created_at).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })}
                  </div>
                </div>
              </div>

              {business.submitted_at && (
                <div className="flex items-start gap-2 border-l-2 border-amber-400 pl-3">
                  <div>
                    <div className="font-semibold text-slate-800">Submitted for Verification</div>
                    <div className="text-[11px] text-slate-400">
                      {new Date(business.submitted_at).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })}
                    </div>
                  </div>
                </div>
              )}

              {auditLogs.map((log) => (
                <div key={log.id} className="flex items-start gap-2 border-l-2 border-indigo-600 pl-3">
                  <div>
                    <div className="font-semibold text-slate-800">
                      Action: {log.action_type.toUpperCase()}
                    </div>
                    <div className="text-[11px] text-slate-500">
                      {new Date(log.created_at).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Reject Reason Modal */}
      {showRejectModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-xs">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">
            <h3 className="text-lg font-bold text-slate-900">Reject Business Verification</h3>
            <p className="mt-1 text-xs text-slate-500">
              Provide a clear reason for rejecting {business.name}. The owner will be notified to edit and resubmit.
            </p>

            <div className="mt-4">
              <label className="text-xs font-semibold text-slate-700">
                Rejection Reason (अस्वीकृति का कारण) *
              </label>
              <textarea
                rows={3}
                value={rejectionReason}
                onChange={(e) => setRejectionReason(e.target.value)}
                placeholder="e.g. व्यापार का पता स्पष्ट नहीं है। कृपया सही लैंडमार्क दर्ज करें..."
                className="mt-1 w-full rounded-lg border border-slate-300 p-2.5 text-xs text-slate-800 focus:border-rose-500 focus:outline-none"
              />
            </div>

            <div className="mt-6 flex justify-end gap-2">
              <button
                onClick={() => {
                  setShowRejectModal(false);
                  setRejectionReason('');
                }}
                className="rounded-lg border border-slate-300 px-3.5 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
              >
                Cancel
              </button>
              <button
                disabled={actionInProgress || rejectionReason.trim().length < 3}
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

function DetailStatusBadge({ status }: { status: string }) {
  switch (status) {
    case 'verified':
      return (
        <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2.5 py-0.5 text-xs font-semibold text-emerald-700 border border-emerald-200">
          <ShieldCheck className="h-3.5 w-3.5" /> Verified
        </span>
      );
    case 'under_review':
      return (
        <span className="inline-flex items-center gap-1 rounded-full bg-blue-50 px-2.5 py-0.5 text-xs font-semibold text-blue-700 border border-blue-200">
          <Clock className="h-3.5 w-3.5" /> Under Review
        </span>
      );
    case 'rejected':
      return (
        <span className="inline-flex items-center gap-1 rounded-full bg-rose-50 px-2.5 py-0.5 text-xs font-semibold text-rose-700 border border-rose-200">
          <XCircle className="h-3.5 w-3.5" /> Rejected
        </span>
      );
    case 'suspended':
      return (
        <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2.5 py-0.5 text-xs font-semibold text-amber-800 border border-amber-300">
          <AlertTriangle className="h-3.5 w-3.5" /> Suspended
        </span>
      );
    case 'pending':
    default:
      return (
        <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2.5 py-0.5 text-xs font-semibold text-amber-700 border border-amber-200">
          <Clock className="h-3.5 w-3.5" /> Pending Review
        </span>
      );
  }
}

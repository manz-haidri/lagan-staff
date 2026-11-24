import React from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { fetchDashboardMetrics } from '@/lib/dashboard-service';
import {
  Users,
  Building2,
  Briefcase,
  CalendarCheck,
  AlertOctagon,
  ArrowUpRight,
  Clock,
  UserCheck,
  CheckCircle2,
  XCircle,
  FileCheck2,
} from 'lucide-react';

export default async function AdminDashboardPage() {
  const m = await fetchDashboardMetrics();

  return (
    <AdminShell>
      {/* Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-black tracking-tight text-slate-900">Platform Control Center</h1>
          <p className="text-xs text-slate-500 font-medium">Real-time marketplace operations for Ghazipur District</p>
        </div>
        <div className="flex items-center gap-2">
          <Link
            href="/admin/business-verifications"
            className="inline-flex items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 shadow-xs"
          >
            <Building2 className="h-3.5 w-3.5 text-slate-500" />
            <span>Verify Businesses ({m.users.pending_business_verifications})</span>
          </Link>
          <Link
            href="/admin/job-approvals"
            className="inline-flex items-center gap-1.5 rounded-lg bg-indigo-900 px-3.5 py-1.5 text-xs font-semibold text-white shadow-xs hover:bg-indigo-800"
          >
            <Clock className="h-3.5 w-3.5 text-amber-300" />
            <span>Review First-Jobs ({m.jobs.pending_approval_jobs})</span>
          </Link>
        </div>
      </div>

      {/* Primary KPI Grid (4 Columns) */}
      <div className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {/* Workers */}
        <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500">Workers</span>
            <span className="rounded-md bg-indigo-50 p-2 text-indigo-900">
              <Users className="h-4 w-4" />
            </span>
          </div>
          <div className="mt-2 text-2xl font-black text-slate-900">{m.users.total_workers}</div>
          <div className="mt-2 flex items-center justify-between text-xs text-slate-600 border-t border-slate-100 pt-2">
            <span>सक्रिय: <strong className="text-emerald-600">{m.users.active_workers}</strong></span>
            <span>निलंबित: <strong className="text-red-600">{m.users.suspended_workers}</strong></span>
            <span>असमरीक्षित: <strong className="text-amber-600">{m.users.unreviewed_workers}</strong></span>
          </div>
        </div>

        {/* Businesses */}
        <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500">Businesses & Lawns</span>
            <span className="rounded-md bg-indigo-50 p-2 text-indigo-900">
              <Building2 className="h-4 w-4" />
            </span>
          </div>
          <div className="mt-2 text-2xl font-black text-slate-900">{m.users.total_businesses}</div>
          <div className="mt-2 flex items-center justify-between text-xs text-slate-600 border-t border-slate-100 pt-2">
            <span>सत्यापित: <strong className="text-emerald-600">{m.users.verified_businesses}</strong></span>
            <span>लंबित: <strong className="text-amber-600">{m.users.pending_business_verifications}</strong></span>
            <span>मालिक: <strong className="text-slate-800">{m.users.total_owners}</strong></span>
          </div>
        </div>

        {/* Master Jobs */}
        <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500">Total Shift Jobs</span>
            <span className="rounded-md bg-indigo-50 p-2 text-indigo-900">
              <Briefcase className="h-4 w-4" />
            </span>
          </div>
          <div className="mt-2 text-2xl font-black text-slate-900">{m.jobs.total_jobs}</div>
          <div className="mt-2 flex items-center justify-between text-xs text-slate-600 border-t border-slate-100 pt-2">
            <span>लाइव: <strong className="text-emerald-600">{m.jobs.published_jobs}</strong></span>
            <span>समीक्षा: <strong className="text-amber-600">{m.jobs.pending_approval_jobs}</strong></span>
            <span>रद्द: <strong className="text-slate-400">{m.jobs.cancelled_jobs}</strong></span>
          </div>
        </div>

        {/* Bookings & Attendance */}
        <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500">Attendance & Shifts</span>
            <span className="rounded-md bg-indigo-50 p-2 text-indigo-900">
              <CalendarCheck className="h-4 w-4" />
            </span>
          </div>
          <div className="mt-2 text-2xl font-black text-slate-900">{m.bookings.total_bookings}</div>
          <div className="mt-2 flex items-center justify-between text-xs text-slate-600 border-t border-slate-100 pt-2">
            <span>उपस्थित: <strong className="text-emerald-600">{m.attendance.present}</strong></span>
            <span>अनुपस्थित: <strong className="text-red-500">{m.attendance.absent}</strong></span>
            <span>नो-शो: <strong className="text-purple-600">{m.attendance.no_show}</strong></span>
          </div>
        </div>
      </div>

      {/* Secondary Alerts & Queues Strip */}
      <div className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {/* Complaints Alert Card */}
        <div className="rounded-xl border border-red-200 bg-red-50/50 p-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 font-bold text-sm text-red-900">
              <AlertOctagon className="h-4 w-4 text-red-600" />
              <span>Complaints & Disputes</span>
            </div>
            <Link href="/admin/complaints" className="text-xs font-bold text-red-700 hover:underline flex items-center gap-0.5">
              <span>Queue ({m.complaints.open + m.complaints.under_review})</span>
              <ArrowUpRight className="h-3 w-3" />
            </Link>
          </div>
          <p className="mt-1 text-xs text-red-800">
            {m.complaints.open} खुली शिकायतें • {m.complaints.under_review} समीक्षाधीन • {m.complaints.resolved} सुलझाई गईं
          </p>
        </div>

        {/* Worker Review Alert Card */}
        <div className="rounded-xl border border-amber-200 bg-amber-50/50 p-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 font-bold text-sm text-amber-900">
              <FileCheck2 className="h-4 w-4 text-amber-600" />
              <span>Worker Post-Onboarding Review</span>
            </div>
            <Link href="/admin/worker-verification" className="text-xs font-bold text-amber-700 hover:underline flex items-center gap-0.5">
              <span>View ({m.users.unreviewed_workers})</span>
              <ArrowUpRight className="h-3 w-3" />
            </Link>
          </div>
          <p className="mt-1 text-xs text-amber-800">
            {m.users.unreviewed_workers} नए कार्यकर्ता सेल्फी समीक्षा हेतु प्रतीक्षारत हैं।
          </p>
        </div>

        {/* First-Job Verification Status */}
        <div className="rounded-xl border border-indigo-200 bg-indigo-50/50 p-4 sm:col-span-2 lg:col-span-1">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 font-bold text-sm text-indigo-900">
              <CheckCircle2 className="h-4 w-4 text-indigo-600" />
              <span>First-Job Quality Gate</span>
            </div>
            <Link href="/admin/job-approvals" className="text-xs font-bold text-indigo-700 hover:underline flex items-center gap-0.5">
              <span>Inspect ({m.jobs.pending_approval_jobs})</span>
              <ArrowUpRight className="h-3 w-3" />
            </Link>
          </div>
          <p className="mt-1 text-xs text-indigo-900">
            {m.jobs.pending_approval_jobs} प्रथम कार्य अनुमोदन हेतु कतार में हैं।
          </p>
        </div>
      </div>

      {/* Main Operational Split Section */}
      <div className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Quick Actions Panel */}
        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-xs">
          <h2 className="text-sm font-bold text-slate-900 uppercase tracking-wider text-[11px]">Operations Fast-Track</h2>
          <div className="mt-4 grid grid-cols-2 gap-3">
            <Link
              href="/admin/workers"
              className="flex items-center gap-3 rounded-lg border border-slate-200 p-3 hover:bg-slate-50 transition-colors"
            >
              <div className="rounded-lg bg-indigo-50 p-2 text-indigo-900">
                <Users className="h-4 w-4" />
              </div>
              <div>
                <div className="text-xs font-bold text-slate-900">कार्यकर्ता निर्देशिका</div>
                <div className="text-[10px] text-slate-500">खोजें व प्रबंधित करें</div>
              </div>
            </Link>

            <Link
              href="/admin/owners"
              className="flex items-center gap-3 rounded-lg border border-slate-200 p-3 hover:bg-slate-50 transition-colors"
            >
              <div className="rounded-lg bg-indigo-50 p-2 text-indigo-900">
                <UserCheck className="h-4 w-4" />
              </div>
              <div>
                <div className="text-xs font-bold text-slate-900">मालिक निर्देशिका</div>
                <div className="text-[10px] text-slate-500">व्यवसाय स्वामी प्रोफ़ाइल</div>
              </div>
            </Link>

            <Link
              href="/admin/categories"
              className="flex items-center gap-3 rounded-lg border border-slate-200 p-3 hover:bg-slate-50 transition-colors"
            >
              <div className="rounded-lg bg-indigo-50 p-2 text-indigo-900">
                <Briefcase className="h-4 w-4" />
              </div>
              <div>
                <div className="text-xs font-bold text-slate-900">श्रेणियाँ व हुनर</div>
                <div className="text-[10px] text-slate-500">Categories & Skills</div>
              </div>
            </Link>

            <Link
              href="/admin/analytics"
              className="flex items-center gap-3 rounded-lg border border-slate-200 p-3 hover:bg-slate-50 transition-colors"
            >
              <div className="rounded-lg bg-indigo-50 p-2 text-indigo-900">
                <CalendarCheck className="h-4 w-4" />
              </div>
              <div>
                <div className="text-xs font-bold text-slate-900">प्लेटफ़ॉर्म आंकड़े</div>
                <div className="text-[10px] text-slate-500">Analytics & Trends</div>
              </div>
            </Link>
          </div>
        </div>

        {/* System Health & Architecture Summary */}
        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-xs">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-bold text-slate-900 uppercase tracking-wider text-[11px]">System Environment</h2>
            <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-0.5 text-[10px] font-bold text-emerald-700">
              <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
              Live Gateway
            </span>
          </div>
          <div className="mt-4 space-y-2 text-xs text-slate-600">
            <div className="flex justify-between py-1.5 border-b border-slate-100">
              <span className="text-slate-500">Target Domain:</span>
              <span className="font-mono font-semibold text-slate-800">admin.laganstaff.in</span>
            </div>
            <div className="flex justify-between py-1.5 border-b border-slate-100">
              <span className="text-slate-500">Primary Database:</span>
              <span className="font-mono font-semibold text-slate-800">Supabase PostgreSQL 15 (ap-south-1)</span>
            </div>
            <div className="flex justify-between py-1.5 border-b border-slate-100">
              <span className="text-slate-500">Audit Trails:</span>
              <span className="font-semibold text-emerald-700">admin_audit_logs Active</span>
            </div>
            <div className="flex justify-between py-1.5">
              <span className="text-slate-500">Market Launch Cluster:</span>
              <span className="font-semibold text-indigo-900">Ghazipur, Saidpur, Zamania, Mohammadabad</span>
            </div>
          </div>
        </div>
      </div>
    </AdminShell>
  );
}

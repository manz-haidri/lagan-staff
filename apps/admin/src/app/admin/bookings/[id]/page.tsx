'use client';

import React, { useEffect, useState, use } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { fetchBookingDetail, AdminBookingRecord } from '@/lib/booking-service';
import {
  ArrowLeft,
  Calendar,
  Building2,
  Clock,
  KeyRound,
  User,
  ExternalLink,
  ShieldCheck,
} from 'lucide-react';

export default function AdminBookingDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const resolvedParams = use(params);
  const [booking, setBooking] = useState<AdminBookingRecord | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      setLoading(true);
      const data = await fetchBookingDetail(resolvedParams.id);
      setBooking(data);
      setLoading(false);
    }
    load();
  }, [resolvedParams.id]);

  if (loading) {
    return (
      <AdminShell>
        <div className="p-12 text-center text-xs text-slate-500">Loading booking record...</div>
      </AdminShell>
    );
  }

  if (!booking) {
    return (
      <AdminShell>
        <div className="rounded-xl border border-slate-200 bg-white p-8 text-center">
          <p className="text-sm font-semibold text-slate-700">Booking record not found.</p>
          <Link
            href="/admin/bookings"
            className="mt-3 inline-flex items-center gap-1.5 text-xs font-semibold text-indigo-700"
          >
            <ArrowLeft className="h-3.5 w-3.5" /> Back to Bookings Roster
          </Link>
        </div>
      </AdminShell>
    );
  }

  return (
    <AdminShell>
      <div>
        <Link
          href="/admin/bookings"
          className="inline-flex items-center gap-1 text-xs font-medium text-slate-500 hover:text-slate-800"
        >
          <ArrowLeft className="h-3.5 w-3.5" /> Back to Bookings Roster
        </Link>
      </div>

      {/* Main Header */}
      <div className="mt-4 rounded-xl border border-slate-200 bg-white p-6 shadow-xs">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2">
              <span className="font-mono text-xs text-slate-400">ID: {booking.id}</span>
              <span className="rounded-full bg-slate-100 px-2.5 py-0.5 text-[10px] font-bold text-slate-700 uppercase">
                {booking.status}
              </span>
            </div>
            <h1 className="mt-2 text-xl font-black text-slate-900">{booking.job_title}</h1>
            <p className="text-xs text-slate-500 mt-0.5">
              Venue: {booking.venue_name} • {booking.locality}, Ghazipur
            </p>
          </div>

          <div className="rounded-xl bg-indigo-50 border border-indigo-100 p-4 text-center">
            <span className="text-[10px] font-bold text-indigo-800 uppercase tracking-wider block">
              Gate Check-in PIN
            </span>
            <div className="mt-1 flex items-center justify-center gap-1.5 font-mono text-2xl font-black text-indigo-950">
              <KeyRound className="h-5 w-5 text-indigo-600" />
              <span>{booking.checkin_code}</span>
            </div>
          </div>
        </div>

        {/* Metrics Grid */}
        <div className="mt-6 grid grid-cols-2 sm:grid-cols-4 gap-4 border-t border-slate-100 pt-5 text-xs">
          <div>
            <span className="text-slate-400">Shift Date</span>
            <div className="font-semibold text-slate-800 flex items-center gap-1 mt-0.5">
              <Calendar className="h-3.5 w-3.5 text-slate-400" />
              {booking.shift_date}
            </div>
          </div>
          <div>
            <span className="text-slate-400">Shift Timing</span>
            <div className="font-semibold text-slate-800 flex items-center gap-1 mt-0.5">
              <Clock className="h-3.5 w-3.5 text-slate-400" />
              {booking.shift_time}
            </div>
          </div>
          <div>
            <span className="text-slate-400">Agreed Wage</span>
            <div className="font-black text-emerald-700 text-sm mt-0.5">
              ₹{booking.agreed_wage}
            </div>
          </div>
          <div>
            <span className="text-slate-400">Attendance Status</span>
            <div className="font-bold text-slate-800 mt-0.5 capitalize">
              {booking.attendance_status}
            </div>
          </div>
        </div>
      </div>

      {/* Two Column Layout: Worker Info & Business Info */}
      <div className="mt-6 grid grid-cols-1 sm:grid-cols-2 gap-6">
        {/* Worker Column */}
        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-xs space-y-4">
          <div className="flex items-center justify-between border-b border-slate-100 pb-3">
            <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
              <User className="h-4 w-4 text-indigo-600" />
              Assigned Worker
            </h2>
            <Link
              href={`/admin/workers/${booking.worker_profile_id}`}
              className="inline-flex items-center gap-1 text-xs font-semibold text-indigo-900 hover:underline"
            >
              <span>Worker Dossier</span>
              <ExternalLink className="h-3 w-3" />
            </Link>
          </div>

          <div className="text-xs space-y-2">
            <div>
              <span className="text-slate-400">Full Name:</span>
              <p className="font-semibold text-slate-800 mt-0.5">{booking.worker_name}</p>
            </div>
            <div>
              <span className="text-slate-400">Verified Mobile:</span>
              <p className="font-mono font-medium text-slate-800 mt-0.5">{booking.worker_phone}</p>
            </div>
            <div>
              <span className="text-slate-400">Worker Locality:</span>
              <p className="font-medium text-slate-800 mt-0.5">{booking.worker_locality}, Ghazipur</p>
            </div>
          </div>
        </div>

        {/* Business Column */}
        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-xs space-y-4">
          <div className="flex items-center justify-between border-b border-slate-100 pb-3">
            <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
              <Building2 className="h-4 w-4 text-indigo-600" />
              Employer Business
            </h2>
            <Link
              href={`/admin/businesses/${booking.business_id}`}
              className="inline-flex items-center gap-1 text-xs font-semibold text-indigo-900 hover:underline"
            >
              <span>Business Dossier</span>
              <ExternalLink className="h-3 w-3" />
            </Link>
          </div>

          <div className="text-xs space-y-2">
            <div>
              <span className="text-slate-400">Business Name:</span>
              <p className="font-semibold text-slate-800 mt-0.5">{booking.business_name}</p>
            </div>
            <div>
              <span className="text-slate-400">Category:</span>
              <p className="font-medium text-slate-800 mt-0.5 capitalize">{booking.business_type.replace('_', ' ')}</p>
            </div>
            <div>
              <span className="text-slate-400">Contact Phone:</span>
              <p className="font-mono font-medium text-slate-800 mt-0.5">{booking.business_contact_phone}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Attendance & Completion Verification Card */}
      <div className="mt-6 rounded-xl border border-slate-200 bg-white p-5 shadow-xs space-y-3">
        <h2 className="text-sm font-bold text-slate-900 flex items-center gap-2">
          <ShieldCheck className="h-4 w-4 text-indigo-600" />
          Gate Verification & Work Completion Record
        </h2>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs pt-2">
          <div>
            <span className="text-slate-400">Gate Check-in Time:</span>
            <p className="font-semibold text-slate-800 mt-0.5">
              {booking.check_in_time
                ? new Date(booking.check_in_time).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })
                : 'Pending Gate Arrival'}
            </p>
          </div>
          <div>
            <span className="text-slate-400">Shift Completion:</span>
            <p className="font-semibold text-slate-800 mt-0.5 capitalize">
              {booking.work_completion_status}
              {booking.completed_at && ` (${new Date(booking.completed_at).toLocaleTimeString('en-IN', { timeZone: 'Asia/Kolkata' })})`}
            </p>
          </div>
          <div>
            <span className="text-slate-400">Booking Confirmed On:</span>
            <p className="font-semibold text-slate-800 mt-0.5">
              {new Date(booking.confirmed_at).toLocaleDateString('en-IN', { timeZone: 'Asia/Kolkata' })}
            </p>
          </div>
        </div>

        {booking.owner_notes && (
          <div className="mt-3 rounded-lg bg-slate-50 p-3 text-xs text-slate-700 border border-slate-200">
            <span className="font-bold text-slate-800">Owner Attendance Remarks: </span>
            {booking.owner_notes}
          </div>
        )}
      </div>
    </AdminShell>
  );
}

'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { fetchMasterBookingsList, AdminBookingRecord } from '@/lib/booking-service';
import {
  Search,
  KeyRound,
  CheckCircle2,
  Clock,
  XCircle,
  AlertTriangle,
  Building2,
  Calendar,
  Eye,
  User,
} from 'lucide-react';

export default function AdminBookingsPage() {
  const [bookings, setBookings] = useState<AdminBookingRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');

  useEffect(() => {
    async function load() {
      setLoading(true);
      const data = await fetchMasterBookingsList({
        status: statusFilter,
        search: searchTerm,
      });
      setBookings(data);
      setLoading(false);
    }
    load();
  }, [searchTerm, statusFilter]);

  const getStatusBadge = (status: AdminBookingRecord['status'], attStatus: AdminBookingRecord['attendance_status']) => {
    if (attStatus === 'no_show' || status === 'no_show') {
      return (
        <span className="inline-flex items-center gap-1 rounded-full bg-rose-50 px-2 py-0.5 text-[11px] font-bold text-rose-700 border border-rose-200">
          <XCircle className="h-3 w-3" /> No-Show
        </span>
      );
    }
    if (status === 'completed') {
      return (
        <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-semibold text-slate-700 border border-slate-200">
          <CheckCircle2 className="h-3 w-3 text-slate-500" /> Completed
        </span>
      );
    }
    if (status === 'checked_in' || attStatus === 'checked_in' || attStatus === 'present') {
      return (
        <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-bold text-emerald-700 border border-emerald-200">
          <CheckCircle2 className="h-3 w-3" /> Present / Checked-In
        </span>
      );
    }
    if (status === 'cancelled_by_worker' || status === 'cancelled_by_owner') {
      return (
        <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2 py-0.5 text-[11px] font-semibold text-amber-700 border border-amber-200">
          <AlertTriangle className="h-3 w-3" /> Cancelled
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1 rounded-full bg-blue-50 px-2 py-0.5 text-[11px] font-semibold text-blue-700 border border-blue-200">
        <Clock className="h-3 w-3" /> Confirmed (Gate Pending)
      </span>
    );
  };

  return (
    <AdminShell>
      {/* Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Bookings & Attendance Roster
            </h1>
            <span className="rounded-full bg-slate-200 px-2.5 py-0.5 text-xs font-bold text-slate-700">
              {bookings.length} Bookings
            </span>
          </div>
          <p className="text-xs text-slate-500 font-medium">
            Live duty passes and 4-digit PIN attendance verifications at venue gates in Ghazipur.
          </p>
        </div>

        <Link
          href="/admin/no-shows"
          className="inline-flex items-center gap-1.5 rounded-lg border border-rose-200 bg-rose-50 px-3 py-1.5 text-xs font-semibold text-rose-700 hover:bg-rose-100 shadow-xs"
        >
          <XCircle className="h-3.5 w-3.5 text-rose-600" />
          <span>No-Show Incident Tracker</span>
        </Link>
      </div>

      {/* Filter and Search Bar */}
      <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between bg-white p-3.5 rounded-xl border border-slate-200 shadow-xs">
        <div className="relative w-full sm:w-80">
          <Search className="absolute left-3 top-2.5 h-3.5 w-3.5 text-slate-400" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search booking ID, worker name, PIN..."
            className="w-full rounded-lg border border-slate-300 pl-9 pr-3 py-1.5 text-xs focus:border-indigo-600 focus:outline-none"
          />
        </div>

        <div className="flex items-center gap-2">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="rounded-lg border border-slate-300 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-700 focus:border-indigo-600 focus:outline-none"
          >
            <option value="all">All Booking Statuses</option>
            <option value="confirmed">Confirmed</option>
            <option value="checked_in">Checked In</option>
            <option value="completed">Completed</option>
            <option value="no_show">No Show</option>
            <option value="cancelled_by_worker">Worker Cancelled</option>
            <option value="cancelled_by_owner">Owner Cancelled</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="mt-4 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xs">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200 text-left text-xs">
            <thead className="bg-slate-50 text-slate-600 font-semibold uppercase tracking-wider text-[11px]">
              <tr>
                <th className="px-4 py-3">Booking ID</th>
                <th className="px-4 py-3">Shift & Venue</th>
                <th className="px-4 py-3">Worker Info</th>
                <th className="px-4 py-3 text-center">Duty Pass PIN</th>
                <th className="px-4 py-3 font-semibold">Agreed Wage</th>
                <th className="px-4 py-3">Gate Attendance</th>
                <th className="px-4 py-3 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {loading ? (
                <tr>
                  <td colSpan={7} className="px-4 py-12 text-center text-slate-400">
                    Loading bookings roster...
                  </td>
                </tr>
              ) : bookings.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-4 py-12 text-center text-slate-400">
                    No bookings found matching filters.
                  </td>
                </tr>
              ) : (
                bookings.map((b) => (
                  <tr key={b.id} className="hover:bg-slate-50/80 transition">
                    <td className="px-4 py-3.5 font-mono text-[11px] text-slate-500">
                      {b.id.substring(0, 10)}...
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="font-bold text-slate-900">{b.job_title}</div>
                      <div className="text-[11px] text-slate-500 flex items-center gap-1 mt-0.5">
                        <Building2 className="h-3 w-3 text-slate-400" />
                        {b.business_name} ({b.locality})
                      </div>
                      <div className="text-[11px] text-slate-400 flex items-center gap-1 mt-0.5">
                        <Calendar className="h-3 w-3 text-slate-400" />
                        {b.shift_date} • {b.shift_time}
                      </div>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="font-semibold text-slate-900 flex items-center gap-1">
                        <User className="h-3 w-3 text-slate-400" />
                        {b.worker_name}
                      </div>
                      <div className="font-mono text-[11px] text-slate-500">{b.worker_phone}</div>
                    </td>
                    <td className="px-4 py-3.5 text-center">
                      <span className="inline-flex items-center gap-1 font-mono font-black text-xs bg-indigo-50 border border-indigo-200 text-indigo-900 px-2 py-1 rounded">
                        <KeyRound className="h-3 w-3 text-indigo-600" />
                        {b.checkin_code}
                      </span>
                    </td>
                    <td className="px-4 py-3.5 font-black text-emerald-700">
                      ₹{b.agreed_wage}
                    </td>
                    <td className="px-4 py-3.5">
                      {getStatusBadge(b.status, b.attendance_status)}
                    </td>
                    <td className="px-4 py-3.5 text-right">
                      <Link
                        href={`/admin/bookings/${b.id}`}
                        className="inline-flex items-center gap-1 rounded-md bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700 hover:bg-indigo-50 hover:text-indigo-900 transition"
                      >
                        <Eye className="h-3 w-3" />
                        <span>Inspect</span>
                      </Link>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </AdminShell>
  );
}

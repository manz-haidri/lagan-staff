import { connection } from 'next/server';
import { supabase, isSupabaseConfigured } from './supabase';

export interface DashboardMetrics {
  users: {
    total_workers: number;
    active_workers: number;
    suspended_workers: number;
    unreviewed_workers: number;
    total_owners: number;
    total_businesses: number;
    verified_businesses: number;
    pending_business_verifications: number;
  };
  jobs: {
    total_jobs: number;
    draft_jobs: number;
    pending_approval_jobs: number;
    published_jobs: number;
    completed_jobs: number;
    cancelled_jobs: number;
    expired_jobs: number;
  };
  bookings: {
    total_bookings: number;
    confirmed_bookings: number;
    checked_in_bookings: number;
    completed_bookings: number;
    cancelled_bookings: number;
  };
  attendance: {
    total_records: number;
    present: number;
    absent: number;
    no_show: number;
  };
  complaints: {
    total_complaints: number;
    open: number;
    under_review: number;
    resolved: number;
    dismissed: number;
  };
}

export const fallbackDashboardMetrics: DashboardMetrics = {
  users: {
    total_workers: 24,
    active_workers: 23,
    suspended_workers: 1,
    unreviewed_workers: 4,
    total_owners: 12,
    total_businesses: 8,
    verified_businesses: 5,
    pending_business_verifications: 2,
  },
  jobs: {
    total_jobs: 18,
    draft_jobs: 2,
    pending_approval_jobs: 3,
    published_jobs: 9,
    completed_jobs: 2,
    cancelled_jobs: 2,
    expired_jobs: 1,
  },
  bookings: {
    total_bookings: 14,
    confirmed_bookings: 8,
    checked_in_bookings: 2,
    completed_bookings: 3,
    cancelled_bookings: 1,
  },
  attendance: {
    total_records: 12,
    present: 9,
    absent: 2,
    no_show: 1,
  },
  complaints: {
    total_complaints: 4,
    open: 2,
    under_review: 1,
    resolved: 1,
    dismissed: 0,
  },
};

export async function fetchDashboardMetrics(): Promise<DashboardMetrics> {
  if (!isSupabaseConfigured) {
    return fallbackDashboardMetrics;
  }

  await connection();
  try {
    const { data, error } = await supabase.rpc('get_admin_dashboard_metrics');
    if (error) throw error;
    if (data) {
      return data as DashboardMetrics;
    }
  } catch (err) {
    console.error('[DashboardService] Error fetching metrics RPC:', err);
  }

  return fallbackDashboardMetrics;
}

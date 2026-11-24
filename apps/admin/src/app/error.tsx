'use client';

import React from 'react';
import { AlertTriangle } from 'lucide-react';

export default function ErrorBoundary({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="flex min-h-[60vh] items-center justify-center p-4">
      <div className="w-full max-w-md rounded-xl border border-red-200 bg-red-50/50 p-6 text-center">
        <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-red-100 text-red-600">
          <AlertTriangle className="h-6 w-6" />
        </div>
        <h2 className="mt-4 text-base font-bold text-slate-900">An Error Occurred</h2>
        <p className="mt-1 text-xs text-slate-600">{error.message || 'Failed to load console data'}</p>
        <button
          type="button"
          onClick={() => reset()}
          className="mt-5 rounded-lg bg-indigo-900 px-4 py-2 text-xs font-semibold text-white hover:bg-indigo-800 transition-colors"
        >
          Try Again
        </button>
      </div>
    </div>
  );
}

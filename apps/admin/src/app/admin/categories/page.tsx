'use client';

import React, { useEffect, useState } from 'react';
import { AdminShell } from '@/components/layout/AdminShell';
import {
  fetchAdminCategories,
  upsertCategory,
  toggleCategoryStatus,
  AdminCategoryRecord,
} from '@/lib/category-service';
import {
  Plus,
  Layers,
  Edit2,
  CheckCircle2,
  XCircle,
} from 'lucide-react';

export default function AdminCategoriesPage() {
  const [categories, setCategories] = useState<AdminCategoryRecord[]>([]);
  const [loading, setLoading] = useState(true);

  // Modal State
  const [showModal, setShowModal] = useState(false);
  const [editingCategory, setEditingCategory] = useState<AdminCategoryRecord | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    slug: '',
    description: '',
    displayOrder: 1,
  });
  const [actionLoading, setActionLoading] = useState(false);
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const loadData = async () => {
    setLoading(true);
    const data = await fetchAdminCategories();
    setCategories(data);
    setLoading(false);
  };

  useEffect(() => {
    let isMounted = true;
    fetchAdminCategories().then((data) => {
      if (isMounted) {
        setCategories(data);
        setLoading(false);
      }
    });
    return () => {
      isMounted = false;
    };
  }, []);

  const openAddModal = () => {
    setEditingCategory(null);
    setFormData({
      name: '',
      slug: '',
      description: '',
      displayOrder: categories.length + 1,
    });
    setShowModal(true);
  };

  const openEditModal = (cat: AdminCategoryRecord) => {
    setEditingCategory(cat);
    setFormData({
      name: cat.name,
      slug: cat.slug,
      description: cat.description || '',
      displayOrder: cat.display_order,
    });
    setShowModal(true);
  };

  const handleToggle = async (cat: AdminCategoryRecord) => {
    const newStatus = !cat.is_active;
    const res = await toggleCategoryStatus(cat.id, newStatus);
    if (res.success) {
      setCategories((prev) =>
        prev.map((c) => (c.id === cat.id ? { ...c, is_active: newStatus } : c))
      );
    } else {
      setFeedback({ type: 'error', text: res.error || 'Failed to toggle category.' });
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name.trim() || !formData.slug.trim()) return;

    setActionLoading(true);
    setFeedback(null);

    const res = await upsertCategory({
      id: editingCategory?.id,
      name: formData.name.trim(),
      slug: formData.slug.trim().toLowerCase(),
      description: formData.description.trim() || undefined,
      displayOrder: Number(formData.displayOrder),
    });

    if (res.success) {
      setFeedback({
        type: 'success',
        text: editingCategory ? 'Category updated successfully!' : 'Category created successfully!',
      });
      setShowModal(false);
      await loadData();
    } else {
      setFeedback({ type: 'error', text: res.error || 'Failed to save category.' });
    }
    setActionLoading(false);
  };

  return (
    <AdminShell>
      {/* Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Worker Categories & Skills
            </h1>
            <span className="rounded-full bg-slate-200 px-2.5 py-0.5 text-xs font-bold text-slate-700">
              {categories.length} Categories
            </span>
          </div>
          <p className="text-xs text-slate-500 font-medium">
            Manage worker classifications and taxonomy for wedding halls and caterers.
          </p>
        </div>

        <button
          onClick={openAddModal}
          className="inline-flex items-center gap-1.5 rounded-lg bg-indigo-900 px-3.5 py-1.5 text-xs font-semibold text-white shadow-xs hover:bg-indigo-800"
        >
          <Plus className="h-3.5 w-3.5" />
          <span>Add New Category</span>
        </button>
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

      {/* Categories Table */}
      <div className="mt-6 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xs">
        <table className="min-w-full divide-y divide-slate-200 text-left text-xs">
          <thead className="bg-slate-50 text-slate-600 font-semibold uppercase tracking-wider text-[11px]">
            <tr>
              <th className="px-4 py-3 text-center">Order</th>
              <th className="px-4 py-3">Category Title & Description</th>
              <th className="px-4 py-3">Slug Identifier</th>
              <th className="px-4 py-3 text-center">Skills Count</th>
              <th className="px-4 py-3 text-center">Status</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 text-slate-700">
            {loading ? (
              <tr>
                <td colSpan={6} className="px-4 py-12 text-center text-slate-400">
                  Loading categories...
                </td>
              </tr>
            ) : categories.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-4 py-12 text-center text-slate-400">
                  No categories configured.
                </td>
              </tr>
            ) : (
              categories.map((cat) => (
                <tr key={cat.id} className="hover:bg-slate-50/80 transition">
                  <td className="px-4 py-3.5 text-center font-bold text-slate-500">
                    #{cat.display_order}
                  </td>
                  <td className="px-4 py-3.5">
                    <div className="font-bold text-slate-900">{cat.name}</div>
                    {cat.description && (
                      <p className="text-[11px] text-slate-500 mt-0.5 line-clamp-1">
                        {cat.description}
                      </p>
                    )}
                  </td>
                  <td className="px-4 py-3.5 font-mono text-[11px] text-slate-600">
                    {cat.slug}
                  </td>
                  <td className="px-4 py-3.5 text-center">
                    <span className="inline-flex items-center gap-1 rounded bg-slate-100 px-2 py-0.5 text-xs font-semibold text-slate-700">
                      <Layers className="h-3 w-3 text-slate-400" />
                      {cat.skills_count}
                    </span>
                  </td>
                  <td className="px-4 py-3.5 text-center">
                    <button
                      onClick={() => handleToggle(cat)}
                      className="inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-semibold transition"
                    >
                      {cat.is_active ? (
                        <span className="inline-flex items-center gap-1 text-emerald-700 bg-emerald-50 border border-emerald-200 px-2 py-0.5 rounded-full">
                          <CheckCircle2 className="h-3 w-3" /> Active
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-slate-500 bg-slate-100 border border-slate-200 px-2 py-0.5 rounded-full">
                          <XCircle className="h-3 w-3" /> Inactive
                        </span>
                      )}
                    </button>
                  </td>
                  <td className="px-4 py-3.5 text-right">
                    <button
                      onClick={() => openEditModal(cat)}
                      className="inline-flex items-center gap-1 rounded-md bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700 hover:bg-indigo-50 hover:text-indigo-900 transition"
                    >
                      <Edit2 className="h-3 w-3" />
                      <span>Edit</span>
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Add / Edit Category Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl border border-slate-200">
            <h3 className="text-base font-bold text-slate-900">
              {editingCategory ? 'Edit Category' : 'Create New Category'}
            </h3>
            <p className="text-xs text-slate-500 mt-1">
              Classify temporary roles for event workers across Ghazipur.
            </p>

            <form onSubmit={handleSave} className="mt-4 space-y-3">
              <div>
                <label className="text-xs font-semibold text-slate-700">Category Name (Hindi / English) *</label>
                <input
                  type="text"
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="e.g. वेटर (Waiters)"
                  className="mt-1 w-full rounded-lg border border-slate-300 p-2 text-xs focus:border-indigo-600 focus:outline-none"
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-slate-700">Slug (Unique identifier) *</label>
                <input
                  type="text"
                  required
                  value={formData.slug}
                  onChange={(e) => setFormData({ ...formData, slug: e.target.value })}
                  placeholder="e.g. waiters"
                  className="mt-1 w-full rounded-lg border border-slate-300 p-2 text-xs font-mono focus:border-indigo-600 focus:outline-none"
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-slate-700">Display Order</label>
                <input
                  type="number"
                  value={formData.displayOrder}
                  onChange={(e) => setFormData({ ...formData, displayOrder: Number(e.target.value) })}
                  className="mt-1 w-full rounded-lg border border-slate-300 p-2 text-xs focus:border-indigo-600 focus:outline-none"
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-slate-700">Description</label>
                <textarea
                  rows={2}
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  placeholder="Brief role description..."
                  className="mt-1 w-full rounded-lg border border-slate-300 p-2 text-xs focus:border-indigo-600 focus:outline-none"
                />
              </div>

              <div className="mt-6 flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  disabled={actionLoading}
                  className="rounded-lg border border-slate-300 px-3.5 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={actionLoading}
                  className="rounded-lg bg-indigo-900 px-3.5 py-1.5 text-xs font-semibold text-white hover:bg-indigo-800 disabled:opacity-50"
                >
                  {editingCategory ? 'Save Changes' : 'Create Category'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AdminShell>
  );
}

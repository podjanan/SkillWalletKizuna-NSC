'use client';

import { useEffect, useState, useRef } from 'react';
import Link from 'next/link';
import { Plus, Search, MoreVertical, Edit, Trash2, Globe, Lock } from 'lucide-react';
import UserProfile from '@/components/UserProfile';
import Pagination from '@/components/admin/Pagination';
import ConfirmModal from '@/components/admin/ConfirmModal';

interface Activity {
  activityId: string;
  nameActivity: string;
  category: string;
  descriptionActivity: string;
  createdAt: string;
  responses: number;
  isPublic: boolean;
}

// สีของ badge แต่ละ category
const CATEGORY_CONFIG: Record<string, { bg: string; text: string; label: string }> = {
  'ด้านภาษา':   { bg: 'bg-yellow--light3', text: 'text-dark',          label: 'Language' },
  'ด้านร่างกาย': { bg: 'bg-green--light6',  text: 'text-green--dark',   label: 'Physical' },
  'ด้านคำนวณ':  { bg: 'bg-purple--light4', text: 'text-purple--dark',  label: 'Calculate' },
};

export default function ActivitiesPage() {
  const [activities, setActivities]   = useState<Activity[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [loading, setLoading]         = useState(true);
  const [page, setPage]               = useState(1);
  const [totalPages, setTotalPages]   = useState(1);
  const [total, setTotal]             = useState(0);
  const [openMenuId, setOpenMenuId]   = useState<string | null>(null);
  const [menuPos, setMenuPos]         = useState<{ top: number; right: number } | null>(null);

  // สำหรับ confirmation modal
  const [deleteTargetId, setDeleteTargetId]     = useState<string | null>(null);
  const [bulkDeletePending, setBulkDeletePending] = useState(false);
  const [isDeleting, setIsDeleting]             = useState(false);

  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchActivities();
  }, [page, searchQuery, categoryFilter]);

  // ปิด dropdown เมื่อคลิกข้างนอก
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setOpenMenuId(null);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const fetchActivities = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams({
        page: page.toString(),
        limit: '10',
        ...(searchQuery && { search: searchQuery }),
        ...(categoryFilter && { category: categoryFilter }),
      });

      const res = await fetch(`/api/activities?${params}`);
      const result = await res.json();

      if (result.success) {
        setActivities(result.data);
        setTotal(result.pagination.total);
        setTotalPages(result.pagination.totalPages);
      } else {
        console.error('API error:', result.error);
        setActivities([]);
      }
    } catch (error) {
      console.error('Failed to fetch activities:', error);
      setActivities([]);
    } finally {
      setLoading(false);
    }
  };

  // Select / Deselect
  const handleSelectAll = (checked: boolean) => {
    setSelectedIds(checked ? activities.map(a => a.activityId) : []);
  };

  const handleSelectOne = (id: string, checked: boolean) => {
    setSelectedIds(prev =>
      checked ? [...prev, id] : prev.filter(i => i !== id)
    );
  };

  // ลบรายการเดียว — เรียกจาก modal
  const executeDelete = async () => {
    if (!deleteTargetId) return;
    setIsDeleting(true);
    try {
      const res = await fetch(`/api/activities/${deleteTargetId}`, { method: 'DELETE' });
      if (res.ok) {
        setOpenMenuId(null);
        await fetchActivities();
      }
    } catch (error) {
      console.error('Failed to delete activity:', error);
    } finally {
      setIsDeleting(false);
      setDeleteTargetId(null);
    }
  };

  // ลบหลายรายการพร้อมกัน — เรียกจาก modal
  const executeBulkDelete = async () => {
    setIsDeleting(true);
    try {
      await Promise.all(
        selectedIds.map(id => fetch(`/api/activities/${id}`, { method: 'DELETE' }))
      );
      setSelectedIds([]);
      await fetchActivities();
    } catch (error) {
      console.error('Failed to bulk delete activities:', error);
    } finally {
      setIsDeleting(false);
      setBulkDeletePending(false);
    }
  };

  // Toggle public/private (reversible → ไม่ต้องยืนยัน)
  const handleTogglePublic = async (id: string, currentValue: boolean) => {
    try {
      const res = await fetch(`/api/activities/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isPublic: !currentValue }),
      });
      if (res.ok) {
        setActivities(prev =>
          prev.map(a => a.activityId === id ? { ...a, isPublic: !currentValue } : a)
        );
      }
    } catch (error) {
      console.error('Failed to toggle public:', error);
    }
  };

  const handleSearch = (value: string) => {
    setSearchQuery(value);
    setPage(1);
  };

  const getCategoryBadge = (category: string) => {
    const c = CATEGORY_CONFIG[category] ?? { bg: 'bg-gray3', text: 'text-secondary--text', label: category };
    return (
      <span className={`inline-flex items-center px-2 py-1 rounded-full body-xs-medium whitespace-nowrap ${c.bg} ${c.text}`}>
        {c.label}
      </span>
    );
  };

  if (loading && activities.length === 0) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="body-large-medium text-secondary--text">Loading...</div>
      </div>
    );
  }

  return (
    <div className="p-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <div className="body-small-regular text-secondary--text mb-1">
            Activities &gt; Activity List
          </div>
          <h1 className="heading-h3">ACTIVITIES</h1>
        </div>
        <div className="flex items-center gap-4">
          <UserProfile />
          <Link href="/admin/activities/new">
            <button className="btn-primary px-4 py-2 rounded-lg flex items-center gap-2">
              <Plus size={20} />
              Create
            </button>
          </Link>
        </div>
      </div>

      {/* Search & Filters */}
      <div className="mb-6 flex flex-wrap gap-4">
        <div className="relative flex-1 min-w-[250px] max-w-md">
          <Search
            className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary--text"
            size={20}
          />
          <input
            type="text"
            placeholder="Search activities..."
            value={searchQuery}
            onChange={e => handleSearch(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
          />
        </div>

        <select
          value={categoryFilter}
          onChange={e => { setCategoryFilter(e.target.value); setPage(1); }}
          className="px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
        >
          <option value="">All Categories</option>
          <option value="ด้านภาษา">Language</option>
          <option value="ด้านร่างกาย">Physical</option>
          <option value="ด้านคำนวณ">Calculate</option>
        </select>
      </div>

      {/* Bulk Actions */}
      {selectedIds.length > 0 && (
        <div className="mb-4 flex items-center gap-4 bg-purple--light5 px-4 py-2 rounded-lg">
          <span className="body-medium-medium">{selectedIds.length} selected</span>
          <button
            onClick={() => setBulkDeletePending(true)}
            className="text-red hover:text-red--dark"
          >
            <Trash2 size={20} />
          </button>
        </div>
      )}

      {/* Table */}
      <div className="bg-white rounded-lg shadow overflow-x-auto">
        <table className="w-full min-w-[800px]">
          <thead className="bg-gray--light1 border-b border-gray4">
            <tr>
              <th className="w-10 px-3 py-3">
                <input
                  type="checkbox"
                  checked={selectedIds.length === activities.length && activities.length > 0}
                  onChange={e => handleSelectAll(e.target.checked)}
                  className="rounded"
                />
              </th>
              <th className="w-12 px-3 py-3 text-left body-small-medium text-secondary--text">No.</th>
              <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Activity Title</th>
              <th className="w-28 px-4 py-3 text-left body-small-medium text-secondary--text">Category</th>
              <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Description</th>
              <th className="w-28 px-4 py-3 text-left body-small-medium text-secondary--text whitespace-nowrap">Date Created</th>
              <th className="w-24 px-4 py-3 text-center body-small-medium text-secondary--text">Responses</th>
              <th className="w-24 px-4 py-3 text-center body-small-medium text-secondary--text">Public</th>
              <th className="w-12 px-3 py-3"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray4">
            {activities.length === 0 ? (
              <tr>
                <td colSpan={9} className="px-4 py-8 text-center body-medium-regular text-secondary--text">
                  No activities found
                </td>
              </tr>
            ) : (
              activities.map((activity, index) => (
                <tr
                  key={activity.activityId}
                  className={`hover:bg-gray--light1 ${
                    selectedIds.includes(activity.activityId) ? 'bg-purple--light5' : ''
                  }`}
                >
                  <td className="px-4 py-3">
                    <input
                      type="checkbox"
                      checked={selectedIds.includes(activity.activityId)}
                      onChange={e => handleSelectOne(activity.activityId, e.target.checked)}
                      className="rounded"
                    />
                  </td>
                  <td className="px-4 py-3 body-medium-regular">{(page - 1) * 10 + index + 1}</td>
                  <td className="px-4 py-3 body-medium-medium">{activity.nameActivity}</td>
                  <td className="px-4 py-3">{getCategoryBadge(activity.category)}</td>
                  <td className="px-4 py-3 body-medium-regular text-secondary--text max-w-[200px] truncate">
                    {activity.descriptionActivity || '-'}
                  </td>
                  <td className="px-4 py-3 body-medium-regular whitespace-nowrap">
                    {new Date(activity.createdAt).toLocaleDateString('en-US', {
                      day: 'numeric', month: 'short', year: 'numeric',
                    })}
                  </td>
                  <td className="px-4 py-3 body-medium-regular text-center">
                    {activity.responses || '-'}
                  </td>
                  <td className="px-4 py-3 text-center">
                    <button
                      onClick={() => handleTogglePublic(activity.activityId, activity.isPublic)}
                      className={`inline-flex items-center gap-1 px-2 py-1 rounded-full body-xs-medium transition-colors ${
                        activity.isPublic
                          ? 'bg-green--light6 text-green--dark hover:opacity-80'
                          : 'bg-gray3 text-secondary--text hover:bg-gray4'
                      }`}
                    >
                      {activity.isPublic ? <Globe size={14} /> : <Lock size={14} />}
                      {activity.isPublic ? 'Public' : 'Private'}
                    </button>
                  </td>
                  <td className="px-4 py-3">
                    <div className="relative">
                      <button
                        onClick={(e) => {
                          if (openMenuId === activity.activityId) {
                            setOpenMenuId(null);
                            setMenuPos(null);
                          } else {
                            const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
                            setMenuPos({ top: rect.bottom + window.scrollY + 4, right: window.innerWidth - rect.right });
                            setOpenMenuId(activity.activityId);
                          }
                        }}
                        className="p-1 hover:bg-gray--light1 rounded"
                      >
                        <MoreVertical size={16} className="text-secondary--text" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>

        <Pagination
          currentPage={page}
          totalPages={totalPages}
          total={total}
          pageSize={10}
          itemCount={activities.length}
          onPageChange={setPage}
        />
      </div>

      {/* Modal: ยืนยันลบรายการเดียว */}
      <ConfirmModal
        isOpen={deleteTargetId !== null}
        title="Delete Activity"
        message="This action cannot be undone. The activity and all related records will be permanently deleted."
        confirmLabel="Delete"
        isLoading={isDeleting}
        onConfirm={executeDelete}
        onCancel={() => setDeleteTargetId(null)}
      />

      {/* Modal: ยืนยันลบหลายรายการ */}
      <ConfirmModal
        isOpen={bulkDeletePending}
        title={`Delete ${selectedIds.length} Activities`}
        message="This action cannot be undone. All selected activities will be permanently deleted."
        confirmLabel="Delete All"
        isLoading={isDeleting}
        onConfirm={executeBulkDelete}
        onCancel={() => setBulkDeletePending(false)}
      />

      {/* Floating dropdown menu (fixed position — ไม่กระทบ layout) */}
      {openMenuId && menuPos && (() => {
        const activity = activities.find(a => a.activityId === openMenuId);
        if (!activity) return null;
        return (
          <div
            ref={menuRef}
            style={{ position: 'fixed', top: menuPos.top, right: menuPos.right }}
            className="bg-white border border-gray4 rounded-lg shadow-lg py-2 z-[9999]"
          >
            <Link
              href={`/admin/activities/${activity.activityId}`}
              className="flex items-center gap-2 px-4 py-2 hover:bg-gray--light1 body-small-medium whitespace-nowrap"
              onClick={() => { setOpenMenuId(null); setMenuPos(null); }}
            >
              <Edit size={16} />
              Edit
            </Link>
            <button
              onClick={() => { setOpenMenuId(null); setMenuPos(null); setDeleteTargetId(activity.activityId); }}
              className="flex items-center gap-2 px-4 py-2 hover:bg-red--light6 body-small-medium text-red--dark w-full text-left whitespace-nowrap"
            >
              <Trash2 size={16} />
              Delete
            </button>
          </div>
        );
      })()}
    </div>
  );
}

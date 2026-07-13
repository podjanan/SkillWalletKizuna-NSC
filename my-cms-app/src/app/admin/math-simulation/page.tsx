// src/app/admin/math-simulation/page.tsx
'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Plus, Search, MoreVertical, Edit, Trash2, Sparkles, Brain, Award } from 'lucide-react';
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
  difficulty?: string;
  maxScore?: number;
  segments?: any;
}

export default function MathSimulationDashboard() {
  const [activities, setActivities] = useState<Activity[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);
  const [openMenuId, setOpenMenuId] = useState<string | null>(null);

  const [deleteTargetId, setDeleteTargetId] = useState<string | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    fetchSimulationActivities();
  }, [page, searchQuery]);

  const fetchSimulationActivities = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams({
        page: page.toString(),
        limit: '10',
        content: 'math_simulation',
        ...(searchQuery && { search: searchQuery }),
      });

      const res = await fetch(`/api/activities?${params}`);
      const result = await res.json();

      if (result.success) {
        setActivities(result.data);
        setTotal(result.pagination.total);
        setTotalPages(result.pagination.totalPages);
      } else {
        setActivities([]);
      }
    } catch (error) {
      console.error('Failed to fetch math simulation activities:', error);
      setActivities([]);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    try {
      setIsDeleting(true);
      const res = await fetch(`/api/activities/${id}`, {
        method: 'DELETE',
      });
      if (res.ok) {
        setDeleteTargetId(null);
        fetchSimulationActivities();
      } else {
        alert('Failed to delete activity');
      }
    } catch (error) {
      console.error('Delete error:', error);
      alert('An error occurred while deleting the activity');
    } finally {
      setIsDeleting(false);
    }
  };

  return (
    <div className="flex-1 bg-gray--light1 p-8 overflow-y-auto">
      {/* Top Header */}
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="heading-h3 text-dark flex items-center gap-2">
            <Brain className="text-purple" size={32} />
            Math Simulation
          </h1>
          <p className="body-medium-regular text-secondary--text mt-1">
            คลังและแบบจัดการคณิตศาสตร์สถานการณ์จำลอง (มีภาพประกอบการ์ตูน AI & สแกนคำตอบด้วยกล้อง)
          </p>
        </div>
        <div className="flex items-center gap-4">
          <Link
            href="/admin/math-simulation/new"
            className="flex items-center gap-2 px-4 py-2 bg-purple text-white rounded-lg body-medium-medium hover:bg-purple--dark transition-colors shadow-md"
          >
            <Plus size={20} />
            Create Simulation Activity
          </Link>
          <UserProfile />
        </div>
      </div>

      {/* Stats Summary cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray4 flex items-center gap-4">
          <div className="p-3 bg-purple--light5 text-purple rounded-xl">
            <Brain size={24} />
          </div>
          <div>
            <h4 className="body-small-semibold text-secondary--text">Total Templates</h4>
            <p className="heading-h4 text-dark font-bold mt-1">{total}</p>
          </div>
        </div>
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray4 flex items-center gap-4">
          <div className="p-3 bg-green--light6 text-green--dark rounded-xl">
            <Award size={24} />
          </div>
          <div>
            <h4 className="body-small-semibold text-secondary--text">Total Plays</h4>
            <p className="heading-h4 text-dark font-bold mt-1">
              {activities.reduce((sum, a) => sum + (a.responses || 0), 0)}
            </p>
          </div>
        </div>
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray4 flex items-center gap-4">
          <div className="p-3 bg-yellow--light3 text-dark rounded-xl">
            <Sparkles size={24} />
          </div>
          <div>
            <h4 className="body-small-semibold text-secondary--text">AI Generation Mode</h4>
            <p className="heading-h5 text-dark font-semibold mt-1">Exact Local Images · ComfyUI Ready</p>
          </div>
        </div>
      </div>

      {/* Main Filter Table card */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray4 overflow-hidden">
        {/* Table Search bar */}
        <div className="p-6 border-b border-gray4 flex flex-col md:flex-row gap-4 justify-between items-center">
          <div className="relative w-full md:w-96">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary--text" size={18} />
            <input
              type="text"
              placeholder="Search math simulation activities..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray6 rounded-xl body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple focus:border-transparent"
            />
          </div>
        </div>

        {/* Table View */}
        <div className="overflow-x-auto">
          {loading ? (
            <div className="text-center py-20 text-secondary--text body-medium-regular">
              Loading activities...
            </div>
          ) : activities.length === 0 ? (
            <div className="text-center py-20 text-secondary--text body-medium-regular">
              No math simulation activities found. Create one to get started!
            </div>
          ) : (
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-gray--light1 border-b border-gray4">
                  <th className="px-6 py-4 body-small-medium text-secondary--text">Activity Name</th>
                  <th className="px-6 py-4 body-small-medium text-secondary--text">Difficulty</th>
                  <th className="px-6 py-4 body-small-medium text-secondary--text">Max Score</th>
                  <th className="px-6 py-4 body-small-medium text-secondary--text">Questions Count</th>
                  <th className="px-6 py-4 body-small-medium text-secondary--text">Plays Count</th>
                  <th className="px-6 py-4 body-small-medium text-secondary--text">Created At</th>
                  <th className="px-6 py-4 body-small-medium text-secondary--text text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray4">
                {activities.map((activity) => {
                  const segmentsCount = Array.isArray(activity.segments)
                    ? activity.segments.length
                    : 0;

                  return (
                    <tr key={activity.activityId} className="hover:bg-gray--light2 transition-colors">
                      <td className="px-6 py-4">
                        <div className="body-medium-semibold text-dark">{activity.nameActivity}</div>
                        <div className="body-xs-regular text-secondary--text truncate max-w-xs mt-1">
                          {activity.descriptionActivity}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span className="inline-flex px-2.5 py-1 rounded-full body-xs-semibold bg-purple--light5 text-purple">
                          {activity.difficulty || 'ง่าย'}
                        </span>
                      </td>
                      <td className="px-6 py-4 body-medium-semibold text-dark">
                        {activity.maxScore || 100} pts
                      </td>
                      <td className="px-6 py-4 body-medium-regular text-secondary--text">
                        {segmentsCount} ข้อ
                      </td>
                      <td className="px-6 py-4 body-medium-semibold text-green--dark">
                        {activity.responses || 0} ครั้ง
                      </td>
                      <td className="px-6 py-4 body-medium-regular text-secondary--text">
                        {new Date(activity.createdAt).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4 text-right relative">
                        <button
                          onClick={() => setOpenMenuId(openMenuId === activity.activityId ? null : activity.activityId)}
                          className="p-1 hover:bg-gray4 rounded-lg text-secondary--text"
                        >
                          <MoreVertical size={20} />
                        </button>
                        
                        {openMenuId === activity.activityId && (
                          <div className="absolute right-6 top-12 bg-white rounded-xl shadow-lg border border-gray4 py-2 w-32 z-10">
                            <Link
                              href={`/admin/math-simulation/${activity.activityId}`}
                              className="flex items-center gap-2 px-4 py-2 body-small-medium text-dark hover:bg-gray--light1"
                            >
                              <Edit size={16} />
                              Edit
                            </Link>
                            <button
                              onClick={() => {
                                setDeleteTargetId(activity.activityId);
                                setOpenMenuId(null);
                              }}
                              className="w-full flex items-center gap-2 px-4 py-2 body-small-medium text-red hover:bg-red--light1 text-left"
                            >
                              <Trash2 size={16} />
                              Delete
                            </button>
                          </div>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="p-6 border-t border-gray4 flex justify-between items-center">
            <span className="body-small-regular text-secondary--text">
              Showing page {page} of {totalPages} ({total} entries)
            </span>
            <Pagination
              currentPage={page}
              totalPages={totalPages}
              total={total}
              pageSize={10}
              itemCount={activities.length}
              onPageChange={setPage}
            />
          </div>
        )}
      </div>

      {/* Delete Confirmation Modal */}
      {deleteTargetId && (
        <ConfirmModal
          isOpen={deleteTargetId !== null}
          title="Delete Activity"
          message="Are you sure you want to delete this math simulation activity template? This action cannot be undone."
          confirmLabel="Delete"
          isLoading={isDeleting}
          onConfirm={() => handleDelete(deleteTargetId)}
          onCancel={() => setDeleteTargetId(null)}
        />
      )}
    </div>
  );
}

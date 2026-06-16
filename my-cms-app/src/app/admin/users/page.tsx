'use client';

import { useEffect, useState, useRef } from 'react';
import Link from 'next/link';
import { Search, MoreVertical, Eye, ShieldCheck, Shield, Trash2 } from 'lucide-react';
import UserProfile from '@/components/UserProfile';
import Pagination from '@/components/admin/Pagination';
import ConfirmModal from '@/components/admin/ConfirmModal';
import { authClient } from '@/lib/auth-client';

interface User {
  id: string;
  fullName: string;
  email: string;
  role: string;
  providers: string[];
  // status: string;       // TODO: not yet implemented — hardcoded mock
  // verification: string; // TODO: not yet implemented — hardcoded mock
  photoUrl?: string;
  createdAt: string;
  childrenCount: number;
  activityRecordCount: number;
}

export default function UsersPage() {
  const [users, setUsers]             = useState<User[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading]         = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages]   = useState(1);
  const [total, setTotal]             = useState(0);
  const [openMenuId, setOpenMenuId]   = useState<string | null>(null);
  const [menuPos, setMenuPos]         = useState<{ top: number; right: number } | null>(null);
  const [deleteTargetId, setDeleteTargetId] = useState<string | null>(null);
  const [isDeleting, setIsDeleting]   = useState(false);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);

  useEffect(() => {
    authClient.getSession().then(({ data }) => {
      if (data?.user?.id) setCurrentUserId(data.user.id);
    });
  }, []);

  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchUsers();
  }, [searchQuery, currentPage]);

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

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({
        page: currentPage.toString(),
        limit: '10',
        ...(searchQuery && { search: searchQuery }),
      });

      const res = await fetch(`/api/users?${params}`);
      const data = await res.json();

      setUsers(data.users || []);
      setTotal(data.pagination?.total || 0);
      setTotalPages(data.pagination?.totalPages || 1);
    } catch (error) {
      console.error('Failed to fetch users:', error);
      setUsers([]);
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteUser = async () => {
    if (!deleteTargetId) return;
    setIsDeleting(true);
    try {
      const res = await fetch(`/api/users/${deleteTargetId}`, { method: 'DELETE' });
      if (!res.ok) throw new Error('Delete failed');
      setDeleteTargetId(null);
      await fetchUsers();
    } catch (error) {
      console.error('Failed to delete user:', error);
    } finally {
      setIsDeleting(false);
    }
  };

  // --- Badge helpers ---

  // TODO: Status/Verification badges — not yet implemented (hardcoded mock data)
  // const getStatusBadge = (status: string) => {
  //   const isActive = status === 'Active';
  //   return (
  //     <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full body-xs-medium ${
  //       isActive ? 'bg-green--light6 text-green--dark' : 'bg-red--light6 text-red--dark'
  //     }`}>
  //       {isActive ? <UserCheck size={12} /> : <UserX size={12} />}
  //       {status}
  //     </span>
  //   );
  // };

  const getProviderIcons = (providers: string[]) => {
    if (providers.length === 0) return <span className="body-xs-medium text-secondary--text">—</span>;
    return (
      <div className="flex items-center justify-center gap-1">
        {providers.map((p) => {
          if (p === 'google') return (
            <span key={p} title="Google" className="w-6 h-6 flex items-center justify-center rounded-full bg-white border border-gray4">
              <svg viewBox="0 0 24 24" width="14" height="14">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
            </span>
          );
          if (p === 'facebook') return (
            <span key={p} title="Facebook" className="w-6 h-6 flex items-center justify-center rounded-full bg-[#1877F2]">
              <svg viewBox="0 0 24 24" width="14" height="14" fill="white">
                <path d="M24 12.073C24 5.405 18.627 0 12 0S0 5.405 0 12.073C0 18.1 4.388 23.094 10.125 24v-8.437H7.078v-3.49h3.047V9.41c0-3.025 1.792-4.697 4.533-4.697 1.312 0 2.686.236 2.686.236v2.97h-1.513c-1.491 0-1.956.93-1.956 1.886v2.268h3.328l-.532 3.49h-2.796V24C19.612 23.094 24 18.1 24 12.073z"/>
              </svg>
            </span>
          );
          // credential = email/password
          return (
            <span key={p} title="Email" className="w-6 h-6 flex items-center justify-center rounded-full bg-gray3">
              <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="#666" strokeWidth="2">
                <rect x="2" y="4" width="20" height="16" rx="2"/>
                <path d="M2 7l10 7 10-7"/>
              </svg>
            </span>
          );
        })}
      </div>
    );
  };

  const getRoleBadge = (role: string) => {
    const isAdmin = role === 'admin';
    return (
      <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full body-xs-medium ${
        isAdmin ? 'bg-purple--light4 text-purple--dark' : 'bg-gray3 text-secondary--text'
      }`}>
        {isAdmin ? <ShieldCheck size={12} /> : <Shield size={12} />}
        {isAdmin ? 'Admin' : 'User'}
      </span>
    );
  };

  // const getVerificationBadge = (verification: string) => {
  //   const isVerified = verification === 'Verified';
  //   return (
  //     <span className={`inline-flex items-center px-2 py-1 rounded-full body-xs-medium ${
  //       isVerified ? 'bg-cyan--light3 text-purple--dark' : 'bg-yellow--light3 text-dark'
  //     }`}>
  //       {verification}
  //     </span>
  //   );
  // };

  if (loading && users.length === 0) {
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
            Users &gt; User List
          </div>
          <h1 className="heading-h3">USERS</h1>
        </div>
        <UserProfile />
      </div>

      {/* Search */}
      <div className="mb-6 flex flex-wrap gap-4">
        <div className="relative flex-1 min-w-[250px] max-w-md">
          <Search
            className="absolute left-3 top-1/2 -translate-y-1/2 text-secondary--text"
            size={20}
          />
          <input
            type="text"
            placeholder="Search by name or email"
            value={searchQuery}
            onChange={e => { setSearchQuery(e.target.value); setCurrentPage(1); }}
            className="w-full pl-10 pr-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
          />
        </div>

        {/*
          TODO: Status และ Verification filters
          - ต้องเพิ่ม field เหล่านี้ใน API /api/users ให้รองรับ query param status, verification
          - ยังไม่ได้ implement ฝั่ง backend จึงซ่อนไว้ก่อน
        */}
      </div>

      {/* Table */}
      <div className="bg-white rounded-lg shadow">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[900px]">
            <thead className="bg-gray--light1 border-b border-gray4">
              <tr>
                <th className="w-12 px-3 py-3 text-left body-small-medium text-secondary--text">No.</th>
                <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Full Name</th>
                <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Email</th>
                <th className="w-20 px-3 py-3 text-center body-small-medium text-secondary--text">Role</th>
                <th className="w-20 px-3 py-3 text-center body-small-medium text-secondary--text">Provider</th>
                {/* <th className="w-20 px-3 py-3 text-center body-small-medium text-secondary--text">Status</th> */}
                {/* <th className="w-24 px-3 py-3 text-center body-small-medium text-secondary--text">Verification</th> */}
                <th className="w-16 px-3 py-3 text-center body-small-medium text-secondary--text">Children</th>
                <th className="w-16 px-3 py-3 text-center body-small-medium text-secondary--text">Activities</th>
                <th className="w-28 px-3 py-3 text-left body-small-medium text-secondary--text whitespace-nowrap">Date Created</th>
                <th className="w-12 px-3 py-3"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray4">
              {users.length === 0 ? (
                <tr>
                  <td colSpan={9} className="px-4 py-8 text-center body-medium-regular text-secondary--text">
                    No users found
                  </td>
                </tr>
              ) : (
                users.map((user, index) => (
                  <tr key={user.id} className="hover:bg-gray--light1">
                    <td className="px-3 py-3 body-medium-regular">
                      {(currentPage - 1) * 10 + index + 1}
                    </td>
                    <td className="px-4 py-3 max-w-[160px]">
                      <div className="flex items-center gap-3 min-w-0">
                        {user.photoUrl ? (
                          <img
                            src={user.photoUrl}
                            alt={user.fullName}
                            className="w-8 h-8 rounded-full object-cover flex-shrink-0"
                          />
                        ) : (
                          <div className="w-8 h-8 rounded-full bg-purple--light4 flex items-center justify-center body-small-medium text-purple flex-shrink-0">
                            {user.fullName.charAt(0).toUpperCase()}
                          </div>
                        )}
                        <span className="body-medium-medium truncate" title={user.fullName}>
                          {user.fullName}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-3 body-medium-regular max-w-[180px]">
                      <span className="truncate block" title={user.email}>{user.email}</span>
                    </td>
                    <td className="px-3 py-3 text-center">{getRoleBadge(user.role)}</td>
                    <td className="px-3 py-3 text-center">{getProviderIcons(user.providers)}</td>
                    {/* <td className="px-3 py-3 text-center">{getStatusBadge(user.status)}</td> */}
                    {/* <td className="px-3 py-3 text-center">{getVerificationBadge(user.verification)}</td> */}
                    <td className="px-3 py-3 body-medium-regular text-center">{user.childrenCount}</td>
                    <td className="px-3 py-3 body-medium-regular text-center">{user.activityRecordCount}</td>
                    <td className="px-3 py-3 body-medium-regular whitespace-nowrap">
                      {new Date(user.createdAt).toLocaleDateString('en-US', {
                        day: 'numeric', month: 'short', year: 'numeric',
                      })}
                    </td>
                    <td className="px-4 py-3">
                      <div className="relative">
                        <button
                          onClick={(e) => {
                            if (openMenuId === user.id) {
                              setOpenMenuId(null);
                              setMenuPos(null);
                            } else {
                              const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
                              setMenuPos({ top: rect.bottom + window.scrollY + 4, right: window.innerWidth - rect.right });
                              setOpenMenuId(user.id);
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
        </div>

        <Pagination
          currentPage={currentPage}
          totalPages={totalPages}
          total={total}
          pageSize={10}
          itemCount={users.length}
          onPageChange={setCurrentPage}
        />
      </div>

      {/* Modal: ยืนยันลบผู้ใช้ */}
      <ConfirmModal
        isOpen={deleteTargetId !== null}
        title="Delete User"
        message="This action cannot be undone. The user account and all associated data will be permanently deleted."
        confirmLabel="Delete"
        isLoading={isDeleting}
        onConfirm={handleDeleteUser}
        onCancel={() => setDeleteTargetId(null)}
      />

      {/* Floating dropdown menu (fixed position — ไม่กระทบ layout) */}
      {openMenuId && menuPos && (() => {
        const user = users.find(u => u.id === openMenuId);
        if (!user) return null;
        return (
          <div
            ref={menuRef}
            style={{ position: 'fixed', top: menuPos.top, right: menuPos.right }}
            className="bg-white border border-gray4 rounded-lg shadow-lg py-2 z-[9999] min-w-[140px]"
          >
            <Link
              href={`/admin/users/${user.id}`}
              className="flex items-center gap-2 px-4 py-2 hover:bg-gray--light1 body-small-medium whitespace-nowrap"
              onClick={() => { setOpenMenuId(null); setMenuPos(null); }}
            >
              <Eye size={16} />
              View Detail
            </Link>
            {user.id !== currentUserId && (
              <button
                className="w-full flex items-center gap-2 px-4 py-2 hover:bg-red--light6 body-small-medium whitespace-nowrap text-red--dark"
                onClick={() => { setOpenMenuId(null); setMenuPos(null); setDeleteTargetId(user.id); }}
              >
                <Trash2 size={16} />
                Delete User
              </button>
            )}
          </div>
        );
      })()}
    </div>
  );
}

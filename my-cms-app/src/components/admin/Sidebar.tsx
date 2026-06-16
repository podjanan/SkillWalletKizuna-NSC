// components/admin/Sidebar.tsx
'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { ChevronDown, FileText, Users } from 'lucide-react';
import { useState } from 'react';

export default function Sidebar() {
  const pathname = usePathname();
  const [activitiesOpen, setActivitiesOpen] = useState(true);

  return (
    <aside className="w-64 bg-white border-r border-gray4 h-screen flex flex-col">
      {/* User Type */}
      <div className="p-4 border-b border-gray4">
        <div className="flex items-center justify-between">
          <span className="body-small-regular text-secondary--text">User Type</span>
          <span className="body-small-semibold text-purple flex items-center gap-1">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
              <path d="M8 4L12 8L8 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
            </svg>
            Admin
          </span>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 py-4">
        {/* Activities Section */}
        <div>
          <button
            onClick={() => setActivitiesOpen(!activitiesOpen)}
            className="w-full flex items-center justify-between px-4 py-2 text-left hover:bg-gray--light1"
          >
            <div className="flex items-center gap-2">
              <FileText size={20} className="text-secondary--text" />
              <span className="body-medium-medium">Activities</span>
            </div>
            <ChevronDown
              size={16}
              className={`text-secondary--text transition-transform ${
                activitiesOpen ? 'rotate-180' : ''
              }`}
            />
          </button>

          {/* Sub-menu */}
          {activitiesOpen && (
            <div className="pl-11 py-1">
              <Link
                href="/admin/activities"
                className={`block px-4 py-2 body-medium-regular rounded-lg ${
                  pathname === '/admin/activities'
                    ? 'text-purple bg-purple--light5'
                    : 'text-primary--text hover:bg-gray--light1'
                }`}
              >
                Activity List
              </Link>
            </div>
          )}
        </div>

        {/* Users */}
        <Link
          href="/admin/users"
          className={`flex items-center gap-2 px-4 py-2 hover:bg-gray--light1 ${
            pathname.startsWith('/admin/users') ? 'bg-gray--light1' : ''
          }`}
        >
          <Users size={20} className="text-secondary--text" />
          <span className="body-medium-medium">Users</span>
        </Link>
      </nav>

      {/* Version */}
      <div className="p-4 border-t border-gray4">
        <span className="body-xs-regular text-secondary--text">Version 1.0.0</span>
      </div>
    </aside>
  );
}
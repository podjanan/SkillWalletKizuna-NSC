// app/admin/users/[id]/page.tsx
'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { ArrowLeft, Mail, Calendar, Users, Activity, Gift, Award, User, Shield, ShieldCheck } from 'lucide-react';

interface Child {
  id: string;
  fullName: string;
  dob?: string;
  score: number;
  scoreUpdate: number;
  relationship: string;
}

interface ActivityRecord {
  id: string;
  activityName: string;
  category: string;
  dateCompleted: string;
  scoreEarned: number;
  status: string;
}

interface Reward {
  rewardId: string;
  name: string;
  cost: number;
}

interface Redemption {
  id: string;
  rewardName: string;
  childName: string;
  dateRedeemed: string;
  scoreUsed: number;
}

interface UserDetail {
  id: string;
  userId?: string;
  fullName: string;
  email: string;
  role: string;
  status: string;
  verification: string;
  photoUrl?: string;
  createdAt: string;
  children: Child[];
  recentActivities: ActivityRecord[];
  rewards: Reward[];
  recentRedemptions: Redemption[];
}

export default function UserDetailPage() {
  const params = useParams();
  const router = useRouter();
  const [user, setUser] = useState<UserDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [updatingRole, setUpdatingRole] = useState(false);

  useEffect(() => {
    if (params.id) {
      fetchUserDetail();
    }
  }, [params.id]);

  const fetchUserDetail = async () => {
    try {
      const res = await fetch(`/api/users/${params.id}`);
      if (res.ok) {
        const data = await res.json();
        setUser(data);
      } else {
        console.error('User not found');
      }
    } catch (error) {
      console.error('Failed to fetch user:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleRoleChange = async (newRole: string) => {
    if (!user || user.role === newRole) return;
    setUpdatingRole(true);
    try {
      const res = await fetch(`/api/users/${params.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ role: newRole }),
      });
      if (res.ok) {
        setUser({ ...user, role: newRole });
      } else {
        const data = await res.json();
        alert(data.error || 'Failed to update role');
      }
    } catch (error) {
      console.error('Failed to update role:', error);
      alert('Failed to update role');
    } finally {
      setUpdatingRole(false);
    }
  };

  const getRoleBadge = (role: string) => {
    const isAdmin = role === 'admin';
    return (
      <span className={`inline-flex items-center gap-1 px-3 py-1 rounded-full body-small-medium ${
        isAdmin
          ? 'bg-purple--light4 text-purple--dark'
          : 'bg-gray3 text-secondary--text'
      }`}>
        {isAdmin ? <ShieldCheck size={14} /> : <Shield size={14} />}
        {isAdmin ? 'Admin' : 'User'}
      </span>
    );
  };

  const getStatusBadge = (status: string) => {
    const isActive = status === 'Active';
    return (
      <span className={`inline-flex items-center gap-1 px-3 py-1 rounded-full body-small-medium ${
        isActive 
          ? 'bg-green--light6 text-green--dark' 
          : 'bg-red--light6 text-red--dark'
      }`}>
        {status}
      </span>
    );
  };

  const getVerificationBadge = (verification: string) => {
    const isVerified = verification === 'Verified';
    return (
      <span className={`inline-flex items-center px-3 py-1 rounded-full body-small-medium ${
        isVerified 
          ? 'bg-cyan--light3 text-purple--dark' 
          : 'bg-yellow--light3 text-dark'
      }`}>
        {verification}
      </span>
    );
  };

  const getCategoryBadge = (category: string) => {
    const config: Record<string, { bg: string; text: string; label: string }> = {
      'ด้านภาษา': { bg: 'bg-yellow--light3', text: 'text-dark', label: 'Language' },
      'ด้านร่างกาย': { bg: 'bg-green--light6', text: 'text-green--dark', label: 'Physical' },
      'ด้านคำนวณ': { bg: 'bg-purple--light4', text: 'text-purple--dark', label: 'Calculate' },
    };
    const c = config[category] || { bg: 'bg-gray3', text: 'text-secondary--text', label: category };
    return (
      <span className={`inline-flex items-center px-2 py-1 rounded-full body-xs-medium whitespace-nowrap ${c.bg} ${c.text}`}>
        {c.label}
      </span>
    );
  };

  const getActivityStatusBadge = (status: string) => {
    const statusColors: { [key: string]: string } = {
      'Completed': 'bg-green--light6 text-green--dark',
      'Pending': 'bg-yellow--light3 text-dark',
      'Failed': 'bg-red--light6 text-red--dark'
    };
    return (
      <span className={`inline-flex items-center px-2 py-1 rounded-full body-xs-medium ${statusColors[status] || 'bg-gray3 text-secondary--text'}`}>
        {status}
      </span>
    );
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="body-large-medium text-secondary--text">Loading...</div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="p-8">
        <div className="bg-white rounded-lg shadow p-12 text-center">
          <div className="body-large-medium text-secondary--text mb-2">
            User not found
          </div>
          <button 
            onClick={() => router.push('/admin/users')}
            className="btn-primary px-4 py-2 rounded-lg mt-4"
          >
            Back to Users
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="p-8">
      {/* Header */}
      <div className="mb-6">
        <button 
          onClick={() => router.push('/admin/users')}
          className="flex items-center gap-2 body-medium-medium text-purple hover:text-purple--dark mb-4"
        >
          <ArrowLeft size={20} />
          Back to Users
        </button>
        <div className="body-small-regular text-secondary--text mb-1">
          Users &gt; User Detail
        </div>
        <h1 className="heading-h3">USER DETAIL</h1>
      </div>

      {/* User Info Card */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <div className="flex items-start gap-6">
          {user.photoUrl ? (
            <img 
              src={user.photoUrl} 
              alt={user.fullName}
              className="w-24 h-24 rounded-full object-cover"
            />
          ) : (
            <div className="w-24 h-24 rounded-full bg-purple--light4 flex items-center justify-center heading-h3 text-purple">
              {user.fullName.charAt(0).toUpperCase()}
            </div>
          )}
          
          <div className="flex-1">
            <div className="flex items-start justify-between mb-4">
              <div>
                <h2 className="heading-h4 mb-2">{user.fullName}</h2>
                <div className="flex items-center gap-4 mb-3">
                  {getRoleBadge(user.role)}
                  {getStatusBadge(user.status)}
                  {getVerificationBadge(user.verification)}
                </div>
              </div>

              {/* Role Management */}
              <div className="flex items-center gap-2">
                <select
                  value={user.role}
                  onChange={(e) => handleRoleChange(e.target.value)}
                  disabled={updatingRole}
                  className="px-3 py-2 border border-gray4 rounded-lg body-medium-medium bg-white focus:outline-none focus:ring-2 focus:ring-purple--light3 disabled:opacity-50"
                >
                  <option value="user">User</option>
                  <option value="admin">Admin</option>
                </select>
                {updatingRole && (
                  <span className="body-small-regular text-secondary--text">Saving...</span>
                )}
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-purple--light5 flex items-center justify-center">
                  <Mail size={20} className="text-purple" />
                </div>
                <div>
                  <div className="body-xs-regular text-secondary--text">Email</div>
                  <div className="body-medium-medium">{user.email}</div>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-purple--light5 flex items-center justify-center">
                  <Calendar size={20} className="text-purple" />
                </div>
                <div>
                  <div className="body-xs-regular text-secondary--text">Member Since</div>
                  <div className="body-medium-medium">
                    {new Date(user.createdAt).toLocaleDateString('en-US', {
                      day: 'numeric',
                      month: 'long',
                      year: 'numeric'
                    })}
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-green--light6 flex items-center justify-center">
                  <Users size={20} className="text-green--dark" />
                </div>
                <div>
                  <div className="body-xs-regular text-secondary--text">Children</div>
                  <div className="body-medium-medium">{user.children.length}</div>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-cyan--light3 flex items-center justify-center">
                  <Activity size={20} className="text-purple--dark" />
                </div>
                <div>
                  <div className="body-xs-regular text-secondary--text">Total Activities</div>
                  <div className="body-medium-medium">{user.recentActivities.length}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Children Section */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <div className="flex items-center gap-2 mb-4">
          <User size={24} className="text-purple" />
          <h3 className="heading-h5">Children ({user.children.length})</h3>
        </div>
        
        {user.children.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {user.children.map((child) => (
              <div key={child.id} className="border border-gray4 rounded-lg p-4">
                <div className="flex items-center gap-3 mb-3">
                  <div className="w-12 h-12 rounded-full bg-purple--light4 flex items-center justify-center body-medium-medium text-purple">
                    {child.fullName.charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <div className="body-medium-medium">{child.fullName}</div>
                    <div className="body-xs-regular text-secondary--text">{child.relationship}</div>
                  </div>
                </div>
                
                {child.dob && (
                  <div className="body-small-regular text-secondary--text mb-2">
                    DOB: {new Date(child.dob).toLocaleDateString('en-US', {
                      day: 'numeric',
                      month: 'short',
                      year: 'numeric'
                    })}
                  </div>
                )}
                
                <div className="flex items-center justify-between pt-3 border-t border-gray4">
                  <div>
                    <div className="body-xs-regular text-secondary--text">Total Score</div>
                    <div className="body-medium-bold text-purple">{child.score}</div>
                  </div>
                  <div>
                    <div className="body-xs-regular text-secondary--text">Score Update</div>
                    <div className="body-medium-bold text-green--dark">+{child.scoreUpdate}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 body-medium-regular text-secondary--text">
            No children registered
          </div>
        )}
      </div>

      {/* Recent Activities Section */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <div className="flex items-center gap-2 mb-4">
          <Activity size={24} className="text-purple" />
          <h3 className="heading-h5">Recent Activities</h3>
        </div>
        
        {user.recentActivities.length > 0 ? (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray--light1 border-b border-gray4">
                <tr>
                  <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Activity Name</th>
                  <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Category</th>
                  <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Date Completed</th>
                  <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Score</th>
                  <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray4">
                {user.recentActivities.map((activity) => (
                  <tr key={activity.id} className="hover:bg-gray--light1">
                    <td className="px-4 py-3 body-medium-medium">{activity.activityName}</td>
                    <td className="px-4 py-3">{getCategoryBadge(activity.category)}</td>
                    <td className="px-4 py-3 body-medium-regular whitespace-nowrap">
                      {new Date(activity.dateCompleted).toLocaleDateString('en-US', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric'
                      })}
                    </td>
                    <td className="px-4 py-3 body-medium-bold text-purple">{activity.scoreEarned}</td>
                    <td className="px-4 py-3">{getActivityStatusBadge(activity.status)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="text-center py-8 body-medium-regular text-secondary--text">
            No activities completed yet
          </div>
        )}
      </div>

      {/* Rewards and Redemptions Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Available Rewards */}
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center gap-2 mb-4">
            <Gift size={24} className="text-purple" />
            <h3 className="heading-h5">Available Rewards ({user.rewards.length})</h3>
          </div>
          
          {user.rewards.length > 0 ? (
            <div className="space-y-3">
              {user.rewards.map((reward) => (
                <div key={reward.rewardId} className="flex items-center justify-between p-3 border border-gray4 rounded-lg">
                  <div className="body-medium-medium">{reward.name}</div>
                  <div className="body-medium-bold text-purple">{reward.cost} pts</div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-8 body-medium-regular text-secondary--text">
              No rewards available
            </div>
          )}
        </div>

        {/* Recent Redemptions */}
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center gap-2 mb-4">
            <Award size={24} className="text-purple" />
            <h3 className="heading-h5">Recent Redemptions</h3>
          </div>
          
          {user.recentRedemptions.length > 0 ? (
            <div className="space-y-3">
              {user.recentRedemptions.map((redemption) => (
                <div key={redemption.id} className="p-3 border border-gray4 rounded-lg">
                  <div className="flex items-center justify-between mb-2">
                    <div className="body-medium-medium">{redemption.rewardName}</div>
                    <div className="body-medium-bold text-red">-{redemption.scoreUsed} pts</div>
                  </div>
                  <div className="flex items-center justify-between body-small-regular text-secondary--text">
                    <span>By: {redemption.childName}</span>
                    <span>
                      {new Date(redemption.dateRedeemed).toLocaleDateString('en-US', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric'
                      })}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-8 body-medium-regular text-secondary--text">
              No redemptions yet
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
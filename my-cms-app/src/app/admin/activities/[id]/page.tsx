// app/admin/activities/[id]/page.tsx
'use client';

import { useEffect, useState, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { ArrowLeft, Edit2, Save, X, Video, FileText, BarChart3, Users, Calendar, Award, Undo2, Redo2, Merge, Trash2, Plus, Lightbulb } from 'lucide-react';
import cuid from 'cuid';

interface ActivityRecord {
  id: string;
  childName: string;
  scoreEarned: number;
  dateCompleted: string;
  status: string;
}

// Segment สำหรับ Language
interface LanguageSegment {
  id: string;
  start: number;
  end: number;
  text: string;
}

// Segment สำหรับ Analysis
interface AnalysisSegment {
  id: string;
  question: string;
  answer: string;
  solution: string;
  score: number;
}

type SegmentType = LanguageSegment[] | AnalysisSegment[];

interface ActivityDetail {
  activityId: string;
  nameActivity: string;
  category: string;
  descriptionActivity: string;
  difficulty: string;
  maxScore: number;
  videoUrl?: string;
  content: string;
  segments?: any;
  createdAt: string;
  updatedAt: string;
  responses: number;
  recentRecords?: ActivityRecord[];
}

export default function ActivityDetailPage() {
  const params = useParams();
  const router = useRouter();
  const [activity, setActivity] = useState<ActivityDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [editForm, setEditForm] = useState<Partial<ActivityDetail>>({});
  const [saving, setSaving] = useState(false);

  // Segment state สำหรับ Language
  const [languageSegments, setLanguageSegments] = useState<LanguageSegment[]>([]);
  const [selectedSegmentIndices, setSelectedSegmentIndices] = useState<number[]>([]);
  const [languageHistory, setLanguageHistory] = useState<LanguageSegment[][]>([]);
  const [languageHistoryIndex, setLanguageHistoryIndex] = useState(-1);

  // Segment state สำหรับ Analysis
  const [analysisSegments, setAnalysisSegments] = useState<AnalysisSegment[]>([]);
  const [analysisHistory, setAnalysisHistory] = useState<AnalysisSegment[][]>([]);
  const [analysisHistoryIndex, setAnalysisHistoryIndex] = useState(-1);

  useEffect(() => {
    if (params.id) {
      fetchActivityDetail();
    }
  }, [params.id]);

  const fetchActivityDetail = async () => {
    try {
      const res = await fetch(`/api/activities/${params.id}`);
      if (res.ok) {
        const data = await res.json();
        setActivity(data);
        setEditForm(data);

        // Initialize segments based on category
        if (data.segments) {
          const parsedSegments = typeof data.segments === 'string'
            ? JSON.parse(data.segments)
            : data.segments;

          if (data.category === 'ด้านภาษา') {
            setLanguageSegments(parsedSegments || []);
            setLanguageHistory([parsedSegments || []]);
            setLanguageHistoryIndex(0);
          } else if (data.category === 'ด้านคำนวณ') {
            setAnalysisSegments(parsedSegments || []);
            setAnalysisHistory([parsedSegments || []]);
            setAnalysisHistoryIndex(0);
          }
        }
      } else {
        console.error('Activity not found');
      }
    } catch (error) {
      console.error('Failed to fetch activity:', error);
    } finally {
      setLoading(false);
    }
  };

  // ==================== Language Segment Functions ====================
  const saveLanguageSnapshot = (newSegments: LanguageSegment[]) => {
    setLanguageHistory(prev => {
      const newHistory = prev.slice(0, languageHistoryIndex + 1);
      newHistory.push(newSegments);
      if (newHistory.length > 50) newHistory.shift();
      return newHistory;
    });
    setLanguageHistoryIndex(prev => Math.min(prev + 1, 49));
  };

  const handleLanguageUndo = () => {
    if (languageHistoryIndex > 0) {
      const newIndex = languageHistoryIndex - 1;
      setLanguageHistoryIndex(newIndex);
      setLanguageSegments(languageHistory[newIndex]);
      setSelectedSegmentIndices([]);
    }
  };

  const handleLanguageRedo = () => {
    if (languageHistoryIndex < languageHistory.length - 1) {
      const newIndex = languageHistoryIndex + 1;
      setLanguageHistoryIndex(newIndex);
      setLanguageSegments(languageHistory[newIndex]);
      setSelectedSegmentIndices([]);
    }
  };

  const handleLanguageSegmentChange = (index: number, field: 'start' | 'end' | 'text', value: string | number) => {
    const newSegments = languageSegments.map((seg, i) => {
      if (i === index) {
        if (field === 'start' || field === 'end') {
          return { ...seg, [field]: parseFloat(value as string) || 0 };
        }
        return { ...seg, [field]: value as string };
      }
      return seg;
    });
    setLanguageSegments(newSegments);
    saveLanguageSnapshot(newSegments);
  };

  const handleSelectSegment = (index: number, isSelected: boolean) => {
    setSelectedSegmentIndices(prev => {
      if (isSelected) {
        return [...prev, index].sort((a, b) => a - b);
      }
      return prev.filter(i => i !== index);
    });
  };

  const handleMergeSegments = () => {
    if (selectedSegmentIndices.length < 2) {
      alert('กรุณาเลือกอย่างน้อย 2 ประโยคเพื่อรวม');
      return;
    }

    const sortedIndices = selectedSegmentIndices;
    const segmentsToMerge = sortedIndices.map(i => languageSegments[i]);

    const mergedText = segmentsToMerge.map(s => s.text).join(' ');
    const earliestStart = segmentsToMerge[0].start;
    const latestEnd = segmentsToMerge[segmentsToMerge.length - 1].end;

    const newSegment: LanguageSegment = {
      id: cuid(),
      start: earliestStart,
      end: latestEnd,
      text: mergedText,
    };

    const newSegments: LanguageSegment[] = [];
    const firstIndex = sortedIndices[0];

    languageSegments.forEach((seg, index) => {
      if (index === firstIndex) {
        newSegments.push(newSegment);
      } else if (!sortedIndices.includes(index)) {
        newSegments.push(seg);
      }
    });

    setLanguageSegments(newSegments);
    setSelectedSegmentIndices([]);
    saveLanguageSnapshot(newSegments);
  };

  const handleDeleteLanguageSegment = (index: number) => {
    const newSegments = languageSegments.filter((_, i) => i !== index);
    setLanguageSegments(newSegments);
    saveLanguageSnapshot(newSegments);
  };

  // ==================== Analysis Segment Functions ====================
  const saveAnalysisSnapshot = (newSegments: AnalysisSegment[]) => {
    setAnalysisHistory(prev => {
      const newHistory = prev.slice(0, analysisHistoryIndex + 1);
      newHistory.push(newSegments);
      if (newHistory.length > 50) newHistory.shift();
      return newHistory;
    });
    setAnalysisHistoryIndex(prev => Math.min(prev + 1, 49));
  };

  const handleAnalysisUndo = () => {
    if (analysisHistoryIndex > 0) {
      const newIndex = analysisHistoryIndex - 1;
      setAnalysisHistoryIndex(newIndex);
      setAnalysisSegments(analysisHistory[newIndex]);
    }
  };

  const handleAnalysisRedo = () => {
    if (analysisHistoryIndex < analysisHistory.length - 1) {
      const newIndex = analysisHistoryIndex + 1;
      setAnalysisHistoryIndex(newIndex);
      setAnalysisSegments(analysisHistory[newIndex]);
    }
  };

  const handleAnalysisSegmentChange = (index: number, field: keyof AnalysisSegment, value: string | number) => {
    const newSegments = analysisSegments.map((seg, i) => {
      if (i === index) {
        if (field === 'score') {
          return { ...seg, score: parseInt(value as string) || 0 };
        }
        return { ...seg, [field]: value as string };
      }
      return seg;
    });
    setAnalysisSegments(newSegments);
    saveAnalysisSnapshot(newSegments);

    // Update maxScore
    const totalScore = newSegments.reduce((sum, q) => sum + q.score, 0);
    setEditForm(prev => ({ ...prev, maxScore: totalScore }));
  };

  const handleAddAnalysisSegment = () => {
    const newSegment: AnalysisSegment = {
      id: cuid(),
      question: '',
      answer: '',
      solution: '',
      score: 10,
    };
    const newSegments = [...analysisSegments, newSegment];
    setAnalysisSegments(newSegments);
    saveAnalysisSnapshot(newSegments);

    // Update maxScore
    const totalScore = newSegments.reduce((sum, q) => sum + q.score, 0);
    setEditForm(prev => ({ ...prev, maxScore: totalScore }));
  };

  const handleDeleteAnalysisSegment = (index: number) => {
    const newSegments = analysisSegments.filter((_, i) => i !== index);
    setAnalysisSegments(newSegments);
    saveAnalysisSnapshot(newSegments);

    // Update maxScore
    const totalScore = newSegments.reduce((sum, q) => sum + q.score, 0);
    setEditForm(prev => ({ ...prev, maxScore: totalScore }));
  };

  const handleEdit = () => {
    setIsEditing(true);
  };

  const handleCancel = () => {
    setIsEditing(false);
    setEditForm(activity || {});
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      // เตรียม segments ตาม category
      let segmentsToSave = null;
      let maxScoreToSave = editForm.maxScore;

      if (activity?.category === 'ด้านภาษา') {
        segmentsToSave = languageSegments;
      } else if (activity?.category === 'ด้านคำนวณ') {
        segmentsToSave = analysisSegments;
        // คำนวณ maxScore จาก segments
        maxScoreToSave = analysisSegments.reduce((sum, q) => sum + q.score, 0);
      }

      const res = await fetch(`/api/activities/${params.id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: editForm.nameActivity,
          category: editForm.category,
          description: editForm.descriptionActivity,
          difficulty: editForm.difficulty,
          maxScore: maxScoreToSave,
          videoUrl: editForm.videoUrl,
          content: editForm.content,
          segments: segmentsToSave,
        }),
      });

      if (res.ok) {
        const data = await res.json();
        setActivity(data);
        setIsEditing(false);
        alert('Activity updated successfully!');
      } else {
        alert('Failed to update activity');
      }
    } catch (error) {
      console.error('Failed to update activity:', error);
      alert('Failed to update activity');
    } finally {
      setSaving(false);
    }
  };

  const getDifficultyBadge = (difficulty: string) => {
    const colors: { [key: string]: string } = {
      'ง่าย': 'bg-green--light6 text-green--dark',
      'กลาง': 'bg-yellow--light3 text-dark',
      'ยาก': 'bg-red--light6 text-red--dark',
    };
    return (
      <span className={`inline-flex items-center px-3 py-1 rounded-full body-small-medium ${colors[difficulty] || 'bg-gray3 text-secondary--text'}`}>
        {difficulty}
      </span>
    );
  };

  const getStatusBadge = (status: string) => {
    const colors: { [key: string]: string } = {
      'Completed': 'bg-green--light6 text-green--dark',
      'Pending': 'bg-yellow--light3 text-dark',
      'Failed': 'bg-red--light6 text-red--dark',
    };
    return (
      <span className={`inline-flex items-center px-2 py-1 rounded-full body-xs-medium ${colors[status] || 'bg-gray3 text-secondary--text'}`}>
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

  if (!activity) {
    return (
      <div className="p-8">
        <div className="bg-white rounded-lg shadow p-12 text-center">
          <div className="body-large-medium text-secondary--text mb-2">
            Activity not found
          </div>
          <button 
            onClick={() => router.push('/admin/activities')}
            className="btn-primary px-4 py-2 rounded-lg mt-4"
          >
            Back to Activities
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
          onClick={() => router.push('/admin/activities')}
          className="flex items-center gap-2 body-medium-medium text-purple hover:text-purple--dark mb-4"
        >
          <ArrowLeft size={20} />
          Back to Activities
        </button>
        <div className="flex items-center justify-between">
          <div>
            <div className="body-small-regular text-secondary--text mb-1">
              Activities &gt; Activity Detail
            </div>
            <h1 className="heading-h3">ACTIVITY DETAIL</h1>
          </div>
          <div className="flex items-center gap-3">
            {!isEditing ? (
              <button 
                onClick={handleEdit}
                className="btn-primary px-4 py-2 rounded-lg flex items-center gap-2"
              >
                <Edit2 size={20} />
                Edit
              </button>
            ) : (
              <>
                <button 
                  onClick={handleCancel}
                  className="btn-white px-4 py-2 rounded-lg flex items-center gap-2"
                  disabled={saving}
                >
                  <X size={20} />
                  Cancel
                </button>
                <button 
                  onClick={handleSave}
                  className="btn-primary px-4 py-2 rounded-lg flex items-center gap-2"
                  disabled={saving}
                >
                  <Save size={20} />
                  {saving ? 'Saving...' : 'Save'}
                </button>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Main Info Card */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
          {/* Statistics */}
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-lg bg-purple--light5 flex items-center justify-center">
              <Users size={24} className="text-purple" />
            </div>
            <div>
              <div className="body-xs-regular text-secondary--text">Total Responses</div>
              <div className="heading-h5">{activity.responses}</div>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-lg bg-yellow--light3 flex items-center justify-center">
              <Award size={24} className="text-dark" />
            </div>
            <div>
              <div className="body-xs-regular text-secondary--text">Max Score</div>
              <div className="heading-h5">{activity.maxScore}</div>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-lg bg-cyan--light3 flex items-center justify-center">
              <Calendar size={24} className="text-purple--dark" />
            </div>
            <div>
              <div className="body-xs-regular text-secondary--text">Created</div>
              <div className="body-medium-medium">
                {new Date(activity.createdAt).toLocaleDateString('en-US', {
                  day: 'numeric',
                  month: 'short',
                  year: 'numeric'
                })}
              </div>
            </div>
          </div>
        </div>

        {/* Activity Details */}
        <div className="space-y-4">
          {/* Activity Name */}
          <div>
            <label className="body-small-medium text-secondary--text mb-2 block">Activity Name</label>
            {isEditing ? (
              <input
                type="text"
                value={editForm.nameActivity || ''}
                onChange={(e) => setEditForm({ ...editForm, nameActivity: e.target.value })}
                className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
              />
            ) : (
              <div className="heading-h5">{activity.nameActivity}</div>
            )}
          </div>

          {/* Category and Difficulty */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="body-small-medium text-secondary--text mb-2 block">Category</label>
              {isEditing ? (
                <input
                  type="text"
                  value={editForm.category || ''}
                  onChange={(e) => setEditForm({ ...editForm, category: e.target.value })}
                  className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
                />
              ) : (
                <div className="body-medium-medium">{activity.category}</div>
              )}
            </div>

            <div>
              <label className="body-small-medium text-secondary--text mb-2 block">Difficulty</label>
              {isEditing ? (
                <select
                  value={editForm.difficulty || ''}
                  onChange={(e) => setEditForm({ ...editForm, difficulty: e.target.value })}
                  className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
                >
                  <option value="ง่าย">ง่าย (Easy)</option>
                  <option value="กลาง">กลาง (Medium)</option>
                  <option value="ยาก">ยาก (Hard)</option>
                </select>
              ) : (
                getDifficultyBadge(activity.difficulty)
              )}
            </div>
          </div>

          {/* Max Score */}
          <div>
            <label className="body-small-medium text-secondary--text mb-2 block">Max Score</label>
            {isEditing ? (
              <input
                type="number"
                value={editForm.maxScore || 0}
                onChange={(e) => setEditForm({ ...editForm, maxScore: parseInt(e.target.value) })}
                className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
              />
            ) : (
              <div className="body-medium-medium">{activity.maxScore} points</div>
            )}
          </div>

          {/* Description */}
          <div>
            <label className="body-small-medium text-secondary--text mb-2 block">Description</label>
            {isEditing ? (
              <textarea
                value={editForm.descriptionActivity || ''}
                onChange={(e) => setEditForm({ ...editForm, descriptionActivity: e.target.value })}
                rows={4}
                className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
              />
            ) : (
              <div className="body-medium-regular text-secondary--text">{activity.descriptionActivity}</div>
            )}
          </div>

          {/* Video URL */}
          <div>
            <label className="body-small-medium text-secondary--text mb-2 block">Video URL</label>
            {isEditing ? (
              <input
                type="url"
                value={editForm.videoUrl || ''}
                onChange={(e) => setEditForm({ ...editForm, videoUrl: e.target.value })}
                placeholder="https://..."
                className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
              />
            ) : (
              activity.videoUrl ? (
                <a href={activity.videoUrl} target="_blank" rel="noopener noreferrer" className="flex items-center gap-2 text-purple hover:text-purple--dark body-medium-medium">
                  <Video size={16} />
                  {activity.videoUrl}
                </a>
              ) : (
                <div className="body-medium-regular text-secondary--text">No video URL</div>
              )
            )}
          </div>
        </div>
      </div>

      {/* Content Section */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <div className="flex items-center gap-2 mb-4">
          <FileText size={24} className="text-purple" />
          <h3 className="heading-h5">Content</h3>
        </div>
        {isEditing ? (
          <textarea
            value={editForm.content || ''}
            onChange={(e) => setEditForm({ ...editForm, content: e.target.value })}
            rows={8}
            className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
          />
        ) : (
          <div className="body-medium-regular whitespace-pre-wrap">{activity.content}</div>
        )}
      </div>

      {/* Language Segments Editor */}
      {activity?.category === 'ด้านภาษา' && isEditing && (
        <div className="bg-white rounded-lg shadow p-6 mb-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="heading-h5">ประโยค (Segments)</h3>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={handleLanguageUndo}
                disabled={languageHistoryIndex <= 0}
                className="p-2 rounded-lg border border-gray6 hover:bg-gray--light1 disabled:opacity-50 disabled:cursor-not-allowed"
                title="Undo"
              >
                <Undo2 size={18} />
              </button>
              <button
                type="button"
                onClick={handleLanguageRedo}
                disabled={languageHistoryIndex >= languageHistory.length - 1}
                className="p-2 rounded-lg border border-gray6 hover:bg-gray--light1 disabled:opacity-50 disabled:cursor-not-allowed"
                title="Redo"
              >
                <Redo2 size={18} />
              </button>
              <button
                type="button"
                onClick={handleMergeSegments}
                disabled={selectedSegmentIndices.length < 2}
                className="flex items-center gap-2 px-3 py-2 rounded-lg bg-purple text-white hover:bg-purple--dark disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Merge size={18} />
                Merge ({selectedSegmentIndices.length})
              </button>
            </div>
          </div>

          {languageSegments.length === 0 ? (
            <div className="text-center py-8 text-secondary--text body-medium-regular">
              ไม่มีประโยค
            </div>
          ) : (
            <div className="space-y-3">
              {languageSegments.map((segment, index) => (
                <div
                  key={segment.id}
                  className={`flex items-start gap-3 p-4 rounded-lg border ${
                    selectedSegmentIndices.includes(index)
                      ? 'border-purple bg-purple--light5'
                      : 'border-gray6 bg-gray--light1'
                  }`}
                >
                  <input
                    type="checkbox"
                    checked={selectedSegmentIndices.includes(index)}
                    onChange={(e) => handleSelectSegment(index, e.target.checked)}
                    className="mt-2 w-5 h-5 rounded border-gray6 text-purple focus:ring-purple"
                  />
                  <div className="flex-1 space-y-2">
                    <div className="flex items-center gap-4">
                      <div className="flex items-center gap-2">
                        <label className="body-small-medium text-secondary--text">เริ่ม:</label>
                        <input
                          type="number"
                          step="0.1"
                          value={segment.start}
                          onChange={(e) => handleLanguageSegmentChange(index, 'start', e.target.value)}
                          className="w-24 px-2 py-1 border border-gray6 rounded body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
                        />
                        <span className="body-small-regular text-secondary--text">วินาที</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <label className="body-small-medium text-secondary--text">จบ:</label>
                        <input
                          type="number"
                          step="0.1"
                          value={segment.end}
                          onChange={(e) => handleLanguageSegmentChange(index, 'end', e.target.value)}
                          className="w-24 px-2 py-1 border border-gray6 rounded body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
                        />
                        <span className="body-small-regular text-secondary--text">วินาที</span>
                      </div>
                    </div>
                    <div>
                      <label className="body-small-medium text-secondary--text mb-1 block">ประโยค:</label>
                      <input
                        type="text"
                        value={segment.text}
                        onChange={(e) => handleLanguageSegmentChange(index, 'text', e.target.value)}
                        className="w-full px-3 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
                        placeholder="กรอกประโยค..."
                      />
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => handleDeleteLanguageSegment(index)}
                    className="p-2 text-red--dark hover:bg-red--light6 rounded-lg"
                    title="ลบประโยค"
                  >
                    <Trash2 size={18} />
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Analysis Segments Editor */}
      {activity?.category === 'ด้านคำนวณ' && isEditing && (
        <div className="bg-white rounded-lg shadow p-6 mb-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="heading-h5">คำถาม (Questions)</h3>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={handleAnalysisUndo}
                disabled={analysisHistoryIndex <= 0}
                className="p-2 rounded-lg border border-gray6 hover:bg-gray--light1 disabled:opacity-50 disabled:cursor-not-allowed"
                title="Undo"
              >
                <Undo2 size={18} />
              </button>
              <button
                type="button"
                onClick={handleAnalysisRedo}
                disabled={analysisHistoryIndex >= analysisHistory.length - 1}
                className="p-2 rounded-lg border border-gray6 hover:bg-gray--light1 disabled:opacity-50 disabled:cursor-not-allowed"
                title="Redo"
              >
                <Redo2 size={18} />
              </button>
              <button
                type="button"
                onClick={handleAddAnalysisSegment}
                className="flex items-center gap-2 px-3 py-2 rounded-lg bg-purple text-white hover:bg-purple--dark"
              >
                <Plus size={18} />
                เพิ่มคำถาม
              </button>
            </div>
          </div>

          {analysisSegments.length === 0 ? (
            <div className="text-center py-8 text-secondary--text body-medium-regular">
              ไม่มีคำถาม - คลิก "เพิ่มคำถาม" เพื่อเริ่มต้น
            </div>
          ) : (
            <div className="space-y-4">
              {analysisSegments.map((segment, index) => (
                <div
                  key={segment.id}
                  className="p-4 rounded-lg border border-gray6 bg-gray--light1"
                >
                  <div className="flex items-center justify-between mb-3">
                    <span className="body-medium-bold text-purple">ข้อที่ {index + 1}</span>
                    <button
                      type="button"
                      onClick={() => handleDeleteAnalysisSegment(index)}
                      className="p-2 text-red--dark hover:bg-red--light6 rounded-lg"
                      title="ลบคำถาม"
                    >
                      <Trash2 size={18} />
                    </button>
                  </div>

                  <div className="space-y-3">
                    <div>
                      <label className="body-small-medium text-secondary--text mb-1 block">โจทย์:</label>
                      <input
                        type="text"
                        value={segment.question}
                        onChange={(e) => handleAnalysisSegmentChange(index, 'question', e.target.value)}
                        className="w-full px-3 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
                        placeholder="กรอกโจทย์..."
                      />
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                      <div>
                        <label className="body-small-medium text-secondary--text mb-1 block">เฉลย:</label>
                        <input
                          type="text"
                          value={segment.answer}
                          onChange={(e) => handleAnalysisSegmentChange(index, 'answer', e.target.value)}
                          className="w-full px-3 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
                          placeholder="กรอกเฉลย..."
                        />
                      </div>
                      <div>
                        <label className="body-small-medium text-secondary--text mb-1 block">คะแนน:</label>
                        <input
                          type="number"
                          value={segment.score}
                          onChange={(e) => handleAnalysisSegmentChange(index, 'score', e.target.value)}
                          className="w-full px-3 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
                          min="0"
                        />
                      </div>
                    </div>

                    <div>
                      <label className="body-small-medium text-secondary--text mb-1 flex items-center gap-2">
                        <Lightbulb size={16} className="text-amber-500" />
                        คำแนะนำ (Hint):
                      </label>
                      <textarea
                        value={segment.solution}
                        onChange={(e) => handleAnalysisSegmentChange(index, 'solution', e.target.value)}
                        className="w-full px-3 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
                        rows={2}
                        placeholder="กรอกคำแนะนำ..."
                      />
                    </div>
                  </div>
                </div>
              ))}

              <div className="pt-3 border-t border-gray6">
                <div className="flex items-center justify-between">
                  <span className="body-medium-medium text-secondary--text">คะแนนรวม:</span>
                  <span className="heading-h5 text-purple">
                    {analysisSegments.reduce((sum, q) => sum + q.score, 0)} คะแนน
                  </span>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Recent Records Section */}
      {activity.recentRecords && activity.recentRecords.length > 0 && (
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center gap-2 mb-4">
            <BarChart3 size={24} className="text-purple" />
            <h3 className="heading-h5">Recent Activity Records</h3>
          </div>
          
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray--light1 border-b border-gray4">
                <tr>
                  <th className="px-4 py-3 text-left body-small-medium text-secondary--text">No.</th>
                  <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Child Name</th>
                  <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Score Earned</th>
                  <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Date Completed</th>
                  <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray4">
                {activity.recentRecords.map((record, index) => (
                  <tr key={record.id} className="hover:bg-gray--light1">
                    <td className="px-4 py-3 body-medium-regular">{index + 1}</td>
                    <td className="px-4 py-3 body-medium-medium">{record.childName}</td>
                    <td className="px-4 py-3 body-medium-bold text-purple">{record.scoreEarned}/{activity.maxScore}</td>
                    <td className="px-4 py-3 body-medium-regular">
                      {new Date(record.dateCompleted).toLocaleDateString('en-US', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric'
                      })}
                    </td>
                    <td className="px-4 py-3">{getStatusBadge(record.status)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
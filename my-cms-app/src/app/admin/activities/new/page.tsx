// app/admin/activities/new/page.tsx
'use client';

import { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { Send, Plus, Trash2 } from 'lucide-react';
import { authClient } from '@/lib/auth-client';
import UserProfile from '@/components/UserProfile';

// Types
interface Segment {
  id: string;
  start: number;
  end: number;
  text: string;
}

interface Question {
  id: string;
  question: string;
  answer: string;
  hint: string;
  score: number;
}

interface ActivityFormData {
  name: string;
  category: string;
  content: string;
  difficulty: string;
  maxScore: number;
  description: string;
  videoUrl: string;
  segments: Segment[] | Question[] | null;
  parentId: string;
}

export default function NewActivityPage() {
  const router = useRouter();
  
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [formData, setFormData] = useState<ActivityFormData>({
    name: '',
    category: '',
    content: '',
    difficulty: 'ง่าย',
    maxScore: 100,
    description: '',
    videoUrl: '',
    segments: null,
    parentId: '',
  });
  const [videoId, setVideoId] = useState<string | null>(null);
  const [isResolvingUrl, setIsResolvingUrl] = useState(false);
  const resolveTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [isFetching, setIsFetching] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Admin doesn't have a parent record — parentId stays empty (nullable in DB)
  useEffect(() => {
    async function checkSession() {
      try {
        const { data: session } = await authClient.getSession();
        if (!session?.user) {
          router.push('/login');
          return;
        }
        setIsLoading(false);
      } catch (err) {
        console.error('Error checking session:', err);
        setError('Failed to load user data');
        setIsLoading(false);
      }
    }

    checkSession();
  }, [router]);

  // Extract video ID from URL
  const extractVideoId = (url: string): { id: string | null, type: 'youtube' | 'tiktok' | null } => {
    // YouTube
    const youtubeRegex = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i;
    const youtubeMatch = url.match(youtubeRegex);
    if (youtubeMatch) return { id: youtubeMatch[1], type: 'youtube' };

    // TikTok
    const tiktokRegex = /(?:tiktok\.com\/(?:@[\w.]+\/video\/|v\/|t\/)|vt\.tiktok\.com\/.*\/)(\d+)/i;
    const tiktokMatch = url.match(tiktokRegex);
    if (tiktokMatch) return { id: tiktokMatch[1], type: 'tiktok' };

    return { id: null, type: null };
  };

  // Handle category selection
  const handleCategorySelect = (category: string) => {
    setSelectedCategory(category);
    setFormData(prev => ({
      ...prev,
      category: category,
      videoUrl: '',
      content: '',  // Reset content when changing category
      segments: null
    }));
    setVideoId(null);
    setQuestions([]);
  };

  // Handle input changes
  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
  ) => {
    const { name, value } = e.target;
    
    if (name === 'maxScore') {
      const newScore = parseInt(value) || 0;
      handleMaxScoreChange(newScore);
    } else {
      setFormData(prev => ({
        ...prev,
        [name]: value
      }));
    }

    if (name === 'videoUrl') {
      if (resolveTimerRef.current) clearTimeout(resolveTimerRef.current);
      const { id, type } = extractVideoId(value);
      if (type === 'youtube' || (type === 'tiktok' && selectedCategory === 'ด้านร่างกาย')) {
        setVideoId(id);
        setIsResolvingUrl(false);
      } else if (
        selectedCategory === 'ด้านร่างกาย' &&
        (value.includes('tiktok.com') || value.includes('vt.tiktok.com'))
      ) {
        // Short URL — resolve via oEmbed after debounce
        setVideoId(null);
        setIsResolvingUrl(true);
        resolveTimerRef.current = setTimeout(async () => {
          try {
            const res = await fetch('/api/tiktok-oembed', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ videoUrl: value }),
            });
            if (res.ok) {
              const data = await res.json();
              const match = (data.html as string | undefined)?.match(/data-video-id="(\d+)"/);
              if (match) setVideoId(match[1]);
            }
          } catch {}
          setIsResolvingUrl(false);
        }, 800);
      } else {
        setVideoId(null);
        setIsResolvingUrl(false);
      }
    }
  };

  // Fetch video data (Language only)
  const handleFetch = async () => {
    if (!formData.videoUrl) {
      alert('Please enter a video URL first');
      return;
    }

    const { id } = extractVideoId(formData.videoUrl);
    if (!id) {
      alert('Invalid YouTube URL');
      return;
    }

    setIsFetching(true);

    try {
      const response = await fetch('/api/fetch-video-data', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ videoUrl: formData.videoUrl })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to fetch video data');
      }

      const data = await response.json();

      const segmentsWithIds: Segment[] = data.segments?.map((seg: any, idx: number) => ({
        id: `seg_${Date.now()}_${idx}`,
        start: seg.start,
        end: seg.end,
        text: seg.text
      })) || [];

      setFormData(prev => ({
        ...prev,
        name: data.title || prev.name,
        description: data.description || prev.description,
        segments: segmentsWithIds.length > 0 ? segmentsWithIds : null,
        content: data.videoId ? `Video Source: YouTube ID ${data.videoId}` : prev.content
      }));

      alert('Video data fetched successfully!');
    } catch (error) {
      console.error('Fetch error:', error);
      alert(`Error: ${error instanceof Error ? error.message : 'Failed to fetch video data'}`);
    } finally {
      setIsFetching(false);
    }
  };

  // Question handlers (Analytical only)
  const addQuestion = () => {
    const newQuestion: Question = {
      id: `q_${Date.now()}`,
      question: '',
      answer: '',
      hint: '',
      score: 1  // Default 1 point per question
    };
    setQuestions([...questions, newQuestion]);
    
    // Update max score (add 1 for new question)
    setFormData(prev => ({
      ...prev,
      maxScore: prev.maxScore + 1
    }));
  };

  const updateQuestion = (id: string, field: keyof Question, value: string | number) => {
    setQuestions(questions.map(q => 
      q.id === id ? { ...q, [field]: value } : q
    ));
    
    // If score is updated, recalculate maxScore
    if (field === 'score') {
      const newQuestions = questions.map(q => 
        q.id === id ? { ...q, score: Number(value) || 0 } : q
      );
      const totalScore = newQuestions.reduce((sum, q) => sum + q.score, 0);
      setFormData(prev => ({ ...prev, maxScore: totalScore }));
    }
  };

  const deleteQuestion = (id: string) => {
    const deletedQuestion = questions.find(q => q.id === id);
    const newQuestions = questions.filter(q => q.id !== id);
    setQuestions(newQuestions);
    
    // Update max score (subtract deleted question's score)
    if (deletedQuestion) {
      const newMaxScore = Math.max(0, formData.maxScore - deletedQuestion.score);
      setFormData(prev => ({ ...prev, maxScore: newMaxScore }));
    }
  };

  // Distribute scores evenly when maxScore changes (Analytical only)
  const handleMaxScoreChange = (newMaxScore: number) => {
    if (selectedCategory === 'ด้านคำนวณ' && questions.length > 0) {
      const scorePerQuestion = Math.floor(newMaxScore / questions.length);
      const remainder = newMaxScore % questions.length;
      
      const updatedQuestions = questions.map((q, index) => ({
        ...q,
        score: scorePerQuestion + (index < remainder ? 1 : 0)
      }));
      
      setQuestions(updatedQuestions);
    }
    
    setFormData(prev => ({ ...prev, maxScore: newMaxScore }));
  };

  // Publish activity
  const handlePublish = async (e: React.FormEvent) => {
    e.preventDefault();

    // Validation
    if (!selectedCategory) {
      alert('Please select a category');
      return;
    }

    if (!formData.name.trim()) {
      alert('Please enter an activity title');
      return;
    }

    if (!formData.description.trim()) {
      alert('Please enter an activity description');
      return;
    }

    // Content validation for Physical and Analytical
    if ((selectedCategory === 'ด้านร่างกาย' || selectedCategory === 'ด้านคำนวณ') && !formData.content.trim()) {
      alert(selectedCategory === 'ด้านร่างกาย' ? 'Please enter how to play instructions' : 'Please enter additional instructions');
      return;
    }

    if (selectedCategory === 'ด้านคำนวณ' && questions.length === 0) {
      alert('Please add at least one question');
      return;
    }

    setIsSubmitting(true);

    try {
      // Prepare segments based on category
      let segments = null;
      if (selectedCategory === 'ด้านภาษา') {
        segments = formData.segments;
      } else if (selectedCategory === 'ด้านคำนวณ') {
        segments = questions;
      }

      const dataToSubmit = {
        ...formData,
        segments,
        videoUrl: selectedCategory === 'ด้านคำนวณ' ? '' : formData.videoUrl
      };

      const response = await fetch('/api/activities', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(dataToSubmit)
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.error || 'Failed to create activity');
      }

      alert('Activity created successfully!');
      router.push('/admin/activities');
    } catch (error) {
      console.error('Submit error:', error);
      alert(`Error: ${error instanceof Error ? error.message : 'Failed to create activity'}`);
    } finally {
      setIsSubmitting(false);
    }
  };

  // Format segments for display (Language only)
  const getSegmentsText = () => {
    if (!formData.segments || formData.segments.length === 0) {
      return '';
    }
    return (formData.segments as Segment[])
      .map(seg => `[${seg.start}s - ${seg.end}s] ${seg.text}`)
      .join('\n');
  };

  // Loading state
  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="body-large-medium text-secondary--text">Loading...</div>
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="text-center space-y-4">
          <div className="body-large-medium text-red">{error}</div>
          <button
            onClick={() => router.push('/')}
            className="btn-primary px-4 py-2 rounded-lg"
          >
            Back to Login
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="p-8 max-w-4xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <div className="body-small-regular text-secondary--text mb-1">
            Activities &gt; Activities List &gt; Create
          </div>
          <h1 className="heading-h3">Create New Activity</h1>
        </div>
        <div className="flex items-center gap-4">
          <UserProfile />
          {selectedCategory && (
            <div className="flex items-center gap-3">
              {/*
                TODO: Save Draft
                - ต้องเพิ่ม field `is_draft` (boolean) ในตาราง activity
                - สร้าง API endpoint หรือเพิ่ม param ใน POST /api/activities
                - ซ่อนกิจกรรม draft จากหน้า Flutter และ list หลัก
              */}
              <button
                type="button"
                onClick={handlePublish}
                disabled={isSubmitting}
                className="btn-primary flex items-center gap-2 px-4 py-2 rounded-lg body-medium-medium disabled:opacity-50"
              >
                <Send size={20} />
                {isSubmitting ? 'Publishing...' : 'Publish'}
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Category Selection */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <h3 className="body-large-semibold text-dark mb-4">
          Select Activity Category <span className="text-red">*</span>
        </h3>
        <div className="grid grid-cols-3 gap-4">
          <button
            type="button"
            onClick={() => handleCategorySelect('ด้านภาษา')}
            className={`p-6 border-2 rounded-lg transition-all ${
              selectedCategory === 'ด้านภาษา'
                ? 'border-purple bg-purple--light5'
                : 'border-gray6 hover:border-purple--light3'
            }`}
          >
            <div className="body-large-semibold mb-2">ด้านภาษา</div>
            <div className="body-small-regular text-secondary--text">
              YouTube video with subtitles
            </div>
          </button>

          <button
            type="button"
            onClick={() => handleCategorySelect('ด้านร่างกาย')}
            className={`p-6 border-2 rounded-lg transition-all ${
              selectedCategory === 'ด้านร่างกาย'
                ? 'border-purple bg-purple--light5'
                : 'border-gray6 hover:border-purple--light3'
            }`}
          >
            <div className="body-large-semibold mb-2">ด้านร่างกาย</div>
            <div className="body-small-regular text-secondary--text">
              TikTok video demonstration
            </div>
          </button>

          <button
            type="button"
            onClick={() => handleCategorySelect('ด้านคำนวณ')}
            className={`p-6 border-2 rounded-lg transition-all ${
              selectedCategory === 'ด้านคำนวณ'
                ? 'border-purple bg-purple--light5'
                : 'border-gray6 hover:border-purple--light3'
            }`}
          >
            <div className="body-large-semibold mb-2">ด้านคำนวณ</div>
            <div className="body-small-regular text-secondary--text">
              Questions and answers
            </div>
          </button>
        </div>
      </div>

      {/* Form - Only show after category selection */}
      {selectedCategory && (
        <form onSubmit={handlePublish} className="space-y-6">
          {/* Video Information - Language & Physical */}
          {(selectedCategory === 'ด้านภาษา' || selectedCategory === 'ด้านร่างกาย') && (
            <div className="bg-white rounded-lg shadow p-6 space-y-4">
              <h3 className="body-large-semibold text-dark">
                Video Information <span className="text-red">*</span>
              </h3>
              <p className="body-small-regular text-secondary--text">
                {selectedCategory === 'ด้านภาษา' 
                  ? 'Provide a link to a YouTube video. The system will automatically fetch video details and transcripts.'
                  : 'Provide a link to a TikTok video for physical activity demonstration.'
                }
              </p>
              
              <div className="flex gap-3">
                <input
                  type="text"
                  name="videoUrl"
                  value={formData.videoUrl}
                  onChange={handleChange}
                  placeholder={`Paste your ${selectedCategory === 'ด้านภาษา' ? 'YouTube' : 'TikTok'} link here...`}
                  className="flex-1 px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
                />
                {selectedCategory === 'ด้านภาษา' && (
                  <button
                    type="button"
                    onClick={handleFetch}
                    disabled={isFetching || !videoId}
                    className="px-6 py-2 bg-gray--light1 text-secondary--text rounded-lg body-medium-medium hover:bg-gray3 disabled:opacity-50 disabled:cursor-not-allowed min-w-[100px]"
                  >
                    {isFetching ? 'Fetching...' : 'Fetch'}
                  </button>
                )}
              </div>

              {/* Video Preview */}
              {isResolvingUrl && (
                <div className="mt-4 bg-gray--light1 rounded-lg p-6 flex items-center justify-center gap-3 text-secondary--text">
                  <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24" fill="none">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
                  </svg>
                  <span className="body-medium-regular">Resolving short URL...</span>
                </div>
              )}
              {videoId && !isResolvingUrl && (
                <div className="mt-4 bg-gray--light1 rounded-lg p-4">
                  {selectedCategory === 'ด้านภาษา' ? (
                    <div className="aspect-video w-full max-w-2xl mx-auto bg-black rounded-lg overflow-hidden">
                      <iframe
                        width="100%"
                        height="100%"
                        src={`https://www.youtube.com/embed/${videoId}`}
                        allowFullScreen
                        title="Video Preview"
                        className="w-full h-full"
                      />
                    </div>
                  ) : (
                    <div className="relative w-full max-w-md mx-auto" style={{ paddingBottom: '100%' }}>
                      <iframe
                        className="absolute inset-0 w-full h-full rounded-lg"
                        src={`https://www.tiktok.com/embed/v2/${videoId}`}
                        allowFullScreen
                        scrolling="no"
                        title="TikTok Preview"
                      />
                    </div>
                  )}
                </div>
              )}
            </div>
          )}

          {/* Activity Title */}
          <div className="bg-white rounded-lg shadow p-6 space-y-4">
            <label className="body-large-semibold text-dark">
              Activity Title <span className="text-red">*</span>
            </label>
            <p className="body-small-regular text-secondary--text">
              Activity title is the title that users will actually see when they choose an activities.
            </p>
            <input
              type="text"
              name="name"
              value={formData.name}
              onChange={handleChange}
              placeholder="Activity Title"
              required
              className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
            />
          </div>

          {/* Activities Description */}
          <div className="bg-white rounded-lg shadow p-6 space-y-4">
            <label className="body-large-semibold text-dark">
              Activities Description
            </label>
            <p className="body-small-regular text-secondary--text">
              A description should have minimum of 255 words.
            </p>
            <textarea
              name="description"
              value={formData.description}
              onChange={handleChange}
              placeholder="Activities Description"
              rows={5}
              className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple resize-none"
            />
          </div>

          {/* Content/Instructions - Physical & Analytical */}
          {(selectedCategory === 'ด้านร่างกาย' || selectedCategory === 'ด้านคำนวณ') && (
            <div className="bg-white rounded-lg shadow p-6 space-y-4">
              <label className="body-large-semibold text-dark">
                {selectedCategory === 'ด้านร่างกาย' ? 'วิธีเล่น / How to Play' : 'คำแนะนำเพิ่มเติม / Additional Instructions'} <span className="text-red">*</span>
              </label>
              <p className="body-small-regular text-secondary--text">
                {selectedCategory === 'ด้านร่างกาย' 
                  ? 'อธิบายวิธีการเล่น ขั้นตอน หรือคำแนะนำในการทำกิจกรรม'
                  : 'คำแนะนำหรือข้อมูลเพิ่มเติมสำหรับกิจกรรมนี้'
                }
              </p>
              <textarea
                name="content"
                value={formData.content}
                onChange={handleChange}
                placeholder={
                  selectedCategory === 'ด้านร่างกาย'
                    ? 'เช่น ดูคลิปและทำตามท่าทาง, ทำซ้ำ 3 ครั้ง, ฯลฯ'
                    : 'เช่น อ่านโจทย์ให้เข้าใจก่อนตอบ, ใช้เวลาคิดให้ดี, ฯลฯ'
                }
                rows={3}
                required
                className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple resize-none"
              />
            </div>
          )}

          {/* Difficulty & Max Score */}
          <div className="bg-white rounded-lg shadow p-6 space-y-4">
            <div className="grid grid-cols-2 gap-6">
              <div>
                <label className="body-large-semibold text-dark block mb-2">
                  Difficulty Level <span className="text-red">*</span>
                </label>
                <select
                  name="difficulty"
                  value={formData.difficulty}
                  onChange={handleChange}
                  required
                  className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
                >
                  <option value="ง่าย">ง่าย (Easy)</option>
                  <option value="กลาง">กลาง (Medium)</option>
                  <option value="ยาก">ยาก (Hard)</option>
                </select>
              </div>

              <div>
                <label className="body-large-semibold text-dark block mb-2">
                  Maximum Score <span className="text-red">*</span>
                </label>
                <input
                  type="number"
                  name="maxScore"
                  value={formData.maxScore}
                  onChange={handleChange}
                  min="1"
                  required
                  className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
                  />
                  {selectedCategory === 'ด้านคำนวณ' && questions.length > 0 && (
                    <p className="body-xs-regular text-secondary--text mb-2">
                      Changing this will distribute points evenly across all questions
                    </p>
                  )}
              </div>
            </div>
          </div>

          {/* Segment Subtitle - Language only */}
          {selectedCategory === 'ด้านภาษา' && formData.segments && (formData.segments as Segment[]).length > 0 && (
            <div className="bg-white rounded-lg shadow p-6 space-y-4">
              <label className="body-large-semibold text-dark">
                Segment Subtitle
              </label>
              <p className="body-small-regular text-secondary--text">
                Fetched {(formData.segments as Segment[]).length} subtitle segments from video.
              </p>
              <textarea
                value={getSegmentsText()}
                readOnly
                rows={8}
                className="w-full px-4 py-2 border border-gray6 rounded-lg body-small-regular bg-gray--light1 resize-none"
              />
            </div>
          )}

          {/* Questions Editor - Analytical only */}
          {selectedCategory === 'ด้านคำนวณ' && (
            <div className="bg-white rounded-lg shadow p-6 space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <label className="body-large-semibold text-dark">
                    Questions <span className="text-red">*</span>
                  </label>
                  <p className="body-small-regular text-secondary--text">
                    Add questions for analytical thinking activity
                  </p>
                  {questions.length > 0 && (
                    <p className="body-small-regular text-purple mt-1">
                      Total: {questions.reduce((sum, q) => sum + q.score, 0)} points from {questions.length} question{questions.length !== 1 ? 's' : ''}
                    </p>
                  )}
                </div>
                <button
                  type="button"
                  onClick={addQuestion}
                  className="flex items-center gap-2 px-4 py-2 bg-purple text-white rounded-lg body-medium-medium hover:bg-purple--dark"
                >
                  <Plus size={20} />
                  Add Question
                </button>
              </div>

              {questions.length === 0 ? (
                <div className="text-center py-8 text-secondary--text body-medium-regular">
                  No questions added yet. Click "Add Question" to start.
                </div>
              ) : (
                <div className="space-y-4">
                  {questions.map((q, index) => (
                    <div key={q.id} className="border border-gray6 rounded-lg p-4 space-y-3">
                      <div className="flex items-center justify-between pb-2 border-b border-gray4">
                        <div className="flex items-center gap-4">
                          <h4 className="body-medium-semibold">Question {index + 1}</h4>
                          <div className="flex items-center gap-2">
                            <label className="body-small-regular text-secondary--text">Score:</label>
                            <input
                              type="number"
                              value={q.score}
                              onChange={(e) => updateQuestion(q.id, 'score', parseInt(e.target.value) || 0)}
                              min="0"
                              className="w-16 px-2 py-1 border border-gray6 rounded body-small-regular text-center focus:outline-none focus:ring-2 focus:ring-purple"
                            />
                            <span className="body-small-regular text-secondary--text">pts</span>
                          </div>
                        </div>
                        <button
                          type="button"
                          onClick={() => deleteQuestion(q.id)}
                          className="text-red hover:bg-red--light1 p-1 rounded"
                        >
                          <Trash2 size={18} />
                        </button>
                      </div>

                      <div>
                        <label className="body-small-semibold text-dark block mb-1">
                          โจทย์ <span className="text-red">*</span>
                        </label>
                        <textarea
                          value={q.question}
                          onChange={(e) => updateQuestion(q.id, 'question', e.target.value)}
                          placeholder="ใส่โจทย์คำถาม"
                          rows={2}
                          required
                          className="w-full px-3 py-2 border border-gray6 rounded-lg body-small-regular focus:outline-none focus:ring-2 focus:ring-purple resize-none"
                        />
                      </div>

                      <div>
                        <label className="body-small-semibold text-dark block mb-1">
                          คำตอบ <span className="text-red">*</span>
                        </label>
                        <input
                          type="text"
                          value={q.answer}
                          onChange={(e) => updateQuestion(q.id, 'answer', e.target.value)}
                          placeholder="คำตอบที่ถูกต้อง"
                          required
                          className="w-full px-3 py-2 border border-gray6 rounded-lg body-small-regular focus:outline-none focus:ring-2 focus:ring-purple"
                        />
                      </div>

                      <div>
                        <label className="body-small-semibold text-dark block mb-1">
                          คำแนะนำ
                        </label>
                        <textarea
                          value={q.hint}
                          onChange={(e) => updateQuestion(q.id, 'hint', e.target.value)}
                          placeholder="คำแนะนำหรือคำอธิบาย (ถ้ามี)"
                          rows={2}
                          className="w-full px-3 py-2 border border-gray6 rounded-lg body-small-regular focus:outline-none focus:ring-2 focus:ring-purple resize-none"
                        />
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </form>
      )}
    </div>
  );
}
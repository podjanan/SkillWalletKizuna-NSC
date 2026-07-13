// src/app/admin/math-simulation/[id]/page.tsx
'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { ArrowLeft, Send, Trash2, PlusCircle, Brain, RefreshCw, Image as ImageIcon } from 'lucide-react';
import UserProfile from '@/components/UserProfile';

interface Question {
  id: string;
  question: string;
  answer: string;
  solution: string;
  score: number;
  equation?: string;
  imageUrl?: string;
  visualPrompt?: string;
  imageProvider?: string;
  visualData?: Record<string, unknown>;
}

export default function EditMathSimulationPage() {
  const params = useParams();
  const router = useRouter();
  
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [difficulty, setDifficulty] = useState('ง่าย');
  const [maxScore, setMaxScore] = useState(100);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [loading, setLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  const [generatingIndex, setGeneratingIndex] = useState<number | null>(null);

  const handleGenerateQuestion = async (index: number, q: Question) => {
    if (!name || !name.trim()) {
      alert('กรุณากรอก Activity Title (ชื่อกิจกรรม) ก่อนที่จะใช้ AI เจนโจทย์');
      return;
    }
    if (!description || !description.trim()) {
      alert('กรุณากรอก Description (รายละเอียดกิจกรรม) ก่อนที่จะใช้ AI เจนโจทย์');
      return;
    }
    if (!q.equation || !q.equation.trim()) {
      alert('กรุณากรอกสมการในการสร้างโจทย์ของข้อนี้ก่อนที่จะใช้ AI เจนโจทย์ (เช่น 18+2)');
      return;
    }

    setGeneratingIndex(index);
    try {
      const response = await fetch('/api/activities/generate-math-question', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          activityTitle: name,
          activityDescription: description,
          equation: q.equation,
        }),
      });
      const data = await response.json();
      if (data.success) {
        setQuestions(prev => {
          const updated = [...prev];
          updated[index] = {
            ...updated[index],
            question: data.question,
            solution: data.solution,
            answer: data.answer || updated[index].answer
          };
          return updated;
        });
      } else {
        alert(data.error || 'เกิดข้อผิดพลาดในการสร้างโจทย์ด้วย AI');
      }
    } catch (err) {
      console.error(err);
      alert('เกิดข้อผิดพลาดระหว่างเรียกใช้งาน AI');
    } finally {
      setGeneratingIndex(null);
    }
  };

  useEffect(() => {
    if (params.id) {
      fetchActivityDetail();
    }
  }, [params.id]);

  const fetchActivityDetail = async () => {
    try {
      setLoading(true);
      const res = await fetch(`/api/activities/${params.id}`);
      if (res.ok) {
        const data = await res.json();
        setName(data.name || '');
        setDescription(data.description || '');
        setDifficulty(data.difficulty || 'ง่าย');
        setMaxScore(data.maxScore || 100);
        
        if (data.segments) {
          const parsed = typeof data.segments === 'string'
            ? JSON.parse(data.segments)
            : data.segments;
          setQuestions(parsed || []);
        }
      } else {
        alert('Activity not found');
        router.push('/admin/math-simulation');
      }
    } catch (err) {
      console.error('Failed to load activity details:', err);
    } finally {
      setLoading(false);
    }
  };

  const addQuestion = () => {
    setQuestions(prev => [
      ...prev,
      {
        id: (prev.length + 1).toString(),
        question: '',
        answer: '',
        solution: '',
        score: 10,
      }
    ]);
  };

  const deleteQuestion = (index: number) => {
    const updated = questions.filter((_, i) => i !== index).map((q, idx) => ({
      ...q,
      id: (idx + 1).toString()
    }));
    setQuestions(updated);
  };

  const updateQuestion = (index: number, key: keyof Question, value: any) => {
    const updated = [...questions];
    updated[index] = {
      ...updated[index],
      [key]: value
    };
    setQuestions(updated);
  };

  const regenerateQuestionImage = async (index: number, q: Question) => {
    try {
      const loader = document.getElementById(`regenerate-loader-${index}`);
      if (loader) loader.style.display = 'inline-block';

      const response = await fetch('/api/activities/generate-math-images', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ questions: [q] })
      });
      const result = await response.json();
      if (result.success && result.segments && result.segments[0]) {
        setQuestions((previous) => {
          const updated = [...previous];
          updated[index] = { ...updated[index], ...result.segments[0] };
          return updated;
        });
        alert(`Regenerated image for Question #${q.id} successfully!`);
      } else {
        alert('Failed to regenerate image.');
      }
    } catch (err) {
      console.error(err);
      alert('An error occurred while generating the image.');
    } finally {
      const loader = document.getElementById(`regenerate-loader-${index}`);
      if (loader) loader.style.display = 'none';
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!name.trim()) return alert('Please enter activity title');
    if (!description.trim()) return alert('Please enter activity description');
    if (questions.length === 0) return alert('Please add at least one question');

    setIsSaving(true);

    try {
      // Step 1: Pre-generate images for questions that don't have them yet
      const missingQuestions = questions.filter(q => !q.imageUrl);
      let updatedSegments = [...questions];
      
      if (missingQuestions.length > 0) {
        const genResponse = await fetch('/api/activities/generate-math-images', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ questions: missingQuestions }),
        });
        const genResult = await genResponse.json();
        if (genResult.success && genResult.segments) {
          updatedSegments = questions.map(q => {
            const found = genResult.segments.find((item: any) => item.id === q.id);
            return found ? found : q;
          });
        }
      }

      // Step 2: Save to database using PATCH /api/activities/${id}
      const dataToSave = {
        name,
        category: 'ด้านคำนวณ',
        description,
        difficulty,
        maxScore,
        content: 'math_simulation',
        segments: updatedSegments,
        videoUrl: '',
      };

      const res = await fetch(`/api/activities/${params.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(dataToSave),
      });

      if (res.ok) {
        alert('Activity updated successfully!');
        router.push('/admin/math-simulation');
      } else {
        alert('Failed to update activity template');
      }
    } catch (err) {
      console.error(err);
      alert('An error occurred during save');
    } finally {
      setIsSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex-1 bg-gray--light1 p-8 flex items-center justify-center">
        <div className="text-secondary--text body-large-medium">Loading activity details...</div>
      </div>
    );
  }

  return (
    <div className="flex-1 bg-gray--light1 p-8 overflow-y-auto">
      {/* Top bar */}
      <div className="flex justify-between items-center mb-8">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.push('/admin/math-simulation')}
            className="p-2 bg-white rounded-lg border border-gray4 hover:bg-gray--light2 text-secondary--text"
          >
            <ArrowLeft size={20} />
          </button>
          <div>
            <h1 className="heading-h3 text-dark flex items-center gap-2">
              <Brain className="text-purple" size={32} />
              Edit Math Simulation Template
            </h1>
            <p className="body-medium-regular text-secondary--text mt-1">
              แก้ไขข้อมูลและรูปภาพ AI ของเกมคำนวณจำลองของแอดมิน
            </p>
          </div>
        </div>
        <UserProfile />
      </div>

      <form onSubmit={handleSubmit} className="space-y-6 max-w-4xl">
        {/* Core settings */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray4 p-6 space-y-4">
          <h3 className="body-large-semibold text-dark">Activity Information</h3>
          
          <div>
            <label className="body-small-semibold text-dark block mb-2">Activity Title *</label>
            <input
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
            />
          </div>

          <div>
            <label className="body-small-semibold text-dark block mb-2">Description *</label>
            <textarea
              required
              rows={3}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple resize-none"
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="body-small-semibold text-dark block mb-2">Difficulty *</label>
              <select
                value={difficulty}
                onChange={(e) => setDifficulty(e.target.value)}
                className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple bg-white"
              >
                <option value="ง่าย">ง่าย (Easy)</option>
                <option value="กลาง">กลาง (Medium)</option>
                <option value="ยาก">ยาก (Hard)</option>
              </select>
            </div>
            <div>
              <label className="body-small-semibold text-dark block mb-2">Maximum Points *</label>
              <input
                type="number"
                min="1"
                value={maxScore}
                onChange={(e) => setMaxScore(parseInt(e.target.value) || 100)}
                className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
              />
            </div>
          </div>
        </div>

        {/* Questions editor */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray4 p-6 space-y-4">
          <div className="flex justify-between items-center">
            <div>
              <h3 className="body-large-semibold text-dark">รายการโจทย์คำถาม</h3>
              <p className="body-small-regular text-secondary--text">
                จัดการโจทย์และภาพจำลองการ์ตูน AI
              </p>
            </div>
            <button
              type="button"
              onClick={addQuestion}
              className="flex items-center gap-1.5 px-4 py-2 bg-purple text-white rounded-lg body-medium-medium hover:bg-purple--dark"
            >
              <PlusCircle size={18} />
              เพิ่มข้อคำถาม
            </button>
          </div>

          {questions.length === 0 ? (
            <div className="text-center py-10 border border-dashed border-gray6 rounded-xl text-secondary--text body-medium-regular">
              ยังไม่มีข้อคำถามในขณะนี้ กด "เพิ่มข้อคำถาม" เพื่อเริ่มเขียนโจทย์
            </div>
          ) : (
            <div className="space-y-6">
              {questions.map((q, index) => (
                <div key={index} className="border border-gray6 rounded-xl p-4 bg-gray--light2 space-y-3 relative">
                  <div className="flex justify-between items-center pb-2 border-b border-gray4">
                    <span className="body-medium-bold text-purple">ข้อที่ {q.id}</span>
                    <button
                      type="button"
                      onClick={() => deleteQuestion(index)}
                      className="p-1 hover:bg-red--light6 rounded text-red"
                    >
                      <Trash2 size={18} />
                    </button>
                  </div>

                  <div className="flex flex-col md:flex-row md:items-end gap-3 p-3 bg-purple--light5 border border-purple--light4 rounded-lg mb-3">
                    <div className="flex-1">
                      <label className="body-xs-semibold text-purple block mb-1">สมการในการสร้างโจทย์ด้วย AI (เช่น 18+2 หรือ 5*4)</label>
                      <input
                        type="text"
                        placeholder="e.g. 18+2"
                        value={q.equation || ''}
                        onChange={(e) => updateQuestion(index, 'equation', e.target.value)}
                        className="w-full px-3 py-1.5 border border-purple--light3 rounded-lg body-small-regular focus:outline-none focus:ring-2 focus:ring-purple bg-white"
                      />
                    </div>
                    <button
                      type="button"
                      onClick={() => handleGenerateQuestion(index, q)}
                      disabled={generatingIndex === index}
                      className="px-4 py-1.5 bg-purple text-white rounded-lg body-small-medium hover:bg-purple--dark disabled:bg-purple--light3 flex items-center gap-1.5 h-[38px] justify-center min-w-[120px]"
                    >
                      {generatingIndex === index ? (
                        <>
                          <RefreshCw size={14} className="animate-spin" />
                          กำลังสร้าง...
                        </>
                      ) : (
                        <>
                          <Brain size={14} />
                          เจนโจทย์ด้วย AI
                        </>
                      )}
                    </button>
                  </div>

                  <div>
                    <label className="body-xs-semibold text-dark block mb-1">โจทย์คำถามวิเคราะห์ *</label>
                    <textarea
                      required
                      placeholder="e.g. มีนมรสจืด 12 กล่อง และมีนมรสช็อกโกแลต 8 กล่อง..."
                      rows={2}
                      value={q.question}
                      onChange={(e) => updateQuestion(index, 'question', e.target.value)}
                      className="w-full px-3 py-2 border border-gray6 rounded-lg body-small-regular focus:outline-none focus:ring-2 focus:ring-purple resize-none bg-white"
                    />
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="body-xs-semibold text-dark block mb-1">คำตอบ *</label>
                      <input
                        type="text"
                        required
                        value={q.answer}
                        onChange={(e) => updateQuestion(index, 'answer', e.target.value)}
                        className="w-full px-3 py-2 border border-gray6 rounded-lg body-small-regular focus:outline-none focus:ring-2 focus:ring-purple bg-white"
                      />
                    </div>
                    <div>
                      <label className="body-xs-semibold text-dark block mb-1">คะแนน *</label>
                      <input
                        type="number"
                        min="1"
                        value={q.score}
                        onChange={(e) => updateQuestion(index, 'score', parseInt(e.target.value) || 10)}
                        className="w-full px-3 py-2 border border-gray6 rounded-lg body-small-regular focus:outline-none focus:ring-2 focus:ring-purple bg-white"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="body-xs-semibold text-dark block mb-1">คำแนะนำ / อธิบายเฉลย</label>
                    <textarea
                      rows={2}
                      value={q.solution}
                      onChange={(e) => updateQuestion(index, 'solution', e.target.value)}
                      className="w-full px-3 py-2 border border-gray6 rounded-lg body-small-regular focus:outline-none focus:ring-2 focus:ring-purple resize-none bg-white"
                    />
                  </div>

                  {/* Image preview block */}
                  <div className="mt-3 p-3 bg-white border border-gray4 rounded-lg flex flex-col md:flex-row items-center gap-4">
                    <div className="w-full md:w-48 h-32 bg-gray2 rounded-lg overflow-hidden flex items-center justify-center border border-gray4 relative">
                      {q.imageUrl ? (
                        <img
                          src={q.imageUrl}
                          alt={`Question ${q.id} illustration`}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <span className="body-xs-regular text-secondary--text text-center px-2">
                          ไม่มีรูปภาพประกอบ (จะสร้างอัตโนมัติเมื่อกดบันทึก)
                        </span>
                      )}
                    </div>
                    <div className="flex-1 space-y-2">
                      <div className="flex items-center gap-2">
                        <ImageIcon size={16} className="text-purple" />
                        <h5 className="body-small-semibold text-dark">รูปภาพสถานการณ์จำลอง (AI Illustration)</h5>
                      </div>
                      <p className="body-xs-regular text-secondary--text">
                        ภาพประกอบเด็กเรียนรู้วิเคราะห์คณิตวาดโดย AI ตามโจทย์เลขข้อนี้
                      </p>
                      {q.imageUrl && (
                        <button
                          type="button"
                          onClick={() => regenerateQuestionImage(index, q)}
                          className="flex items-center gap-1.5 px-3 py-1.5 border border-purple text-purple rounded-lg body-xs-medium hover:bg-purple--light5"
                        >
                          <RefreshCw size={12} id={`regenerate-loader-${index}`} className="animate-spin hidden" />
                          สร้างรูปภาพใหม่ด้วย AI (Regenerate Image)
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Submit */}
        <div className="flex justify-end gap-4">
          <button
            type="button"
            onClick={() => router.push('/admin/math-simulation')}
            className="px-6 py-2 border border-gray6 rounded-lg body-medium-medium text-secondary--text hover:bg-white"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={isSaving}
            className="flex items-center gap-2 px-6 py-2 bg-purple text-white rounded-lg body-medium-medium hover:bg-purple--dark disabled:opacity-50"
          >
            <Send size={18} />
            {isSaving ? 'กำลังบันทึกและตรวจเช็กภาพ AI...' : 'บันทึกการแก้ไข'}
          </button>
        </div>
      </form>
    </div>
  );
}

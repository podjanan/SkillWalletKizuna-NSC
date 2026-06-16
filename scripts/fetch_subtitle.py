# scripts/fetch_subtitle.py

import sys
import json
import re
import requests 
from bs4 import BeautifulSoup 
from youtube_transcript_api import YouTubeTranscriptApi 

# *** 1. การแก้ไข Encoding: บังคับให้ stdout/stderr ใช้ UTF-8 ***
# การแก้ไขนี้ช่วยแก้ปัญหาตัวอักษรผิดเพี้ยน ('' แทน ''' )
try:
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')
except AttributeError:
    pass 

# ตรวจสอบว่ามี Argument เข้ามาหรือไม่ (คือ Video URL)
if len(sys.argv) < 2:
    print(json.dumps({"error": "No video URL provided as argument."}))
    sys.exit(1) 

video_url = sys.argv[1] # รับ Argument ตัวแรก (Video URL)

def extract_youtube_id(url):
    """ดึง YouTube video ID"""
    # รองรับทั้ง YouTube และ TikTok ID (แต่ Subtitle ทำงานเฉพาะ YouTube)
    match = re.search(r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})', url)
    if match:
        return match.group(1)
        
    # ลองหา TikTok ID (ถ้าเป็นไปได้)
    tiktok_match = re.search(r'tiktok\.com\/(@[\w.]+\/video\/|v\/|t\/)(\d+)', url)
    if tiktok_match:
        return tiktok_match.group(2) # ส่ง ID TikTok (ตัวเลข 19 หลัก)

    return None

# *** 2. การดึง Metadata ด้วย Web Scraping (แทน Pytube) ***
def scrape_metadata(video_url):
    """Scrapes Title and Description using BeautifulSoup and og:tags."""
    try:
        # ใช้ requests เพื่อดึง HTML ของหน้า YouTube/TikTok
        # เพิ่ม User-Agent เพื่อปลอมเป็น Browser จริง
        headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}
        response = requests.get(video_url, headers=headers, timeout=15) # เพิ่ม Timeout
        response.raise_for_status() # โยน HTTPError ถ้าสถานะไม่ OK
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # ค้นหา Title จาก og:title meta tag
        title_tag = soup.find('meta', property='og:title')
        title = title_tag['content'] if title_tag else "[Scrape Failed] Title not found"

        # ค้นหา Description จาก og:description meta tag
        desc_tag = soup.find('meta', property='og:description')
        description = desc_tag['content'] if desc_tag else "[Scrape Failed] Description not found"

        return {
            'title': title.strip(),
            'description': description.strip()
        }
    except Exception as e:
        # หาก Scraping ล้มเหลวด้วยสาเหตุใดก็ตาม
        return {
            'title': f"[Auto Fetch Failed] Please enter Title manually.",
            'description': f"Metadata fetch failed (Scraping Error: {str(e)[:50]}...). Please enter description manually."
        }

def get_transcript_segments(video_url):
    """ดึง Subtitle และแปลงเป็น Segment Format ที่ต้องการ"""
    video_id = extract_youtube_id(video_url)
    
    # 1. ดึง Metadata ด้วย Scraping
    metadata = scrape_metadata(video_url)

    # Note: Subtitle ดึงได้เฉพาะ YouTube (ID 11 ตัว)
    if not video_id or len(video_id) != 11:
         # ถ้าไม่ใช่ YouTube ID ให้ข้ามการดึง Subtitle
         return {
            'videoId': video_id,
            'title': metadata['title'],
            'description': metadata['description'],
            'segments': [] # ส่ง Array ว่างสำหรับกิจกรรมอื่น
         }

    # 2. Fetch Transcript (ส่วนนี้ใช้ youtube-transcript-api)
    transcript_data = []
    try:
        ytt_api = YouTubeTranscriptApi() 
        fetched_transcript = ytt_api.fetch(
            video_id, 
            languages=['en', 'a.en', 'en-US']
        )
        transcript_data = fetched_transcript.to_raw_data() 

    except Exception as e:
        # หากเกิดข้อผิดพลาดในการดึง Subtitle
        raise ValueError(f"Could not retrieve any transcript for this video. Details: {e}")
        
    if not transcript_data:
        raise ValueError("No transcript available for this video.")

    segments = []
    
    # 3. Process and convert to Segment Format
    for i, item in enumerate(transcript_data):
        start = item['start']
        duration = item['duration']
        
        next_item = transcript_data[i + 1] if i + 1 < len(transcript_data) else None
        
        end = start + duration
        
        if next_item and next_item['start'] > start: 
            end = next_item['start']
        
        segments.append({
            'start': round(start, 1),
            'end': round(end, 1),
            'text': item['text'].replace('\n', ' ').strip()
        })
        
    # 4. ส่ง Metadata ที่ดึงมาจริง (หรือ Placeholder) กลับไป
    return {
        'videoId': video_id,
        'title': metadata['title'],
        'description': metadata['description'],
        'segments': segments
    }

try:
    result = get_transcript_segments(video_url)
    # **สำคัญ:** พิมพ์ผลลัพธ์ JSON ออกทาง stdout
    print(json.dumps(result, ensure_ascii=False)) 
except Exception as e:
    # พิมพ์ Error JSON ออกทาง stdout
    print(json.dumps({"error": f"Python Processing Error: {str(e)}"}))
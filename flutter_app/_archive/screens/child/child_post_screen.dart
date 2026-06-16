import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChildPostScreen extends StatelessWidget {
  const ChildPostScreen({super.key});

  // --- Theme Colors ---
  static const creamBg = Color(0xFFFFF5CD); // สีพื้นหลังครีม
  static const blueTitle = Color(0xFF4DA9FF); // สีฟ้าหัวข้อ

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg, // 1. พื้นหลังสีครีมทั้งหน้า
      body: SafeArea(
        child: Column(
          children: [
            // --- 2. Custom Header (ส่วนหัวทำเอง) ---
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ปุ่มย้อนกลับ (ลูกศร)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        size: 30, color: Colors.black87),
                  ),

                  // ชื่อหัวข้อ (MY GALLERY)
                  Text(
                    'MY GALLERY',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 32, // ขนาดตัวหนังสือ
                      color: blueTitle,
                      letterSpacing: 1.0,
                    ),
                  ),

                  // กล่องเปล่าด้านขวา (เพื่อให้ชื่ออยู่ตรงกลางพอดี)
                  const SizedBox(width: 30),
                ],
              ),
            ),

            // --- 3. Body (ส่วนเนื้อหาตรงกลาง) ---
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // รูปไอคอน Gallery (ทำให้จางลงนิดหน่อย เพื่อสื่อว่ายังไม่มีรูป)
                    Opacity(
                      opacity: 0.5,
                      child: Image.asset(
                        'assets/icons/gallery.png', // ใช้รูปเดียวกับหน้า Profile
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                        // ถ้าหารูปไม่เจอ ให้โชว์ไอคอนแทน
                        errorBuilder: (_, __, ___) => const Icon(Icons.image,
                            size: 100, color: Colors.grey),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ข้อความแจ้งเตือน
                    Text(
                      "NO POSTS YET",
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 24,
                        color: Colors.grey, // สีเทา
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

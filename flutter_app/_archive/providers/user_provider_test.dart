// // test/user_provider_test.dart

// import 'package:flutter_test/flutter_test.dart';
// import 'package:skill_wallet_kizuna/providers/user_provider.dart'; // แก้ 'your_app' ให้เป็นชื่อโปรเจกต์ของคุณ

// void main() {
//   // สร้าง Group เพื่อจัดกลุ่มการทดสอบ
//   group('UserProvider Unit Tests', () {
//     late UserProvider userProvider;

//     // รันก่อนทุกการทดสอบ (test) ใน Group
//     setUp(() {
//       userProvider = UserProvider();
//     });

//     // TEST 1: ทดสอบสถานะเริ่มต้น
//     test('Initial state: currentUser is null and isAuthenticated is false', () {
//       expect(userProvider.currentUser, isNull);
//       expect(userProvider.isAuthenticated, isFalse);
//       expect(userProvider.isLoading, isFalse);
//     });

//     // TEST 2: ทดสอบการ Login ด้วย ID ที่กำหนด (PR2)
//     test('Login sets currentUser to ID: PR2 and isAuthenticated to true',
//         () async {
//       // ********* ส่วนที่ระบุค่าจำลอง *********
//       const testEmail = 'pr2@test.com';
//       const testPassword = 'password123';
//       const expectedId = 'PR2';
//       const expectedName = 'Test User PR2';
//       // ***************************************

//       // เนื่องจาก method login เป็น async เราต้องรอให้เสร็จ
//       await userProvider.login(testEmail, testPassword);

//       // การตรวจสอบ (Assertion)
//       expect(userProvider.isLoading, isFalse);
//       expect(userProvider.isAuthenticated, isTrue);
//       expect(userProvider.currentUser, isNotNull);

//       // ตรวจสอบค่า ID และ Name ที่จำลองไว้
//       expect(userProvider.currentUser!.id, expectedId);
//       expect(userProvider.currentUser!.name, expectedName);

//       // (หมายเหตุ: ในโค้ดจริง คุณต้องปรับ logic ใน user_provider.dart ให้สร้าง User Object ด้วย ID ที่เหมาะสม)
//     });

//     // TEST 3: ทดสอบการ Update Username ด้วย ID เดิม (CH2)
//     test('UpdateUserName successfully changes name for current user (ID: CH2)',
//         () async {
//       // ********* ส่วนที่ระบุค่าจำลอง *********
//       const initialId = 'CH2';
//       const initialName = 'Initial Name CH2';
//       const newName = 'Chayut CH2 Update';
//       // ***************************************

//       // 1. จำลองการ Login (ตั้งค่าสถานะเริ่มต้น)
//       // ******* (ปรับเปลี่ยนให้ตรงกับ logic การ login ของคุณ) *******
//       userProvider.login(initialId, 'pass');
//       userProvider.updateUserName(initialName); // ให้มีค่าเริ่มต้น
//       // ************************************************************

//       // 2. ตรวจสอบว่ามีการเรียก notifyListeners() หรือไม่
//       // เราสามารถใช้ expectLater กับ `userProvider` เพื่อตรวจสอบการแจ้งเตือน
//       // (นี่เป็นรูปแบบที่ซับซ้อนขึ้น สามารถละเว้นได้ถ้าไม่ต้องการทดสอบ notifyListeners)

//       // 3. เรียก method ที่ต้องการทดสอบ
//       userProvider.updateUserName(newName);

//       // 4. การตรวจสอบ (Assertion)
//       expect(userProvider.currentUser!.name, newName);
//       expect(userProvider.currentUser!.id, initialId); // ID ต้องไม่เปลี่ยน
//     });

//     // TEST 4: ทดสอบการออกจากระบบ
//     test('Logout resets currentUser to null and isAuthenticated to false',
//         () async {
//       // 1. ตั้งค่าสถานะเริ่มต้นให้มีการ Login ก่อน
//       await userProvider.login('test@logout.com', 'password');
//       expect(userProvider.isAuthenticated, isTrue);

//       // 2. เรียก method ที่ต้องการทดสอบ
//       userProvider.logout();

//       // 3. การตรวจสอบ (Assertion)
//       expect(userProvider.currentUser, isNull);
//       expect(userProvider.isAuthenticated, isFalse);
//     });
//   });
// }

// // (หมายเหตุ: โค้ดในไฟล์ user_provider.dart ที่ใช้ใน Test 2 และ 3 ต้องถูกปรับให้สร้าง User Object ที่มี id 'PR2' หรือ 'CH2' ได้
// // เช่น อาจต้องสร้าง MockService หรือปรับ logic การ login ให้ return User ตามที่ต้องการ)

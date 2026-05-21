# Mobile-App-Toppan

## 📌 Description
โปรเจกต์นี้เป็นระบบใบผ่านเข้า-ออกโรงงาน โดยตัวโปรแกรมถูกพัฒนาด้วย Flutter (Mobile App) และมีการใช้งานฐานข้อมูลตัวเดียวกันกับ `visitor-WebApp (ระบบแจ้งเข้า)`  
ิFrontend - Flutter(Dart)
Backend - ExpressJS (Javascript)

--- 

## 📁 Requirement
`Dart 3.5.4 (Flutter 3.24.5)`
`Javascript`
`Android Studio (SDK)`
### เพิ่มเติม (For Testing)
- Android Studio (Emulator) 
- Real Device (Mobile, Tablet)

---

## 🚀 Setup Project

### 1. Clone repository

### 2. COPY ไฟล์ env, config และ docker ที่ไดรฟ์ F software development ของโปรแกรมเอาไปไว้ตามนี้
`.env.development`  -> mobile-app-toppan\backend  
`.env.production`  -> mobile-app-toppan\backend  
`config.js`  -> mobile-app-toppan\backend\src\config  
`Dockerfile`  -> mobile-app-toppan  
`docker-compose.yml` -> mobile-app-toppan  
`firebase` -> mobile-app-toppan\backend\src  

### 3. Install Package
```bash
 cd backned
 npm install
```

### 4. วิธี run โปรแกรม (backend)
```bash
 cd backned/src
```
`Development` envelopment:
```bash
 npm npm run dev
```
`Prodcution` envelopment:
```bash
 npm npm run start
```

### 5. วิธี run โปรแกรม (frontend)
เชื่อมต่อ Device ที่ต้องการจากนั้นรันคำสั่ง  

`Development` envelopment:
```bash
 flutter run
```
`Prodcution` envelopment:
```bash
 flutter run --release
```

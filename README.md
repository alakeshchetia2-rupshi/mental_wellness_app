# MindHeal Pro 🧠✨

A full-stack Flutter mental wellness application built with Firebase.

🌐 Live Demo: https://mindheal-pro.web.app

---

## 🚀 Overview

MindHeal Pro is a cross-platform mental wellness application designed to help users track mood patterns, maintain journaling habits, and analyze emotional trends over time.

The app is deployed to Firebase Hosting and uses Firebase Authentication and Cloud Firestore for backend services.

---

## 🏗️ Architecture

### Frontend
- Flutter (Material Design)
- Provider for state management
- Responsive UI (Web + Desktop)

### Backend
- Firebase Authentication (Email & Password)
- Cloud Firestore (NoSQL document database)
- Firebase Hosting (Production deployment)

### Firestore Structure

Each user’s data is isolated under their unique UID for security and scalability.

---

## 🔐 Authentication

- Email & Password authentication
- Secure user session management via FirebaseAuth
- Per-user data isolation using UID-based document paths

---

## 📊 Features

### Mood Tracking
- Log daily mood using emoji-based selection
- Store mood value, label, timestamp, and metadata
- Real-time Firestore persistence

### Mood Insights
- Average mood calculation
- Most common mood detection
- Best day identification
- Trend analysis (Improving / Declining / Stable)

### Streak System
- Tracks daily logging consistency
- Encourages habit formation

### User Experience
- Clean Material UI
- Date selection support
- Responsive layout for Web

---

## 🛠 Tech Stack

- Flutter 3.x
- Dart 3.x
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Provider
- Shared Preferences

---

## 📦 Installation

1. Clone repository
2. Run:

---

## 🔒 Security

- Data stored per-user using UID
- Firestore document-based access structure
- Firebase Authentication enforced before data operations

---

## 📈 Future Improvements

- Firestore security rule hardening
- Proper server-side delete operations
- Analytics integration
- CI/CD pipeline
- Enhanced data visualization charts

---

## 👨‍💻 Author

Alakesh Chetia  
BTech Student | Flutter & Firebase Developer
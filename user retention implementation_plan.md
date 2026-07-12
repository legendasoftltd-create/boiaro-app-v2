# 🚀 Boiaro App — User Retention Feature Implementation Plan

> **লক্ষ্য:** DAU 50–100 → 500–800 | Retention Rate 4% → 30%+
> 
> **বর্তমান অবস্থা:** Streak API, Reading Progress, Presence Tracking, Wallet — সব backend আছে। শুধু UI ও engagement loop তৈরি করতে হবে।

---

## 📦 ফিচার সমূহ (8টি মডিউল)

---

## MODULE 1 — 🔔 Personalized Push Notification

### উদ্দেশ্য
Generic push notification বন্ধ করে user-specific, action-triggering notification পাঠানো।

### Notification Types

| # | Trigger | Message | কখন পাঠাবে |
|---|---------|---------|------------|
| 1 | **Inactive 3 days** | 📖 "আপনি ৩ দিন পড়েননি! '[Book Name]' এ আবার ফিরে আসুন" | প্রতিদিন রাত ৭টায় check |
| 2 | **Streak at risk** | 🔥 "আপনার streak আজ শেষ হবে! মাত্র ৫ মিনিট পড়ুন" | রাত ৮টায়, যারা আজ open করেনি |
| 3 | **New book in fav category** | 📚 "নতুন বই: '[Book Name]' — আপনার পছন্দের category" | নতুন বই publish হলেই |
| 4 | **Trending book** | ⭐ "সবাই পড়ছে: '[Trending Book]' — আপনিও পড়ুন!" | সাপ্তাহিক, রবিবার সকাল |
| 5 | **Favorite author new book** | ❤️ "[Author Name] এর নতুন বই এসেছে!" | নতুন বই publish হলেই |
| 6 | **Weekly reading report** | 📊 "এই সপ্তাহে আপনি [X] মিনিট পড়েছেন! আপনার রিপোর্ট দেখুন" | প্রতি রবিবার |
| 7 | **Personalized recommendation** | 📖 "আপনার মতো পাঠকরা '[Book]' পছন্দ করেছেন" | সাপ্তাহিক |
| 8 | **Special offer** | 🎁 "[Book Name] — আজ মাত্র ৳[X]! সীমিত সময়ের অফার" | অফার চলাকালীন |

### Technical Architecture

```
Flutter App (Token Registration)
        ↓
Firebase FCM (Token Store)
        ↓
Backend/Cloud Function (Scheduler + Personalizer)
        ↓
Firestore (user_last_read, user_preferences, user_streak)
```

### Backend Requirements (API Endpoints needed)
```
POST /api/notifications/send-inactive-users
POST /api/notifications/send-streak-at-risk  
POST /api/notifications/send-new-book-in-category
POST /api/notifications/send-weekly-report
```

### Flutter Implementation
```dart
// services/smart_notification_service.dart
class SmartNotificationService {
  // Store user's last read book for personalized notification
  static Future<void> saveLastReadBook({
    required String bookId,
    required String bookName,
    required String category,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_read_book_id', bookId);
    await prefs.setString('last_read_book_name', bookName);
    await prefs.setString('last_read_category', category);
    await prefs.setString('last_read_time', DateTime.now().toIso8601String());
    // Sync to backend
    await EbookGroup.updateUserReadingMetaCall(
      bookId: bookId, category: category
    );
  }
}
```

### Placement
- `main.dart` → `initState()` এ notification handler already আছে ✅
- Backend scheduler: Firebase Cloud Functions (Cron Jobs)

---

## MODULE 2 — 🏆 Reading Badges & Achievements

### Badges List

| Badge | Icon | Condition | Coin Reward | Shareable |
|-------|------|-----------|-------------|-----------|
| 🥉 **প্রথম বই** | Bronze Medal | ১টি বই ১০০% সম্পন্ন | 50 Coin | ✅ |
| 🥈 **পাঠক** | Silver Medal | ৫টি বই সম্পন্ন | 150 Coin | ✅ |
| 🥇 **বই পোকা** | Gold Medal | ১০টি বই সম্পন্ন | 300 Coin | ✅ |
| 🔥 **৭ দিনের ধারা** | Flame | ৭ দিন consecutive পড়া | 100 Coin | ✅ |
| 🌟 **৩০ দিনের যোদ্ধা** | Star | ৩০ দিন consecutive | 500 Coin | ✅ |
| 🎧 **শ্রোতা** | Headphones | ৩টি audiobook সম্পন্ন | 100 Coin | ✅ |
| ⭐ **রিভিউ লেখক** | Star | ৫টি রিভিউ দেওয়া | 75 Coin | ✅ |
| 👑 **VIP পাঠক** | Crown | Subscription active ৩০ দিন | 200 Coin | ✅ |

### Shareable Badge Image Feature
- Badge unlock হলে একটি **সুন্দর animated bottom sheet** খুলবে
- "Share করুন" বাটনে ক্লিক করলে badge image generate হবে
- Image-এ থাকবে: Badge icon + user নাম + অর্জনের বর্ণনা + Boiaro logo
- **Share করা যাবে:** WhatsApp, Facebook, Instagram, Download

### Placement
```
ProfilePage
  └── "আমার অর্জন" section (নিচে)
      ├── Earned badges (full color)
      └── Locked badges (grayscale + lock icon)

BookReadPage
  └── On 100% completion → Achievement popup
```

### Flutter Structure
```
lib/pages/profile_screens/achievements_page/
    ├── achievements_page_widget.dart
    └── badge_card_widget.dart

lib/services/achievement_service.dart
lib/widgets/achievement_unlock_sheet.dart
lib/widgets/badge_share_card.dart  ← screenshot_widget দিয়ে image generate
```

### Backend Requirements
```
GET  /api/user/achievements        → user এর earned badges
POST /api/user/achievements/claim  → badge claim + coin credit
GET  /api/badges/all               → সব badge এর list
```

---

## MODULE 3 — 📊 Weekly Reading Report

### কী থাকবে Report-এ

```
┌─────────────────────────────────────┐
│   📚 এই সপ্তাহের পাঠ রিপোর্ট         │
│   ১ জুলাই – ৭ জুলাই ২০২৬            │
├─────────────────────────────────────┤
│   ⏱️ মোট পড়ার সময়: ৩ ঘণ্টা ২০ মিনিট │
│   📖 বই পড়েছেন: ২টি                  │
│   🎧 অডিওবুক শুনেছেন: ১টি            │
│   🔥 Streak: ৫ দিন                   │
│   ⭐ Rank: Top 15%                   │
├─────────────────────────────────────┤
│   Most Read: "[Book Name]"           │
│   ████████████░░ 78%                 │
├─────────────────────────────────────┤
│   [Share করুন] [পরের সপ্তাহের লক্ষ্য] │
└─────────────────────────────────────┘
```

### Social Sharing
- "Share করুন" বাটনে tap করলে report এর screenshot image generate হবে
- Image-এ Boiaro watermark + user নাম থাকবে
- WhatsApp, Facebook, Instagram, Twitter-এ share করা যাবে

### Placement
```
ProfilePage → "আমার রিপোর্ট" tab/card
Notification → প্রতি রবিবার সকাল ১০টায় push
Library Page → "পড়ার ইতিহাস" section
```

### Flutter Structure
```
lib/pages/profile_screens/reading_report_page/
    ├── reading_report_page_widget.dart
    └── weekly_stat_card.dart

lib/widgets/shareable_report_card.dart  ← screenshot + share
```

### Backend Requirements
```
GET /api/user/reading-report?week=current  → weekly stats
GET /api/user/reading-report?week=last     → last week stats
GET /api/user/reading-report/history       → all weeks
```

---

## MODULE 4 — 🎯 Personalized Home Recommendations

### Home Page New Structure
```
┌──────────────────────────────────────┐
│ 🔥 5 দিন Streak | ⏱️ আজ: 20/30 min   │  ← Sticky top bar
├──────────────────────────────────────┤
│ ▶ আবার পড়ুন: [Cover + Progress Bar] │  ← Continue Reading (MUST)
├──────────────────────────────────────┤
│ 🎯 আপনার জন্য বাছাই করা বই           │  ← NEW: Personalized
├──────────────────────────────────────┤
│ ❤️ প্রিয় লেখকের নতুন বই              │  ← NEW: Fav Author Update  
├──────────────────────────────────────┤
│ 🔥 Trending | 🆕 নতুন বই              │  ← Existing sections
└──────────────────────────────────────┘
```

### Recommendation Algorithm
1. User এর শেষ ৫টি পড়া বইয়ের category বের করো
2. সেই category থেকে unpurchased/unread বই দেখাও
3. Follow করা author এর নতুন বই দেখাও
4. Server-side: collaborative filtering (পরে)

### Backend Requirements
```
GET /api/recommendations/for-user?userId=X  → personalized books
GET /api/recommendations/based-on-book?bookId=X  → similar books
```

---

## MODULE 5 — 🎁 Daily Login Streak Reward (7-Day Gift Dialog)

### 7-Day Reward Structure

| Day | Reward | Value |
|-----|--------|-------|
| Day 1 | 10 Coin | ২০ টাকা সমতুল্য |
| Day 2 | 20 Coin | ৪০ টাকা সমতুল্য |
| Day 3 | 1 Free Ebook | বাজার মূল্য ১৫০–৩০০ টাকা |
| Day 4 | 30 Coin | ৬০ টাকা সমতুল্য |
| Day 5 | 1 Free Audiobook Chapter | |
| Day 6 | 50 Coin | ১০০ টাকা সমতুল্য |
| Day 7 | 100 Coin + Premium Badge | বিশেষ পুরস্কার! |

### Dialog UI Design
```
┌──────────────────────────────────────┐
│        🎁 দৈনিক পুরস্কার             │
│   ধন্যবাদ! আজ আপনার [X] দিন!        │
├──────────────────────────────────────┤
│  [D1] [D2] [D3] [D4] [D5] [D6] [D7] │
│   ✓    ✓    ✓   TODAY ░    ░    ░   │
├──────────────────────────────────────┤
│         🎉 আজকের পুরস্কার             │
│           [Coin Icon] 30 Coin         │
│                                      │
│      [✅ দাবি করুন (Claim)]          │
└──────────────────────────────────────┘
```

### Logic
- App open হলে check: আজ reward claim করা হয়েছে কি?
- না হলে: `showDialog()` দিয়ে reward dialog দেখাও
- Backend streak data ব্যবহার করে (ইতিমধ্যে `updateStreakCall` আছে ✅)

### Placement
- App launch → `main.dart` এর `initState()` এ check
- Dialog auto-show একবার প্রতিদিন

### Flutter Structure
```
lib/widgets/daily_reward_dialog.dart
lib/services/daily_reward_service.dart
```

### Backend Requirements
```
GET  /api/user/daily-reward/status  → আজ claim হয়েছে কি + কোন day
POST /api/user/daily-reward/claim   → reward claim + coin credit
```

---

## MODULE 6 — 🏅 Leaderboard

### Categories
| Category | Description |
|----------|-------------|
| 📖 **পড়ার সময়** | সবচেয়ে বেশি মিনিট পড়েছে |
| 🎧 **শোনার সময়** | সবচেয়ে বেশি মিনিট অডিওবুক শুনেছে |
| 🪙 **Coin উপার্জন** | সবচেয়ে বেশি coin earn করেছে |
| 🔥 **Streak** | সবচেয়ে দীর্ঘ consecutive streak |

### Time Filters
- **Daily** — আজকের top readers
- **Weekly** — এই সপ্তাহের
- **Monthly** — এই মাসের
- **All Time** — সর্বকালের

### UI Design
```
┌──────────────────────────────────────┐
│          🏆 লিডারবোর্ড               │
│  [পড়া] [শোনা] [Coin] [Streak]       │  ← Filter tabs
│  [দৈনিক] [সাপ্তাহিক] [মাসিক]        │  ← Time filter
├──────────────────────────────────────┤
│  🥇 1. রাহেল আহমেদ    4h 20m        │
│  🥈 2. সুমাইয়া খান   3h 45m        │
│  🥉 3. তানভীর হোসেন  3h 10m        │
│  ...                                 │
├──────────────────────────────────────┤
│  👤 আপনার অবস্থান: #47              │  ← Your rank (sticky)
└──────────────────────────────────────┘
```

### Placement
```
Bottom Nav → Existing "আরো" বা নতুন tab যোগ করো
ProfilePage → "লিডারবোর্ডে আমার অবস্থান" card
```

### Flutter Structure
```
lib/pages/leaderboard_page/
    ├── leaderboard_page_widget.dart
    └── leaderboard_item_widget.dart
```

### Backend Requirements
```
GET /api/leaderboard?type=reading_time&period=daily&limit=100
GET /api/leaderboard?type=coin&period=weekly
GET /api/leaderboard/my-rank?type=reading_time&period=daily
```

---

## MODULE 7 — 🎮 Special Events (Quiz, Game, Lucky Spin)

### Event Types

#### 7A. Lucky Spin 🎡
```
┌──────────────────────────────────────┐
│           🎡 ভাগ্যচক্র               │
│     প্রতিদিন ১বার বিনামূল্যে!        │
│                                      │
│         [Wheel Animation]            │
│     [🎰 এখন ঘুরান! (Spin)]          │
├──────────────────────────────────────┤
│  সম্ভাব্য পুরস্কার:                  │
│  🪙 5 Coin | 🪙 20 Coin | ❌ আবার চেষ্টা │
│  📖 Free Book | 🎧 Audiobook Chapter  │
│  💰 ৳50 Recharge | 🏆 Special Badge  │
└──────────────────────────────────────┘
```
- প্রতিদিন ১ বার free spin
- Extra spin: 50 coin দিয়ে

#### 7B. Reading Quiz 📝
```
- সাপ্তাহিক quiz: পড়া বই থেকে প্রশ্ন
- বা সাধারণ সাহিত্য জ্ঞান quiz
- পুরস্কার: Coin + Special Rank
- Top 3: Real reward (recharge/cash)
```

#### 7C. Special Events Calendar 📅
```
- ঈদ Event: Double coin week
- বই মেলা Event: Special discounts + quiz
- পয়লা বৈশাখ: Special Bengali book challenge
```

### Placement
```
Home Page → "ইভেন্ট" banner/card (eye-catching)
Bottom Nav → "ইভেন্ট" নতুন tab যোগ বা existing "আরো" এ
Notification → Event শুরু হলে push
```

### Flutter Structure
```
lib/pages/events_page/
    ├── events_home_page_widget.dart
    ├── lucky_spin_page_widget.dart
    └── quiz_page_widget.dart
```

### Backend Requirements
```
GET  /api/events/active              → current events
POST /api/events/lucky-spin/spin     → spin result
GET  /api/events/lucky-spin/status   → আজ spin করা হয়েছে কি
GET  /api/events/quiz/current        → current week quiz
POST /api/events/quiz/submit         → quiz answers submit
```

---

## MODULE 8 — 💰 Special Competitions & Rewards

### Competition Types

#### 8A. Reading Competition
```
প্রতি ঘণ্টায় সবচেয়ে বেশি পড়া user পায়:
🥇 1st → ৳100 Mobile Recharge
🥈 2nd → 50 Coin
🥉 3rd → 25 Coin

দৈনিক:
🥇 1st → ৳200 Recharge বা Free Book
🥈 2nd → ৳100 Recharge  
🥉 3rd → 50 Coin
```

#### 8B. Purchase-Based Competition
```
"প্রথম ক্রেতা" Competition:
- প্রতিদিন প্রথম যে user purchase করবে → Double cashback
- প্রথম ১০ জন purchase করলে → বিশেষ discount

"বেশি কেনা" Competition:
- এই সপ্তাহে সবচেয়ে বেশি purchase → Special reward
```

#### 8C. Referral Competition
```
Refer করো, পুরস্কার পাও:
- প্রতি সফল refer → 30 Coin (referrer) + 20 Coin (new user)
- মাসের সেরা referrer → ৳500 Cash / Recharge
```

#### 8D. Cashback & Recharge Rewards
```
💰 Reading Cashback:
- প্রতি ঘণ্টা reading = 5 Coin
- প্রতি বই সম্পন্ন = 20 Coin
- Coin → টাকা (100 Coin = ৳10 Wallet balance / Recharge)

📱 Mobile Recharge Reward:
- Streak 30 days → ৳50 Recharge
- Complete 5 books → ৳100 Recharge (বিশেষ event এ)
```

### Placement
```
Home Page → "চলমান প্রতিযোগিতা" section (urgent banner style)
Wallet Page → Coin history + Withdrawal options
Notification → Real-time competition updates
```

### Flutter Structure
```
lib/pages/competitions_page/
    ├── competitions_page_widget.dart
    └── competition_item_widget.dart

lib/widgets/competition_banner_widget.dart  ← Home Page এ
```

### Backend Requirements
```
GET  /api/competitions/active           → চলমান competitions
GET  /api/competitions/{id}/leaderboard → competition ranking
POST /api/competitions/join             → join করো
GET  /api/user/wallet/coin-balance      → coin balance
POST /api/user/wallet/redeem-coins      → coin → recharge/cash
POST /api/referral/generate-code        → referral code
POST /api/referral/apply                → referral code apply
```

---

## 🗄️ Firestore / Database Schema

### New Collections Needed
```
users/{userId}/
  ├── streak_data/
  │     ├── current_streak: int
  │     ├── max_streak: int
  │     ├── last_read_date: timestamp
  │     └── streak_updated_today: bool
  │
  ├── achievements/
  │     ├── {badge_id}/
  │     │     ├── earned: bool
  │     │     ├── earned_at: timestamp
  │     │     └── coin_claimed: bool
  │
  ├── daily_rewards/
  │     ├── last_claim_date: timestamp
  │     └── consecutive_days: int
  │
  └── reading_stats/
        ├── weekly_minutes: int
        ├── total_books_completed: int
        └── total_audiobooks_completed: int

competitions/{id}/
  └── participants/{userId}/
        ├── score: double
        └── joined_at: timestamp

events/
  └── {event_id}/
        ├── type: string (quiz/spin/challenge)
        ├── start_at: timestamp
        └── end_at: timestamp

leaderboard/{period}/  (daily/weekly/monthly)
  └── {userId}/
        ├── reading_minutes: int
        ├── listening_minutes: int
        └── coins_earned: int
```

---

## 📅 Implementation Timeline

### Phase 1 — Quick Wins (সপ্তাহ ১–২)
- [ ] Daily Login Reward Dialog (Module 5)
- [ ] Continue Reading Card (Home Page)
- [ ] Reading Streak UI (Home Page header)
- [ ] Personalized Notification messages improve

### Phase 2 — Engagement Features (সপ্তাহ ৩–৫)
- [ ] Badges & Achievements UI + Backend
- [ ] Weekly Reading Report UI + Share
- [ ] Personalized Home Recommendations

### Phase 3 — Social & Competition (সপ্তাহ ৬–৯)
- [ ] Leaderboard (Daily/Weekly/Monthly)
- [ ] Lucky Spin Event
- [ ] Reading Quiz

### Phase 4 — Monetized Engagement (সপ্তাহ ১০+)
- [ ] Reading Competition with Recharge reward
- [ ] Purchase Competition
- [ ] Referral System
- [ ] Coin → Recharge/Cash redemption

---

## ✅ Existing Infrastructure (ইতিমধ্যে আছে)

| Feature | Status |
|---------|--------|
| Streak API (`updateStreakCall`) | ✅ আছে |
| Reading Progress Service | ✅ আছে |
| Presence Tracking (reading/listening time) | ✅ আছে |
| Push Notification (Firebase FCM) | ✅ আছে |
| Wallet Page | ✅ আছে |
| Follow Service (author follow) | ✅ আছে |
| Favourite Page | ✅ আছে |
| Notification Permission | ✅ আছে |

---

## 🎯 কোথা থেকে শুরু করবে?

**এই সপ্তাহে করো:**
1. `Daily Login Reward Dialog` → সবচেয়ে কম কাজ, সবচেয়ে বেশি impact
2. `Continue Reading Card` Home Page এ → `reading_progress_service.dart` ব্যবহার করে
3. Push notification message personalize করো

> **কোন module implement করতে চাও? বললে সেটার পুরো Flutter code লিখে দেবো।**

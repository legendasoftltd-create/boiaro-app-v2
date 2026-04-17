# BoiAro REST API — Complete Documentation v2
## Flutter Integration Reference

**Version:** 2.0  
**Date:** 2026-04-05  
**Base URL:** `https://kxpqejmjfnzhqcefyued.supabase.co/functions/v1/mobile-api`

---

## Global Rules

### Required Headers (every request)

| Header | Value | When |
|--------|-------|------|
| `apikey` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4cHFlam1qZm56aHFjZWZ5dWVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzMzA0NjUsImV4cCI6MjA4OTkwNjQ2NX0.PSM2xT9QPzJmBU5yP7uKnQxVAvbpevAGF8wFw43i9to` | **Always** |
| `Content-Type` | `application/json` | POST / PUT / PATCH |
| `Authorization` | `Bearer <access_token>` | 🔒 Authenticated endpoints |

### Response Envelope

All responses are JSON. Success responses vary per endpoint. Error responses always follow:

```json
{ "error": "Human-readable error message" }
```

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| `200` | Success |
| `201` | Resource created |
| `400` | Bad request / missing params |
| `401` | Authentication required |
| `403` | Forbidden (deactivated/deleted account) |
| `404` | Resource not found |
| `422` | Validation error (e.g. weak password) |
| `500` | Internal server error |

### Pagination Convention

Paginated endpoints accept:
- `limit` (int, default 20, max 50)
- `offset` (int, default 0)

And return `total` (int or null) alongside the data array.

---

# 1. Authentication

## POST /auth/signup

Create a new user account. Email verification is required before login.

| Field | Details |
|-------|---------|
| **Auth required** | No |
| **Path params** | None |
| **Query params** | None |

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `email` | string | ✅ | User email address |
| `password` | string | ✅ | Min 6 characters |
| `display_name` | string | ❌ | User display name |

```json
{
  "email": "rahim@example.com",
  "password": "SecurePass123!",
  "display_name": "রহিম আহমেদ"
}
```

**Success (201):**

```json
{
  "user_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "email": "rahim@example.com",
  "message": "Please verify your email"
}
```

**Error (400):**
```json
{ "error": "email and password required" }
```

**Error (422):**
```json
{ "error": "Password should be at least 6 characters" }
```

---

## POST /auth/login

Sign in with email/password. Returns JWT tokens.

| Field | Details |
|-------|---------|
| **Auth required** | No |

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `email` | string | ✅ | Registered email |
| `password` | string | ✅ | Account password |

```json
{
  "email": "rahim@example.com",
  "password": "SecurePass123!"
}
```

**Success (200):**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "v1_refresh_abc123def456...",
  "expires_in": 3600,
  "user": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "email": "rahim@example.com"
  }
}
```

| Response field | Type | Description |
|----------------|------|-------------|
| `access_token` | string | JWT for Authorization header, expires in `expires_in` seconds |
| `refresh_token` | string | Use with `/auth/refresh` to get a new access token |
| `expires_in` | int | Token lifetime in seconds (typically 3600) |
| `user.id` | uuid | User's unique ID |
| `user.email` | string | User's email |

**Error (401):**
```json
{ "error": "Invalid login credentials" }
```

**Error (403):**
```json
{ "error": "Account deactivated. Contact support." }
```
```json
{ "error": "Account has been deleted. Contact support." }
```

---

## POST /auth/refresh

Refresh an expired access token using the refresh token.

| Field | Details |
|-------|---------|
| **Auth required** | No |

**Request body:**

| Field | Type | Required |
|-------|------|----------|
| `refresh_token` | string | ✅ |

```json
{ "refresh_token": "v1_refresh_abc123def456..." }
```

**Success (200):**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "v1_refresh_newtoken789...",
  "expires_in": 3600
}
```

**Error (401):**
```json
{ "error": "Invalid Refresh Token: Refresh Token Not Found" }
```

---

## POST /auth/logout

Server-side logout acknowledgment. Client should discard tokens.

| Field | Details |
|-------|---------|
| **Auth required** | 🔒 Yes |

**Request body:** None (empty `{}`)

**Success (200):**
```json
{ "message": "Logged out" }
```

---

## POST /auth/reset-password

Send a password reset email.

| Field | Details |
|-------|---------|
| **Auth required** | No |

**Request body:**

| Field | Type | Required |
|-------|------|----------|
| `email` | string | ✅ |

```json
{ "email": "rahim@example.com" }
```

**Success (200):**
```json
{ "message": "Password reset email sent" }
```

---

## POST /auth/update-password

Set a new password for the currently authenticated user.

| Field | Details |
|-------|---------|
| **Auth required** | 🔒 Yes |

**Request body:**

| Field | Type | Required |
|-------|------|----------|
| `password` | string | ✅ |

```json
{ "password": "NewSecurePass456!" }
```

**Success (200):**
```json
{ "message": "Password updated" }
```

**Error (422):**
```json
{ "error": "Password should be at least 6 characters" }
```

---

# 2. User Profile

## GET /profile

Get the current user's profile.

| Field | Details |
|-------|---------|
| **Auth required** | 🔒 Yes |
| **Query params** | None |

**Success (200):**

```json
{
  "user_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "display_name": "রহিম আহমেদ",
  "full_name": "Rahim Ahmed Khan",
  "avatar_url": "https://storage.example.com/avatars/rahim.jpg",
  "bio": "বই পড়তে ভালোবাসি",
  "preferred_language": "bn",
  "referral_code": "A1B2C3D4",
  "created_at": "2026-01-15T10:30:00.000Z"
}
```

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `user_id` | uuid | No | User's unique ID |
| `display_name` | string | Yes | Public display name |
| `full_name` | string | Yes | Full legal name |
| `avatar_url` | string | Yes | Profile picture URL |
| `bio` | string | Yes | User bio text |
| `preferred_language` | string | Yes | `"bn"` or `"en"` |
| `referral_code` | string | Yes | User's referral code |
| `created_at` | ISO 8601 | No | Account creation time |

**Error (404):**
```json
{ "error": "Profile not found" }
```

---

## PATCH /profile

Update profile fields. Only send fields you want to change.

| Field | Details |
|-------|---------|
| **Auth required** | 🔒 Yes |

**Allowed fields:**

| Field | Type | Description |
|-------|------|-------------|
| `display_name` | string | Public display name |
| `full_name` | string | Full name |
| `avatar_url` | string | Profile picture URL |
| `bio` | string | Bio text |
| `preferred_language` | string | `"bn"` or `"en"` |

**Request body:**
```json
{
  "display_name": "নতুন নাম",
  "preferred_language": "en"
}
```

**Success (200):**
```json
{ "message": "Profile updated" }
```

---

## GET /profile/roles

Get the authenticated user's assigned roles.

| Field | Details |
|-------|---------|
| **Auth required** | 🔒 Yes |

**Success (200):**

```json
{ "roles": ["user", "writer"] }
```

| Field | Type | Description |
|-------|------|-------------|
| `roles` | string[] | Array of role strings. Possible values: `"user"`, `"writer"`, `"narrator"`, `"publisher"`, `"admin"`, `"moderator"` |

---

# 3. Books & Content Discovery

## GET /books

List books with pagination and optional filters. **No auth required.**

**Query params:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | int | 20 | Results per page (max 50) |
| `offset` | int | 0 | Pagination offset |
| `category_id` | uuid | — | Filter by category |
| `featured` | `"true"` | — | Featured books only |
| `free` | `"true"` | — | Free books only |
| `q` | string | — | Search by title (Bangla or English) |

**Success (200):**

```json
{
  "books": [
    {
      "id": "b1234567-89ab-cdef-0123-456789abcdef",
      "title": "চাঁদের পাহাড়",
      "title_en": "Chander Pahar",
      "slug": "chander-pahar",
      "cover_url": "https://storage.example.com/covers/chander-pahar.jpg",
      "rating": 4.5,
      "total_reads": 1200,
      "is_free": false,
      "is_featured": true,
      "is_bestseller": true,
      "is_new": false,
      "is_premium": true,
      "language": "Bangla",
      "published_date": "2025-06-15",
      "created_at": "2026-01-10T08:00:00.000Z",
      "author_id": "auth-uuid",
      "category_id": "cat-uuid",
      "authors": {
        "id": "auth-uuid",
        "name": "বিভূতিভূষণ বন্দ্যোপাধ্যায়",
        "avatar_url": "https://..."
      },
      "categories": {
        "id": "cat-uuid",
        "name": "উপন্যাস",
        "name_en": "Novel"
      }
    }
  ],
  "total": 156,
  "limit": 20,
  "offset": 0
}
```

| Field | Type | Description |
|-------|------|-------------|
| `books` | array | Array of book objects |
| `total` | int\|null | Total matching books (for pagination) |
| `limit` | int | Applied limit |
| `offset` | int | Applied offset |

Each book object:

| Field | Type | Description |
|-------|------|-------------|
| `id` | uuid | Book unique ID |
| `title` | string | Bangla title |
| `title_en` | string\|null | English title |
| `slug` | string | URL-friendly slug |
| `cover_url` | string\|null | Cover image URL |
| `rating` | float\|null | Average rating (0–5) |
| `total_reads` | int\|null | Total read count |
| `is_free` | bool | Whether the book is free |
| `is_featured` | bool | Featured flag |
| `is_bestseller` | bool | Bestseller flag |
| `is_new` | bool | Recently published |
| `is_premium` | bool | Premium content flag |
| `language` | string | Book language |
| `published_date` | string\|null | Publication date |
| `authors` | object\|null | Nested author `{id, name, avatar_url}` |
| `categories` | object\|null | Nested category `{id, name, name_en}` |

---

## GET /books/{id_or_slug}

Get full book details including all available formats. **No auth required.**

| Field | Details |
|-------|---------|
| **Path params** | `id_or_slug` — UUID or slug string |

**Success (200):**

```json
{
  "id": "b1234567-89ab-cdef-0123-456789abcdef",
  "title": "চাঁদের পাহাড়",
  "title_en": "Chander Pahar",
  "slug": "chander-pahar",
  "description": "A classic adventure novel...",
  "description_bn": "একটি ক্লাসিক অ্যাডভেঞ্চার উপন্যাস...",
  "cover_url": "https://...",
  "rating": 4.5,
  "reviews_count": 15,
  "total_reads": 1200,
  "is_free": false,
  "is_featured": true,
  "is_bestseller": true,
  "is_new": false,
  "is_premium": true,
  "language": "Bangla",
  "published_date": "2025-06-15",
  "tags": ["adventure", "classic", "bangla"],
  "coin_price": 50,
  "submission_status": "approved",
  "created_at": "2026-01-10T08:00:00.000Z",
  "authors": {
    "id": "auth-uuid",
    "name": "বিভূতিভূষণ বন্দ্যোপাধ্যায়",
    "name_en": "Bibhutibhushan Bandyopadhyay",
    "avatar_url": "https://...",
    "bio": "বিখ্যাত বাংলা ঔপন্যাসিক..."
  },
  "categories": {
    "id": "cat-uuid",
    "name": "উপন্যাস",
    "name_en": "Novel",
    "icon": "BookOpen",
    "color": "from-amber-50 to-orange-50"
  },
  "formats": [
    {
      "id": "fmt-uuid-1",
      "format": "ebook",
      "price": 90,
      "original_price": 120,
      "discount": 25,
      "coin_price": 50,
      "duration": null,
      "pages": 320,
      "file_size": "2.5 MB",
      "in_stock": null,
      "stock_count": null,
      "is_available": true,
      "preview_percentage": 15,
      "preview_chapters": 2,
      "narrator_id": null,
      "narrators": null
    },
    {
      "id": "fmt-uuid-2",
      "format": "audiobook",
      "price": 150,
      "original_price": null,
      "discount": null,
      "coin_price": 80,
      "duration": "5:30:00",
      "pages": null,
      "file_size": null,
      "in_stock": null,
      "stock_count": null,
      "is_available": true,
      "preview_percentage": 5,
      "preview_chapters": null,
      "narrator_id": "narr-uuid",
      "narrators": {
        "id": "narr-uuid",
        "name": "ফিউরেল্লা নূর পায়েল",
        "avatar_url": "https://..."
      }
    },
    {
      "id": "fmt-uuid-3",
      "format": "hardcopy",
      "price": 350,
      "original_price": 450,
      "discount": 22,
      "coin_price": null,
      "duration": null,
      "pages": 320,
      "file_size": null,
      "in_stock": true,
      "stock_count": 45,
      "is_available": true,
      "preview_percentage": null,
      "preview_chapters": null,
      "narrator_id": null,
      "narrators": null
    }
  ]
}
```

Format object fields:

| Field | Type | Description |
|-------|------|-------------|
| `id` | uuid | Format record ID |
| `format` | string | `"ebook"`, `"audiobook"`, or `"hardcopy"` |
| `price` | float\|null | Price in BDT |
| `original_price` | float\|null | Original price before discount |
| `discount` | float\|null | Discount percentage |
| `coin_price` | int\|null | Price in coins (for coin unlock) |
| `duration` | string\|null | Audiobook duration (HH:MM:SS) |
| `pages` | int\|null | Page count for ebook/hardcopy |
| `file_size` | string\|null | File size string |
| `in_stock` | bool\|null | Hardcopy stock status |
| `stock_count` | int\|null | Available stock quantity |
| `is_available` | bool | Whether this format is active |
| `preview_percentage` | int\|null | Preview % allowed (e.g. 15 = 15%) |
| `preview_chapters` | int\|null | Number of free preview chapters |
| `narrator_id` | uuid\|null | Narrator ID (audiobook only) |
| `narrators` | object\|null | Nested `{id, name, avatar_url}` |

**Error (404):**
```json
{ "error": "Book not found" }
```

---

## GET /categories

List all active categories. **No auth required.**

**Success (200):**

```json
{
  "categories": [
    {
      "id": "cat-uuid",
      "name": "উপন্যাস",
      "name_bn": "উপন্যাস",
      "name_en": "Novel",
      "icon": "BookOpen",
      "color": "from-amber-50 to-orange-50",
      "slug": "novel",
      "is_featured": true,
      "is_trending": false,
      "priority": 1
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | uuid | Category ID |
| `name` | string | Primary name |
| `name_bn` | string\|null | Bangla name |
| `name_en` | string\|null | English name |
| `icon` | string\|null | Lucide icon name |
| `color` | string\|null | Tailwind gradient classes |
| `slug` | string\|null | URL slug |
| `is_featured` | bool | Featured on homepage |
| `is_trending` | bool | Currently trending |
| `priority` | int | Sort order (lower = first) |

---

## GET /authors

List authors with pagination. **No auth required.**

**Query params:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | int | 20 | Max 50 |
| `offset` | int | 0 | Pagination offset |

**Success (200):**

```json
{
  "authors": [
    {
      "id": "auth-uuid",
      "name": "বিভূতিভূষণ বন্দ্যোপাধ্যায়",
      "name_en": "Bibhutibhushan Bandyopadhyay",
      "avatar_url": "https://...",
      "bio": "বিখ্যাত বাংলা ঔপন্যাসিক ও ছোটগল্পকার...",
      "genre": "Adventure, Fiction",
      "is_featured": true,
      "is_trending": false,
      "priority": 1
    }
  ],
  "total": 42,
  "limit": 20,
  "offset": 0
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | uuid | Author ID |
| `name` | string | Bangla name |
| `name_en` | string\|null | English name |
| `avatar_url` | string\|null | Photo URL |
| `bio` | string\|null | Biography text |
| `genre` | string\|null | Genre specialization |
| `is_featured` | bool | Featured author |
| `is_trending` | bool | Currently trending |
| `priority` | int | Sort order |

---

## GET /authors/{id}

Get a single author's details. **No auth required.**

| Field | Details |
|-------|---------|
| **Path params** | `id` — author UUID |

**Success (200):**

```json
{
  "id": "auth-uuid",
  "name": "বিভূতিভূষণ বন্দ্যোপাধ্যায়",
  "name_en": "Bibhutibhushan Bandyopadhyay",
  "avatar_url": "https://...",
  "bio": "বিখ্যাত বাংলা ঔপন্যাসিক...",
  "genre": "Adventure, Fiction",
  "is_featured": true,
  "is_trending": false
}
```

**Error (404):**
```json
{ "error": "Author not found" }
```

---

## GET /narrators

List all active narrators. **No auth required.**

**Success (200):**

```json
{
  "narrators": [
    {
      "id": "narr-uuid",
      "name": "ফিউরেল্লা নূর পায়েল",
      "name_en": "Fiurella Noor Payel",
      "avatar_url": "https://...",
      "bio": "পেশাদার অডিওবুক বর্ণনাকারী...",
      "specialty": "Fiction, Drama",
      "rating": 4.8,
      "is_featured": true,
      "is_trending": false
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | uuid | Narrator ID |
| `name` | string | Bangla name |
| `name_en` | string\|null | English name |
| `avatar_url` | string\|null | Photo URL |
| `bio` | string\|null | Biography |
| `specialty` | string\|null | Genre specialty |
| `rating` | float\|null | Average rating (0–5) |
| `is_featured` | bool | Featured narrator |
| `is_trending` | bool | Trending |

---

## GET /publishers

List all active publishers. **No auth required.**

**Success (200):**

```json
{
  "publishers": [
    {
      "id": "pub-uuid",
      "name": "আনন্দ পাবলিশার্স",
      "name_en": "Ananda Publishers",
      "logo_url": "https://...",
      "description": "বাংলা ভাষার অন্যতম শীর্ষ প্রকাশনা সংস্থা...",
      "is_verified": true,
      "is_featured": true
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | uuid | Publisher ID |
| `name` | string | Bangla name |
| `name_en` | string\|null | English name |
| `logo_url` | string\|null | Logo URL |
| `description` | string\|null | Description |
| `is_verified` | bool | Verified publisher |
| `is_featured` | bool | Featured |

---

## GET /search

Search books by title. **No auth required.**

**Query params:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `q` | string | ✅ | Search query, min 2 characters |

**Success (200):**

```json
{
  "results": [
    {
      "id": "book-uuid",
      "title": "চাঁদের পাহাড়",
      "title_en": "Chander Pahar",
      "slug": "chander-pahar",
      "cover_url": "https://...",
      "rating": 4.5,
      "is_free": false,
      "authors": {
        "name": "বিভূতিভূষণ বন্দ্যোপাধ্যায়"
      }
    }
  ]
}
```

**Error (400):**
```json
{ "error": "Search query too short (min 2 chars)" }
```

---

## GET /homepage

Fetch all homepage sections in a single call. **No auth required.** Recommended for the app home screen.

**Success (200):**

```json
{
  "featured": [
    { "id": "uuid", "title": "চাঁদের পাহাড়", "slug": "chander-pahar", "cover_url": "https://...", "rating": 4.5, "authors": { "name": "বিভূতিভূষণ" } }
  ],
  "trending": [
    { "id": "uuid", "title": "পথের পাঁচালী", "slug": "pather-panchali", "cover_url": "https://...", "rating": 4.7, "total_reads": 5200, "authors": { "name": "বিভূতিভূষণ" } }
  ],
  "free": [
    { "id": "uuid", "title": "গীতাঞ্জলি", "slug": "gitanjali", "cover_url": "https://...", "rating": 4.9, "authors": { "name": "রবীন্দ্রনাথ" } }
  ],
  "new": [
    { "id": "uuid", "title": "নতুন বই", "slug": "notun-boi", "cover_url": "https://...", "rating": 4.0, "authors": { "name": "নতুন লেখক" } }
  ]
}
```

Each section is an array of up to 10 books. Each book has: `id`, `title`, `slug`, `cover_url`, `rating`, `authors.name`. The `trending` section also includes `total_reads`.

---

# 4. Audiobook Tracks

## GET /books/{book_id}/tracks

List audiobook tracks for a book. **No auth required.**

| Field | Details |
|-------|---------|
| **Path params** | `book_id` — UUID |

**Success (200):**

```json
{
  "tracks": [
    {
      "id": "track-uuid-1",
      "track_number": 1,
      "title": "অধ্যায় ১ - শুরু",
      "duration": "12:30",
      "is_preview": true,
      "media_type": "audio",
      "chapter_price": null,
      "status": "active"
    },
    {
      "id": "track-uuid-2",
      "track_number": 2,
      "title": "অধ্যায় ২ - যাত্রা",
      "duration": "15:45",
      "is_preview": false,
      "media_type": "audio",
      "chapter_price": 10,
      "status": "active"
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | uuid | Track ID |
| `track_number` | int | Sequential track number |
| `title` | string | Chapter/track title |
| `duration` | string\|null | Duration string (MM:SS or HH:MM:SS) |
| `is_preview` | bool | Whether marked as preview |
| `media_type` | string | `"audio"` or `"video"` |
| `chapter_price` | int\|null | Per-chapter coin price |
| `status` | string | Track status |

Returns `{ "tracks": [] }` if no audiobook format exists.

---

# 5. Access Control

## POST /access/check

Check if user has access to a specific book format. **🔒 Auth required.**

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `book_id` | uuid | ✅ | Book ID |
| `format` | string | ✅ | `"ebook"`, `"audiobook"`, or `"hardcopy"` |

```json
{ "book_id": "book-uuid", "format": "ebook" }
```

**Success (200):**

```json
{
  "has_access": true,
  "access_method": "purchase",
  "is_free": false,
  "has_subscription": false,
  "has_purchase": true,
  "has_unlock": false
}
```

Response depends on the `check_hybrid_access` database function. Key fields:

| Field | Type | Description |
|-------|------|-------------|
| `has_access` | bool | Whether user can access full content |
| `access_method` | string | How access was granted: `"purchase"`, `"subscription"`, `"coin_unlock"`, `"free"`, `"none"` |

---

## GET /access/preview-eligibility

Check preview availability for any book/format. **No auth required.** Use this to configure preview UI.

**Query params:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `book_id` | uuid | — | ✅ Required |
| `format` | string | `"ebook"` | `"ebook"` or `"audiobook"` |

**Success (200):**

```json
{
  "is_free": false,
  "preview_percentage": 15,
  "preview_chapters": 2,
  "price": 90,
  "guest_preview_allowed": true
}
```

| Field | Type | Description |
|-------|------|-------------|
| `is_free` | bool | Book is completely free |
| `preview_percentage` | int | Percentage of content available as preview |
| `preview_chapters` | int | Number of free chapters |
| `price` | float | Price in BDT |
| `guest_preview_allowed` | bool | Always `true` — guests can preview |

---

# 6. Secure Content URLs

## POST /content/ebook-url

Get a time-limited signed URL for full ebook file access. **🔒 Auth required + purchase/unlock.**

**Request body:**

| Field | Type | Required |
|-------|------|----------|
| `book_id` | uuid | ✅ |

```json
{ "book_id": "book-uuid" }
```

**Success (200):**

```json
{
  "signed_url": "https://storage.example.com/ebooks/book.pdf?token=abc123&expires=1712345678",
  "mime_type": "application/pdf",
  "expires_in": 300
}
```

| Field | Type | Description |
|-------|------|-------------|
| `signed_url` | string | Time-limited download URL |
| `mime_type` | string | File MIME type |
| `expires_in` | int | URL validity in seconds |

**Error (401):**
```json
{ "error": "Authentication required" }
```

**Error (500):**
```json
{ "error": "Failed to get secure URL" }
```

---

## POST /content/audio-url

Get a signed URL for a specific audio track. **Works for both guests (preview) and authenticated users (full access).**

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `book_id` | uuid | ✅ | Book ID |
| `track_number` | int | ❌ | Track to fetch (default: 1) |

```json
{ "book_id": "book-uuid", "track_number": 1 }
```

**Success (200):**

```json
{
  "signed_url": "https://storage.example.com/audio/track1.mp3?token=xyz&expires=1712345678",
  "expires_in": 300
}
```

**Note:** Guest users receive the same URL but the Flutter app must enforce the preview duration limit client-side (using `preview_percentage` from `/access/preview-eligibility`).

---

## POST /content/batch-audio-urls

Get signed URLs for all tracks at once. **🔒 Auth required.**

**Request body:**

| Field | Type | Required |
|-------|------|----------|
| `book_id` | uuid | ✅ |

```json
{ "book_id": "book-uuid" }
```

**Success (200):**

```json
{
  "urls": {
    "1": { "signed_url": "https://...", "expires_in": 300 },
    "2": { "signed_url": "https://...", "expires_in": 300 },
    "3": { "signed_url": "https://...", "expires_in": 300 }
  },
  "full_access": true
}
```

---

# 7. Reading & Listening Progress

## GET /progress/reading

Get reading progress for a specific book. **🔒 Auth required.**

**Query params:**

| Param | Type | Required |
|-------|------|----------|
| `book_id` | uuid | ✅ |

**Success (200):**

```json
{
  "id": "progress-uuid",
  "user_id": "user-uuid",
  "book_id": "book-uuid",
  "current_page": 45,
  "total_pages": 320,
  "percentage": 14,
  "last_read_at": "2026-04-05T12:30:00.000Z",
  "created_at": "2026-04-01T10:00:00.000Z"
}
```

Returns default if no progress exists:
```json
{ "current_page": 0, "total_pages": 0, "percentage": 0 }
```

| Field | Type | Description |
|-------|------|-------------|
| `current_page` | int | Last read page number |
| `total_pages` | int | Total pages in the book |
| `percentage` | int | Read percentage (0–100) |
| `last_read_at` | ISO 8601 | Timestamp of last reading session |

---

## PUT /progress/reading

Save or update reading progress. **🔒 Auth required.**

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `book_id` | uuid | ✅ | Book ID |
| `current_page` | int | ✅ | Current page number |
| `total_pages` | int | ✅ | Total pages |

```json
{
  "book_id": "book-uuid",
  "current_page": 78,
  "total_pages": 320
}
```

**Success (200):**
```json
{ "message": "Progress saved", "percentage": 24 }
```

---

## GET /progress/listening

Get listening progress for a specific audiobook. **🔒 Auth required.**

**Query params:**

| Param | Type | Required |
|-------|------|----------|
| `book_id` | uuid | ✅ |

**Success (200):**

```json
{
  "id": "progress-uuid",
  "user_id": "user-uuid",
  "book_id": "book-uuid",
  "current_track": 3,
  "position_seconds": 180,
  "total_seconds": 750,
  "last_listened_at": "2026-04-05T14:00:00.000Z"
}
```

Returns default if no progress exists:
```json
{ "current_track": 1, "position_seconds": 0 }
```

| Field | Type | Description |
|-------|------|-------------|
| `current_track` | int | Current track number |
| `position_seconds` | int | Playback position in seconds within current track |
| `total_seconds` | int | Total duration in seconds of current track |
| `last_listened_at` | ISO 8601 | Last listening timestamp |

---

## PUT /progress/listening

Save or update listening progress. **🔒 Auth required.**

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `book_id` | uuid | ✅ | Book ID |
| `track_number` | int | ❌ | Current track (default: 1) |
| `position_seconds` | int | ❌ | Playback position in seconds |
| `total_seconds` | int | ❌ | Total track duration in seconds |

```json
{
  "book_id": "book-uuid",
  "track_number": 3,
  "position_seconds": 245,
  "total_seconds": 750
}
```

**Success (200):**
```json
{ "message": "Listening progress saved" }
```

---

# 8. Bookmarks

## GET /bookmarks

Get all bookmarked books. **🔒 Auth required.**

**Success (200):**

```json
{
  "bookmarks": [
    {
      "id": "bookmark-uuid",
      "book_id": "book-uuid",
      "created_at": "2026-04-03T10:00:00.000Z",
      "books": {
        "id": "book-uuid",
        "title": "চাঁদের পাহাড়",
        "cover_url": "https://...",
        "slug": "chander-pahar"
      }
    }
  ]
}
```

---

## POST /bookmarks

Add a book to bookmarks. **🔒 Auth required.**

**Request body:**

| Field | Type | Required |
|-------|------|----------|
| `book_id` | uuid | ✅ |

```json
{ "book_id": "book-uuid" }
```

**Success (201):**
```json
{ "message": "Bookmarked" }
```

---

## DELETE /bookmarks/{book_id}

Remove a bookmark. **🔒 Auth required.**

| Field | Details |
|-------|---------|
| **Path params** | `book_id` — UUID of the book |

**Success (200):**
```json
{ "message": "Bookmark removed" }
```

---

# 9. Reviews & Comments

## GET /books/{book_id}/reviews

Get book reviews. **No auth required.**

**Success (200):**

```json
{
  "reviews": [
    {
      "id": "review-uuid",
      "rating": 5,
      "comment": "অসাধারণ বই! সবাইকে পড়তে বলছি।",
      "created_at": "2026-04-01T15:00:00.000Z",
      "user_id": "user-uuid",
      "profiles": {
        "display_name": "রহিম আহমেদ",
        "avatar_url": "https://..."
      }
    }
  ]
}
```

---

## POST /reviews

Submit a review/rating. **🔒 Auth required.**

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `book_id` | uuid | ✅ | Book ID |
| `rating` | int | ✅ | Rating 1–5 |
| `comment` | string | ❌ | Review text |

```json
{
  "book_id": "book-uuid",
  "rating": 5,
  "comment": "অসাধারণ বই!"
}
```

**Success (200):** Returns the review data from the database function.

---

## GET /books/{book_id}/comments

Get book comments (threaded). **No auth required.**

**Success (200):**

```json
{
  "comments": [
    {
      "id": "comment-uuid",
      "comment": "এই বইটা কি মোবাইলে পড়া যায়?",
      "created_at": "2026-04-02T08:00:00.000Z",
      "user_id": "user-uuid",
      "parent_id": null,
      "profiles": {
        "display_name": "করিম",
        "avatar_url": "https://..."
      }
    },
    {
      "id": "reply-uuid",
      "comment": "হ্যাঁ, BoiAro অ্যাপে পড়তে পারবেন!",
      "created_at": "2026-04-02T09:00:00.000Z",
      "user_id": "other-uuid",
      "parent_id": "comment-uuid",
      "profiles": {
        "display_name": "জাহিদ",
        "avatar_url": null
      }
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `parent_id` | uuid\|null | `null` = top-level comment, uuid = reply to that comment |

---

## POST /comments

Post a comment or reply. **🔒 Auth required.**

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `book_id` | uuid | ✅ | Book ID |
| `comment` | string | ✅ | Comment text |
| `parent_id` | uuid | ❌ | Parent comment ID for replies |

```json
{
  "book_id": "book-uuid",
  "comment": "দারুণ বই!",
  "parent_id": null
}
```

**Success (201):**
```json
{
  "id": "new-comment-uuid",
  "comment": "দারুণ বই!",
  "created_at": "2026-04-05T16:00:00.000Z"
}
```

---

# 10. Orders & Payments

## POST /orders

Create a new order. **🔒 Auth required.**

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `items` | array | ✅ | Array of items to order |
| `items[].book_id` | uuid | ✅ | Book ID |
| `items[].format` | string | ✅ | `"ebook"`, `"audiobook"`, or `"hardcopy"` |
| `items[].quantity` | int | ❌ | Quantity (default: 1) |
| `shipping_address` | object | ❌ | Shipping info (for hardcopy) |
| `payment_method` | string | ❌ | `"online"` (default) or `"cod"` |

```json
{
  "items": [
    { "book_id": "book-uuid-1", "format": "ebook", "quantity": 1 },
    { "book_id": "book-uuid-2", "format": "hardcopy", "quantity": 2 }
  ],
  "shipping_address": {
    "name": "রহিম আহমেদ",
    "address": "৫৩ মিরপুর রোড, ঢাকা",
    "phone": "01712345678"
  },
  "payment_method": "online"
}
```

**Success (201):**

```json
{
  "order": {
    "id": "order-uuid",
    "order_number": "BOI-20260405-0001",
    "total_amount": 790,
    "status": "pending"
  }
}
```

**Error (400):**
```json
{ "error": "items required" }
```
```json
{ "error": "Format not found: book-uuid/audiobook" }
```

---

## GET /orders

Get order history. **🔒 Auth required.**

**Success (200):**

```json
{
  "orders": [
    {
      "id": "order-uuid",
      "order_number": "BOI-20260405-0001",
      "total_amount": 790,
      "status": "confirmed",
      "payment_method": "online",
      "created_at": "2026-04-05T10:00:00.000Z"
    },
    {
      "id": "order-uuid-2",
      "order_number": "BOI-20260404-0003",
      "total_amount": 90,
      "status": "pending",
      "payment_method": "online",
      "created_at": "2026-04-04T14:00:00.000Z"
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | uuid | Order ID |
| `order_number` | string | Human-readable order number |
| `total_amount` | float | Total in BDT |
| `status` | string | `"pending"`, `"awaiting_payment"`, `"confirmed"`, `"paid"`, `"processing"`, `"shipped"`, `"delivered"`, `"completed"`, `"cancelled"`, `"payment_failed"` |
| `payment_method` | string | `"online"` or `"cod"` |
| `created_at` | ISO 8601 | Order creation time |

---

## GET /orders/{order_id}

Get full order details with items. **🔒 Auth required.**

| Field | Details |
|-------|---------|
| **Path params** | `order_id` — UUID |

**Success (200):**

```json
{
  "id": "order-uuid",
  "order_number": "BOI-20260405-0001",
  "user_id": "user-uuid",
  "total_amount": 790,
  "status": "confirmed",
  "payment_method": "online",
  "shipping_name": "রহিম আহমেদ",
  "shipping_address": "৫৩ মিরপুর রোড, ঢাকা",
  "shipping_phone": "01712345678",
  "shipping_city": "Dhaka",
  "shipping_zip": "1216",
  "created_at": "2026-04-05T10:00:00.000Z",
  "updated_at": "2026-04-05T10:05:00.000Z",
  "order_items": [
    {
      "id": "item-uuid",
      "book_id": "book-uuid",
      "format": "ebook",
      "quantity": 1,
      "unit_price": 90,
      "total_price": 90,
      "books": {
        "id": "book-uuid",
        "title": "চাঁদের পাহাড়",
        "cover_url": "https://...",
        "slug": "chander-pahar"
      }
    }
  ]
}
```

**Error (404):**
```json
{ "error": "Order not found" }
```

---

## POST /payments/initiate

Initiate SSLCommerz payment for an order. **🔒 Auth required.**

**Request body:**

| Field | Type | Required |
|-------|------|----------|
| `order_id` | uuid | ✅ |

```json
{ "order_id": "order-uuid" }
```

**Success (200):**

```json
{
  "success": true,
  "gateway_url": "https://securepay.sslcommerz.com/gwprocess/v4?...",
  "session_key": "SSLsession123..."
}
```

| Field | Type | Description |
|-------|------|-------------|
| `gateway_url` | string | Redirect user to this URL to complete payment |
| `session_key` | string | SSLCommerz session key |

**Flutter integration:** Open `gateway_url` in a WebView. After payment, user is redirected back to the app's callback URL with `?status=success|failed|cancelled&order_id=...`.

**Error (500):**
```json
{ "error": "Payment initiation failed" }
```

---

## POST /payments/demo

Demo/test payment — instantly marks order as paid. **🔒 Auth required. Development only.**

**Request body:**
```json
{ "order_id": "order-uuid" }
```

**Success (200):**
```json
{ "message": "Payment completed (demo)" }
```

---

# 11. Wallet & Coins

## GET /wallet

Get coin balance. **🔒 Auth required.**

**Success (200):**

```json
{
  "balance": 250,
  "total_earned": 500,
  "total_spent": 250
}
```

| Field | Type | Description |
|-------|------|-------------|
| `balance` | int | Current coin balance |
| `total_earned` | int | Lifetime coins earned |
| `total_spent` | int | Lifetime coins spent |

---

## GET /wallet/transactions

Get coin transaction history. **🔒 Auth required.**

**Query params:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | int | 50 | Max 100 |

**Success (200):**

```json
{
  "transactions": [
    {
      "id": "tx-uuid-1",
      "amount": 10,
      "type": "earn",
      "description": "Daily login reward",
      "source": "daily_reward",
      "created_at": "2026-04-05T06:00:00.000Z",
      "expires_at": "2026-07-05T06:00:00.000Z"
    },
    {
      "id": "tx-uuid-2",
      "amount": -50,
      "type": "spend",
      "description": "Content unlock - ebook",
      "source": "content_unlock",
      "created_at": "2026-04-04T15:00:00.000Z",
      "expires_at": null
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | uuid | Transaction ID |
| `amount` | int | Positive = earned, Negative = spent |
| `type` | string | `"earn"` or `"spend"` |
| `description` | string | Human-readable description |
| `source` | string\|null | Source: `"daily_reward"`, `"ad_reward"`, `"content_unlock"`, `"purchase"`, `"referral"`, etc. |
| `created_at` | ISO 8601 | Transaction time |
| `expires_at` | ISO 8601\|null | Coin expiry (null = never) |

---

## POST /wallet/claim-daily

Claim daily login reward coins. **🔒 Auth required.**

**Request body:** None (empty `{}`)

**Success (200):** Returns reward data from the `claim_daily_login_reward` database function.

```json
{
  "success": true,
  "coins_awarded": 5,
  "streak_day": 3,
  "message": "Day 3 reward claimed!"
}
```

---

## POST /wallet/claim-ad

Claim ad watch reward. **🔒 Auth required.**

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `placement` | string | ❌ | Ad placement key (default: `"general"`) |

```json
{ "placement": "general" }
```

**Success (200):** Returns reward data from the `claim_ad_reward` database function.

---

## POST /wallet/unlock

Unlock content using coins. **🔒 Auth required.**

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `book_id` | uuid | ✅ | Book to unlock |
| `format` | string | ✅ | `"ebook"` or `"audiobook"` |
| `coin_cost` | int | ✅ | Coins to spend (from book format's `coin_price`) |

```json
{
  "book_id": "book-uuid",
  "format": "ebook",
  "coin_cost": 50
}
```

**Success (200):**
```json
{ "message": "Unlocked successfully" }
```

**Already unlocked:**
```json
{ "message": "Already unlocked", "already_unlocked": true }
```

**Error (400):**
```json
{ "error": "Coin deduction failed: insufficient balance" }
```

---

## GET /coin-packages

List available coin purchase packages. **No auth required.**

**Success (200):**

```json
{
  "packages": [
    {
      "id": "pkg-uuid-1",
      "name": "স্টার্টার",
      "coins": 50,
      "bonus_coins": 0,
      "price": 49,
      "is_featured": false,
      "sort_order": 1
    },
    {
      "id": "pkg-uuid-2",
      "name": "পপুলার",
      "coins": 200,
      "bonus_coins": 30,
      "price": 149,
      "is_featured": true,
      "sort_order": 2
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | uuid | Package ID |
| `name` | string | Package name |
| `coins` | int | Base coins included |
| `bonus_coins` | int | Extra bonus coins |
| `price` | float | Price in BDT |
| `is_featured` | bool | Highlighted package |
| `sort_order` | int | Display order |

---

# 12. Library

## GET /library/purchases

Get user's purchased books. **🔒 Auth required.**

**Query params:**

| Param | Type | Description |
|-------|------|-------------|
| `format` | string | Filter: `"ebook"`, `"audiobook"`, or `"hardcopy"` |

**Success (200):**

```json
{
  "purchases": [
    {
      "id": "purchase-uuid",
      "book_id": "book-uuid",
      "format": "ebook",
      "status": "active",
      "created_at": "2026-04-01T10:00:00.000Z",
      "books": {
        "id": "book-uuid",
        "title": "চাঁদের পাহাড়",
        "cover_url": "https://...",
        "slug": "chander-pahar",
        "authors": { "name": "বিভূতিভূষণ" }
      }
    }
  ]
}
```

---

## GET /library/unlocks

Get books unlocked with coins. **🔒 Auth required.**

**Success (200):**

```json
{
  "unlocks": [
    {
      "id": "unlock-uuid",
      "book_id": "book-uuid",
      "format": "ebook",
      "unlock_method": "coin",
      "created_at": "2026-04-02T12:00:00.000Z",
      "books": {
        "id": "book-uuid",
        "title": "পথের পাঁচালী",
        "cover_url": "https://...",
        "slug": "pather-panchali"
      }
    }
  ]
}
```

---

## GET /library/continue-reading

Get books with in-progress reading. **🔒 Auth required.**

**Success (200):**

```json
{
  "items": [
    {
      "book_id": "book-uuid",
      "current_page": 78,
      "total_pages": 320,
      "percentage": 24,
      "last_read_at": "2026-04-05T12:30:00.000Z",
      "books": {
        "id": "book-uuid",
        "title": "চাঁদের পাহাড়",
        "cover_url": "https://...",
        "slug": "chander-pahar",
        "authors": { "name": "বিভূতিভূষণ" }
      }
    }
  ]
}
```

Returns books where `0 < percentage < 100`, sorted by most recently read. Max 10 items.

---

## GET /library/continue-listening

Get audiobooks with in-progress listening. **🔒 Auth required.**

**Success (200):**

```json
{
  "items": [
    {
      "book_id": "book-uuid",
      "current_track": 3,
      "position_seconds": 245,
      "last_listened_at": "2026-04-05T14:00:00.000Z",
      "books": {
        "id": "book-uuid",
        "title": "পথের পাঁচালী",
        "cover_url": "https://...",
        "slug": "pather-panchali"
      }
    }
  ]
}
```

Max 10 items, sorted by most recently listened.

---

# 13. Subscriptions

## GET /subscriptions/plans

List active subscription plans. **No auth required.**

**Success (200):**

```json
{
  "plans": [
    {
      "id": "plan-uuid",
      "name": "প্রিমিয়াম মাসিক",
      "description": "সকল ইবুক ও অডিওবুকে সীমাহীন প্রবেশাধিকার",
      "price": 199,
      "duration_days": 30,
      "access_type": "all",
      "features": ["unlimited_ebooks", "unlimited_audiobooks", "no_ads"],
      "is_active": true
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | uuid | Plan ID |
| `name` | string | Plan name |
| `description` | string\|null | Plan description |
| `price` | float | Price in BDT |
| `duration_days` | int | Subscription duration |
| `access_type` | string | Content access level |
| `features` | string[]\|null | Feature list |
| `is_active` | bool | Plan availability |

---

## GET /subscriptions/my

Get current user's subscriptions. **🔒 Auth required.**

**Success (200):**

```json
{
  "subscriptions": [
    {
      "id": "sub-uuid",
      "plan_id": "plan-uuid",
      "status": "active",
      "start_date": "2026-04-01",
      "end_date": "2026-05-01",
      "subscription_plans": {
        "name": "প্রিমিয়াম মাসিক",
        "access_type": "all"
      }
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `status` | string | `"active"`, `"expired"`, `"cancelled"` |
| `start_date` | date | Subscription start |
| `end_date` | date | Subscription end |

---

# 14. Notifications

## GET /notifications

Get user notifications. **🔒 Auth required.** Returns most recent 50.

**Success (200):**

```json
{
  "notifications": [
    {
      "id": "notif-uuid",
      "title": "নতুন বই প্রকাশিত!",
      "message": "আপনার পছন্দের লেখকের নতুন বই এসেছে।",
      "type": "new_book",
      "is_read": false,
      "created_at": "2026-04-05T08:00:00.000Z"
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | uuid | Notification ID |
| `title` | string | Notification title |
| `message` | string | Notification body |
| `type` | string | Type: `"new_book"`, `"order_update"`, `"reward"`, `"system"`, etc. |
| `is_read` | bool | Read status |
| `created_at` | ISO 8601 | Notification time |

---

## POST /notifications/read

Mark notifications as read. **🔒 Auth required.**

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ids` | uuid[] | ❌ | Specific notification IDs. If omitted/empty, marks ALL as read. |

Mark specific:
```json
{ "ids": ["notif-uuid-1", "notif-uuid-2"] }
```

Mark all:
```json
{}
```

**Success (200):**
```json
{ "message": "Marked as read" }
```

---

# 15. Integration Flows

## Flow 1: Guest Browsing & Preview

```
1. GET /homepage                          → Home screen data
2. GET /categories                        → Category list
3. GET /books?category_id=xxx             → Browse category
4. GET /books/{slug}                      → Book detail page
5. GET /access/preview-eligibility?book_id=xxx&format=ebook  → Preview config
6. GET /books/{book_id}/tracks            → Audiobook track list
7. POST /content/audio-url                → Get preview audio (no auth)
   Body: { "book_id": "xxx", "track_number": 1 }
8. → User hits preview limit → Show "Sign in to continue" paywall
```

## Flow 2: Authentication & Profile

```
1. POST /auth/signup                      → Create account
   Body: { "email": "...", "password": "...", "display_name": "..." }
2. → User verifies email via link
3. POST /auth/login                       → Get tokens
   Body: { "email": "...", "password": "..." }
4. GET /profile                           → Load profile
5. GET /profile/roles                     → Check roles
6. → Store access_token + refresh_token securely
7. → Before token expires: POST /auth/refresh
```

## Flow 3: Purchase & Payment

```
1. POST /orders                           → Create order
   Body: { "items": [{ "book_id": "xxx", "format": "ebook" }] }
2. POST /payments/initiate                → Get payment URL
   Body: { "order_id": "<order_id from step 1>" }
3. → Open gateway_url in WebView
4. → User completes payment on SSLCommerz
5. → Redirect back to app with ?status=success&order_id=xxx
6. GET /orders/{order_id}                 → Verify order status
7. POST /access/check                     → Confirm access granted
   Body: { "book_id": "xxx", "format": "ebook" }
8. POST /content/ebook-url                → Get full content URL
```

## Flow 4: Coin Unlock

```
1. GET /wallet                            → Check balance
2. GET /books/{slug}                      → Get coin_price from formats
3. POST /wallet/unlock                    → Unlock content
   Body: { "book_id": "xxx", "format": "ebook", "coin_cost": 50 }
4. POST /content/ebook-url                → Get full content URL
```

## Flow 5: Reading Session                                                                                                                                                                           

```
1. GET /progress/reading?book_id=xxx      → Resume position
2. POST /content/ebook-url                → Get signed URL
3. → User reads in app
4. PUT /progress/reading                  → Save progress periodically
   Body: { "book_id": "xxx", "current_page": 120, "total_pages": 320 }
```

## Flow 6: Listening Session

```
1. GET /progress/listening?book_id=xxx    → Resume position
2. GET /books/{book_id}/tracks            → Track listing
3. POST /content/batch-audio-urls         → Get all track URLs
4. → User listens in app
5. PUT /progress/listening                → Save progress periodically
   Body: { "book_id": "xxx", "track_number": 3, "position_seconds": 245, "total_seconds": 750 }
```

---

# 16. Flutter Helper Class

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class BoiAroApi {
  static const _baseUrl =
      'https://kxpqejmjfnzhqcefyued.supabase.co/functions/v1/mobile-api';
  static const _apiKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4cHFlam1qZm56aHFjZWZ5dWVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzMzA0NjUsImV4cCI6MjA4OTkwNjQ2NX0.PSM2xT9QPzJmBU5yP7uKnQxVAvbpevAGF8wFw43i9to';

  String? accessToken;
  String? refreshToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'apikey': _apiKey,
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Future<Map<String, dynamic>> _get(String path,
      [Map<String, String>? queryParams]) async {
    final uri = Uri.parse('$_baseUrl/$path')
        .replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: _headers);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> _post(String path,
      [Map<String, dynamic>? body]) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : '{}',
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> _patch(String path,
      Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> _put(String path,
      Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final res = await http.delete(Uri.parse('$_baseUrl/$path'), headers: _headers);
    return jsonDecode(res.body);
  }

  // ─── Auth ───
  Future<Map<String, dynamic>> signup(
      String email, String password, String? displayName) =>
      _post('auth/signup', {
        'email': email, 'password': password,
        if (displayName != null) 'display_name': displayName,
      });

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _post('auth/login', {'email': email, 'password': password});
    if (data.containsKey('access_token')) {
      accessToken = data['access_token'];
      refreshToken = data['refresh_token'];
    }
    return data;
  }

  Future<Map<String, dynamic>> refresh() async {
    final data = await _post('auth/refresh', {'refresh_token': refreshToken});
    if (data.containsKey('access_token')) {
      accessToken = data['access_token'];
      refreshToken = data['refresh_token'];
    }
    return data;
  }

  Future<Map<String, dynamic>> logout() => _post('auth/logout');
  Future<Map<String, dynamic>> resetPassword(String email) =>
      _post('auth/reset-password', {'email': email});

  // ─── Profile ───
  Future<Map<String, dynamic>> getProfile() => _get('profile');
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updates) =>
      _patch('profile', updates);
  Future<Map<String, dynamic>> getRoles() => _get('profile/roles');

  // ─── Discovery ───
  Future<Map<String, dynamic>> getHomepage() => _get('homepage');
  Future<Map<String, dynamic>> getBooks({int limit = 20, int offset = 0,
      String? categoryId, bool? featured, bool? free, String? query}) =>
      _get('books', {
        'limit': '$limit', 'offset': '$offset',
        if (categoryId != null) 'category_id': categoryId,
        if (featured == true) 'featured': 'true',
        if (free == true) 'free': 'true',
        if (query != null) 'q': query,
      });
  Future<Map<String, dynamic>> getBook(String idOrSlug) =>
      _get('books/$idOrSlug');
  Future<Map<String, dynamic>> getCategories() => _get('categories');
  Future<Map<String, dynamic>> getAuthors({int limit = 20, int offset = 0}) =>
      _get('authors', {'limit': '$limit', 'offset': '$offset'});
  Future<Map<String, dynamic>> getAuthor(String id) => _get('authors/$id');
  Future<Map<String, dynamic>> getNarrators() => _get('narrators');
  Future<Map<String, dynamic>> getPublishers() => _get('publishers');
  Future<Map<String, dynamic>> search(String query) =>
      _get('search', {'q': query});

  // ─── Tracks ───
  Future<Map<String, dynamic>> getTracks(String bookId) =>
      _get('books/$bookId/tracks');

  // ─── Access ───
  Future<Map<String, dynamic>> checkAccess(String bookId, String format) =>
      _post('access/check', {'book_id': bookId, 'format': format});
  Future<Map<String, dynamic>> previewEligibility(String bookId,
      [String format = 'ebook']) =>
      _get('access/preview-eligibility',
          {'book_id': bookId, 'format': format});

  // ─── Content URLs ───
  Future<Map<String, dynamic>> getEbookUrl(String bookId) =>
      _post('content/ebook-url', {'book_id': bookId});
  Future<Map<String, dynamic>> getAudioUrl(String bookId,
      [int trackNumber = 1]) =>
      _post('content/audio-url',
          {'book_id': bookId, 'track_number': trackNumber});
  Future<Map<String, dynamic>> getBatchAudioUrls(String bookId) =>
      _post('content/batch-audio-urls', {'book_id': bookId});

  // ─── Progress ───
  Future<Map<String, dynamic>> getReadingProgress(String bookId) =>
      _get('progress/reading', {'book_id': bookId});
  Future<Map<String, dynamic>> saveReadingProgress(
      String bookId, int currentPage, int totalPages) =>
      _put('progress/reading', {
        'book_id': bookId,
        'current_page': currentPage,
        'total_pages': totalPages,
      });
  Future<Map<String, dynamic>> getListeningProgress(String bookId) =>
      _get('progress/listening', {'book_id': bookId});
  Future<Map<String, dynamic>> saveListeningProgress(
      String bookId, int track, int positionSec, int totalSec) =>
      _put('progress/listening', {
        'book_id': bookId,
        'track_number': track,
        'position_seconds': positionSec,
        'total_seconds': totalSec,
      });

  // ─── Bookmarks ───
  Future<Map<String, dynamic>> getBookmarks() => _get('bookmarks');
  Future<Map<String, dynamic>> addBookmark(String bookId) =>
      _post('bookmarks', {'book_id': bookId});
  Future<Map<String, dynamic>> removeBookmark(String bookId) =>
      _delete('bookmarks/$bookId');

  // ─── Reviews & Comments ───
  Future<Map<String, dynamic>> getReviews(String bookId) =>
      _get('books/$bookId/reviews');
  Future<Map<String, dynamic>> postReview(
      String bookId, int rating, [String? comment]) =>
      _post('reviews', {
        'book_id': bookId, 'rating': rating,
        if (comment != null) 'comment': comment,
      });
  Future<Map<String, dynamic>> getComments(String bookId) =>
      _get('books/$bookId/comments');
  Future<Map<String, dynamic>> postComment(
      String bookId, String comment, [String? parentId]) =>
      _post('comments', {
        'book_id': bookId, 'comment': comment,
        if (parentId != null) 'parent_id': parentId,
      });

  // ─── Orders ───
  Future<Map<String, dynamic>> createOrder(
      List<Map<String, dynamic>> items,
      {Map<String, dynamic>? shipping, String paymentMethod = 'online'}) =>
      _post('orders', {
        'items': items,
        if (shipping != null) 'shipping_address': shipping,
        'payment_method': paymentMethod,
      });
  Future<Map<String, dynamic>> getOrders() => _get('orders');
  Future<Map<String, dynamic>> getOrder(String orderId) =>
      _get('orders/$orderId');
  Future<Map<String, dynamic>> initiatePayment(String orderId) =>
      _post('payments/initiate', {'order_id': orderId});

  // ─── Wallet ───
  Future<Map<String, dynamic>> getWallet() => _get('wallet');
  Future<Map<String, dynamic>> getTransactions([int limit = 50]) =>
      _get('wallet/transactions', {'limit': '$limit'});
  Future<Map<String, dynamic>> claimDaily() => _post('wallet/claim-daily');
  Future<Map<String, dynamic>> claimAdReward([String placement = 'general']) =>
      _post('wallet/claim-ad', {'placement': placement});
  Future<Map<String, dynamic>> unlockContent(
      String bookId, String format, int coinCost) =>
      _post('wallet/unlock', {
        'book_id': bookId, 'format': format, 'coin_cost': coinCost,
      });
  Future<Map<String, dynamic>> getCoinPackages() => _get('coin-packages');

  // ─── Library ───
  Future<Map<String, dynamic>> getPurchases([String? format]) =>
      _get('library/purchases', {if (format != null) 'format': format});
  Future<Map<String, dynamic>> getUnlocks() => _get('library/unlocks');
  Future<Map<String, dynamic>> getContinueReading() =>
      _get('library/continue-reading');
  Future<Map<String, dynamic>> getContinueListening() =>
      _get('library/continue-listening');

  // ─── Subscriptions ───
  Future<Map<String, dynamic>> getPlans() => _get('subscriptions/plans');
  Future<Map<String, dynamic>> getMySubscriptions() =>
      _get('subscriptions/my');

  // ─── Notifications ───
  Future<Map<String, dynamic>> getNotifications() => _get('notifications');
  Future<Map<String, dynamic>> markRead([List<String>? ids]) =>
      _post('notifications/read', {if (ids != null) 'ids': ids});
}
```

---

# 17. Important Notes for Flutter Developer

1. **Token Management:** Store `access_token` and `refresh_token` securely (e.g. `flutter_secure_storage`). Access tokens expire in ~1 hour. Call `/auth/refresh` proactively.

2. **Guest vs Auth:** Books, categories, authors, narrators, publishers, search, homepage, preview eligibility, audio preview URLs, coin packages, subscription plans, reviews, and comments all work **without authentication**.

3. **Preview Enforcement:** Audio preview duration is enforced **client-side**. Use `preview_percentage` from `/access/preview-eligibility` to calculate the cutoff time. Stop playback and show paywall when the user reaches the limit.

4. **apikey Header:** Include the `apikey` header in **every** request (both guest and authenticated).

5. **Pagination:** Use `limit` (max 50) and `offset`. Check `total` for calculating page count.

6. **Error Handling:** All errors return `{ "error": "message" }`. Check HTTP status code first, then parse the error message.

7. **Signed URLs Expire:** Content URLs from `/content/*` endpoints expire in ~5 minutes. Request new URLs as needed.

8. **No SDK Required:** This API is 100% standard REST. Any HTTP client works.

9. **Payment WebView:** For SSLCommerz, open `gateway_url` in a WebView. Handle the redirect callback URL to detect payment result.

10. **Image URLs:** `cover_url`, `avatar_url`, `logo_url` are full HTTPS URLs. Load them directly with `CachedNetworkImage` or similar.

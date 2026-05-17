# MODULE 3 – DIGITAL SHOE PASSPORT (ARTICLES) DOCUMENTATION

## Table of Contents
1. [Overview](#overview)
2. [Complete User Flow](#complete-user-flow)
3. [API Endpoints](#api-endpoints)
4. [Architecture](#architecture)
5. [Screens](#screens)
6. [Domain & Data Models](#domain--data-models)
7. [Use Cases & DI](#use-cases--di)
8. [Integration with Other Modules](#integration-with-other-modules)

---

## Overview

Module 3 is the **Digital Shoe Passport**: each registered shoe is an **article** stored on `getmypair-api`. Users manage their collection in **My Rack** (list, create, view, edit, delete) with photos and material composition.

**Key features:**
- List all user articles (`GET /api/articles/my`)
- Add shoe with brand, model, category, color, condition, materials, images
- Upload images to Cloudinary via backend (`POST /api/articles/upload-image`)
- View rack detail UI with stats and service shortcuts
- Edit and delete existing articles
- Filter chips and shelf-style list UI on `ArticleListPage`

**Feature path:** `lib/features/articles/`

---

## Complete User Flow

### My Rack (list)

```
CustomerDashboardPage (tab: My Rack)
      ↓
ArticleListPage
      ↓
GET /api/articles/my  (via GetMyArticles + access token)
      ↓
Display shelf rows / filter chips
      ↓
Tap shoe → ArticleDetailsPage
Tap +     → ArticleCreatePage
```

### Add shoe

```
ArticleCreatePage
      ↓
User fills: brand, model, category, color, condition,
           optional purchase year, materials %, local photos
      ↓
POST /api/articles/create  (images: URLs after upload)
      ↓
Per image: POST /api/articles/upload-image (multipart, articleId)
      ↓
Navigate → ArticleDetailsPage(articleId)
```

### View / edit / delete

```
ArticleDetailsPage
      ↓
GET /api/articles/:id
      ↓
Actions: Edit → ArticleEditPage → PUT /api/articles/update/:id
         Delete → DELETE /api/articles/delete/:id → pop to list
```

### Service entry from rack

From article details or home, users can start Module 4 flows with a selected `articleId` (repair, wash, maintenance, donate, dispose).

---

## API Endpoints

Defined in `lib/core/constants/api_endpoints.dart`. All require `Authorization: Bearer <accessToken>` plus `X-App-Source` and `X-App-Version`.

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/articles/my` | List current user's articles |
| `GET` | `/api/articles/:id` | Single article by ID |
| `POST` | `/api/articles/create` | Create article |
| `PUT` | `/api/articles/update/:id` | Partial/full update |
| `DELETE` | `/api/articles/delete/:id` | Delete article |
| `POST` | `/api/articles/upload-image` | Multipart upload (`file`, field `articleId`) |

### POST /api/articles/create

**Body (representative):**
```json
{
  "brand": "Nike",
  "model": "Air Max",
  "category": "sports_shoe",
  "color": "White/Blue",
  "condition": "good",
  "purchaseYear": 2023,
  "materials": [
    { "type": "Leather", "percentage": 60 },
    { "type": "Mesh", "percentage": 40 }
  ],
  "images": ["https://res.cloudinary.com/.../image1.jpg"]
}
```

**Categories (UI):** `sports_shoe`, `casual`, `formal`, `sandal`, `boot`, `slipper`, `other`

**Conditions (UI):** `excellent`, `good`, `fair`, `worn`

**Response:** `{ "data": { "article": { ... } } }` (parsed by `ArticleRemoteDataSource`)

### POST /api/articles/upload-image

Multipart: `file` (bytes), `articleId` (string field).

**Response:** URL in `data` (string) or `data.imageUrl` / `data.url` / `data.image`.

---

## Architecture

```
Presentation (pages, no BLoC — StatefulWidget + use cases)
      ↓
Domain use cases (GetMyArticles, GetArticleById, CreateArticle, …)
      ↓
ArticleRepository → ArticleRepositoryImpl
      ↓
ArticleRemoteDataSource (package:http)
      ↓
getmypair-api /api/articles/*
```

**Token access:** Pages call `GetValidAccessToken` from `injection_container` before API use cases.

---

## Screens

### 1. ArticleListPage

**File:** `lib/features/articles/presentation/pages/article_list_page.dart`

**Purpose:** My Rack — gradient shell, filter chips, horizontal shelf rows, FAB to add shoe.

**Data:** Loads articles on init via `GetMyArticles`.

**Navigation:**
- Tap item → `ArticleDetailsPage(articleId)`
- FAB / add → `ArticleCreatePage`
- Optional chatbot route (`ChatbotPage`)

**Dashboard:** Shown as tab 2 inside `CustomerDashboardPage` with `showBottomBar: false` (parent provides nav).

---

### 2. ArticleCreatePage

**File:** `lib/features/articles/presentation/pages/article_create_page.dart`

**Purpose:** Manual entry form (no auto-fill). Default demo values for brand/model in dev UI.

**Flow:**
1. Pick multiple images (`image_picker`)
2. On submit: `CreateArticle` then `UploadArticleImage` per file
3. Success → `ArticleDetailsPage`

---

### 3. ArticleDetailsPage

**File:** `lib/features/articles/presentation/pages/article_details_page.dart`

**Purpose:** Figma-style rack detail — hero image (`rackHeroImagePath` = last image), stats, edit/delete, links to care services.

**Data:** `GetArticleById` on load.

---

### 4. ArticleEditPage

**File:** `lib/features/articles/presentation/pages/article_edit_page.dart`

**Purpose:** Edit existing shoe; `PUT /api/articles/update/:articleId` with prefilled selects (category, condition, materials).

---

## Domain & Data Models

### Article (entity)

**File:** `lib/features/articles/domain/entities/article.dart`

| Field | Type | Notes |
|-------|------|--------|
| `id` | String | Mongo `_id` |
| `ownerId` | String | User owner |
| `brand`, `model`, `category`, `color` | String | Core metadata |
| `purchaseYear` | int? | Optional |
| `materials` | `List<ArticleMaterial>` | type + percentage |
| `condition` | String | excellent / good / fair / worn |
| `images` | `List<String>` | Cloudinary URLs |
| `createdAt` | DateTime | |
| `shoeSize` | String? | API aliases: size, usSize |
| `lastWornAt`, `lastShoeCareAt` | DateTime? | Wear / care tracking |

**Helpers:**
- `thumbnailImage` — first image
- `rackHeroImagePath` — last image (primary in UI)

### ArticleModel

**File:** `lib/features/articles/data/models/article_model.dart`

- `fromJson` / `toJson` with flexible Mongo date and image shapes

---

## Use Cases & DI

Registered in `lib/injection_container.dart`:

| Use case | Role |
|----------|------|
| `GetMyArticles` | List for rack |
| `GetArticleById` | Detail, service summary, Module 4 |
| `CreateArticle` | New passport |
| `UpdateArticle` | Edit |
| `DeleteArticle` | Remove |
| `UploadArticleImage` | Multipart after create or on edit |

**Repository:** `ArticleRepository` / `ArticleRepositoryImpl`  
**Remote:** `ArticleRemoteDataSourceImpl` (`lib/features/articles/data/datasources/article_remote_datasource.dart`)

---

## Integration with Other Modules

| Module | Integration |
|--------|-------------|
| **1 – Auth** | `GetValidAccessToken` for every API call |
| **2 – Profile** | Addresses used when creating service requests for an article |
| **4 – Service** | `articleId` required on `POST /api/service/create`; hero image from `Article.rackHeroImagePath` |

**Route:** `AppRoutes.articleList` → `/articles` → `ArticleListPage`

---

## Related Files

- `lib/core/constants/api_endpoints.dart` — article URLs
- `lib/core/widgets/article_rack_shoe_image.dart` — shared rack thumbnail
- `lib/features/home/presentation/pages/home_page.dart` — shortcuts to rack / create

---

**End of Module 3 Documentation**

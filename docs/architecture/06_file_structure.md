# ファイル構成

## 概要

このドキュメントでは、プロジェクトのファイル構成とディレクトリ構造を詳細に説明します。

---

## プロジェクト全体構造

```
battle_for_the_cats/
├── lib/                      # アプリケーションコード
│   ├── main.dart            # エントリーポイント
│   ├── constants/           # 定数・Enum
│   ├── domain/              # ドメインロジック
│   ├── models/              # データモデル
│   ├── repositories/        # リポジトリ層
│   ├── services/            # サービス層
│   └── screens/             # 画面（Presentation層）
├── test/                     # テストコード
├── docs/                     # ドキュメント
│   └── architecture/        # アーキテクチャドキュメント
├── android/                  # Androidプラットフォーム固有
├── ios/                      # iOSプラットフォーム固有
├── web/                      # Webプラットフォーム固有
├── windows/                  # Windowsプラットフォーム固有
├── linux/                    # Linuxプラットフォーム固有
├── macos/                    # macOSプラットフォーム固有
├── pubspec.yaml             # 依存関係定義
├── analysis_options.yaml    # Lintルール
└── README.md                # プロジェクト説明
```

---

## lib/ディレクトリ詳細

### 完全なファイルツリー

```
lib/
├── main.dart                                    (約100行) - エントリーポイント
│
├── constants/                                   【定数・Enum】
│   └── game_constants.dart                     (74行)
│       ├── GameConstants (static class)
│       ├── GameStatus (enum)
│       ├── MatchmakingStatus (enum)
│       └── Winner (enum)
│
├── domain/                                      【ドメイン層】
│   └── game_logic.dart                         (184行)
│       ├── GameLogic (class)
│       ├── RoundResult (class)
│       └── ClipResult (class)
│
├── models/                                      【データモデル】
│   └── game_room.dart                          (約150行)
│       └── GameRoom (class)
│
├── repositories/                                【リポジトリ層】
│   ├── firestore_repository.dart               (104行)
│   │   ├── FirestoreRepository (base class)
│   │   └── QueryFilter (helper class)
│   │
│   └── room_repository.dart                    (82行)
│       └── RoomRepository (extends FirestoreRepository)
│
├── services/                                    【サービス層】
│   ├── game_service.dart                       (58行)
│   │   └── GameService (Facade)
│   │
│   ├── room_service.dart                       (71行)
│   │   └── RoomService
│   │
│   ├── matchmaking_service.dart                (160行)
│   │   └── MatchmakingService
│   │
│   └── game_flow_service.dart                  (131行)
│       └── GameFlowService
│
└── screens/                                     【Presentation層】
    │
    ├── home/                                    【ホーム画面】
    │   ├── home_screen.dart                    (62行) - Entry Point
    │   ├── home_screen_view_model.dart         (161行)
    │   ├── home_screen_state.dart              (46行)
    │   └── views/
    │       ├── main_menu_view.dart             (106行)
    │       └── matchmaking_view.dart           (51行)
    │
    └── game/                                    【ゲーム画面】
        ├── game_screen.dart                    (100行) - Entry Point
        ├── game_screen_view_model.dart         (155行)
        ├── game_screen_state.dart              (95行)
        ├── player_data.dart                    (18行) - Helper
        └── views/
            ├── waiting_view.dart               (40行)
            ├── rolling_phase_view.dart         (160行)
            ├── betting_phase_view.dart         (220行)
            ├── round_result_view.dart          (165行)
            └── final_result_view.dart          (105行)
```

---

## 層別ファイル分類

### Presentation Layer (画面・UI)

```
lib/screens/
├── home/
│   ├── home_screen.dart              - Provider設定 + Navigator
│   ├── home_screen_view_model.dart   - 状態管理 + ビジネスロジック
│   ├── home_screen_state.dart        - 型安全な状態クラス
│   └── views/
│       ├── main_menu_view.dart       - メインメニューUI
│       └── matchmaking_view.dart     - マッチング中UI
│
└── game/
    ├── game_screen.dart              - Provider設定 + Navigator
    ├── game_screen_view_model.dart   - 状態管理 + Stream監視
    ├── game_screen_state.dart        - 型安全な状態クラス
    ├── player_data.dart              - Host/Guest切替ヘルパー
    └── views/
        ├── waiting_view.dart         - 相手待機中UI
        ├── rolling_phase_view.dart   - サイコロフェーズUI
        ├── betting_phase_view.dart   - ベットフェーズUI
        ├── round_result_view.dart    - ラウンド結果UI
        └── final_result_view.dart    - 最終結果UI
```

**特徴**:
- 1画面 = 1ディレクトリ
- MVVM構成: Screen (View) + ViewModel + State + Views
- Viewsサブディレクトリで詳細UIを分離

---

### Service Layer (ビジネスロジック調整)

```
lib/services/
├── game_service.dart            - Facade: 統一インターフェース
├── room_service.dart            - 部屋のライフサイクル管理
├── matchmaking_service.dart     - ランダムマッチング処理
└── game_flow_service.dart       - ゲーム進行制御
```

**責務**:
- `GameService`: 他3サービスへのFacade
- `RoomService`: 部屋作成・参加・削除
- `MatchmakingService`: キュー管理・マッチング
- `GameFlowService`: サイコロ・ベット・ターン管理

---

### Domain Layer (純粋なビジネスロジック)

```
lib/domain/
└── game_logic.dart              - ゲームルール実装
    ├── GameLogic               - Pure Functions
    ├── RoundResult             - ラウンド結果データ
    └── ClipResult              - 足切り結果データ
```

**特徴**:
- Firestoreに依存しない
- 全てPure Functions
- テストが容易

---

### Repository Layer (データアクセス)

```
lib/repositories/
├── firestore_repository.dart    - Firestore操作の抽象化
│   ├── FirestoreRepository     - Base class (CRUD + Stream)
│   └── QueryFilter             - クエリヘルパー
│
└── room_repository.dart         - Room専用データアクセス
    └── RoomRepository          - Extends FirestoreRepository
```

**継承関係**:
```
FirestoreRepository (汎用)
    ↑
    | extends
    |
RoomRepository (Room専用)
```

---

### Data Models (データ構造)

```
lib/models/
└── game_room.dart               - GameRoomモデル
    └── GameRoom                - Firestoreドキュメント構造
```

**責務**:
- Firestoreドキュメントとの変換 (`toMap()`, `fromMap()`)
- データ構造の定義

---

### Constants (定数・Enum)

```
lib/constants/
└── game_constants.dart          - 定数とEnum定義
    ├── GameConstants           - static定数
    ├── GameStatus              - ゲーム状態Enum
    ├── MatchmakingStatus       - マッチング状態Enum
    └── Winner                  - 勝者Enum
```

---

## ファイルサイズ統計

### 層別の合計行数

| 層 | ファイル数 | 合計行数 | 平均行数 |
|---|---|---|---|
| **Presentation** | 12 | 約1,100行 | 約92行 |
| **Service** | 4 | 420行 | 105行 |
| **Domain** | 1 | 184行 | 184行 |
| **Repository** | 2 | 186行 | 93行 |
| **Models** | 1 | 150行 | 150行 |
| **Constants** | 1 | 74行 | 74行 |
| **合計** | 21 | 約2,114行 | 約101行 |

**考察**:
- 1ファイルあたり平均100行程度で適切に分割
- 最大でも220行（`betting_phase_view.dart`）でUI複雑度に起因
- MVVM化により、旧GameScreen (739行) → 9ファイルに分散

---

## ディレクトリ構造の設計原則

### 1. 層別ディレクトリ構成

```
lib/
├── constants/     ← 最下層（依存なし）
├── domain/        ← 純粋ロジック（constants依存のみ）
├── models/        ← データ構造（domain依存）
├── repositories/  ← データアクセス（models依存）
├── services/      ← ビジネスロジック（repositories, domain依存）
└── screens/       ← UI（services依存）
```

**依存方向**: 上から下への単方向

---

### 2. 画面単位でのディレクトリ分離

```
screens/
├── home/          - ホーム画面関連すべて
└── game/          - ゲーム画面関連すべて
```

**利点**:
- 画面追加時の影響範囲が明確
- 画面ごとに独立してリファクタリング可能

---

### 3. MVVMパターンの統一

各画面は以下の構成を持つ：

```
screen_name/
├── <screen_name>_screen.dart         - Entry Point (Provider設定)
├── <screen_name>_view_model.dart     - ViewModel (ChangeNotifier)
├── <screen_name>_state.dart          - State (型安全)
└── views/                            - 詳細UI
    ├── <specific>_view.dart
    └── ...
```

**一貫性**: 全画面で同じパターン適用

---

## Import パス規則

### 相対パスは使わない

❌ **悪い例**:
```dart
import '../services/game_service.dart';
import '../../models/game_room.dart';
```

✅ **良い例**:
```dart
import 'package:battle_for_the_cats/services/game_service.dart';
import 'package:battle_for_the_cats/models/game_room.dart';
```

### 層をまたぐ場合のImport

```dart
// Presentation層 → Service層
import 'package:battle_for_the_cats/services/game_service.dart';

// Service層 → Repository層
import 'package:battle_for_the_cats/repositories/room_repository.dart';

// Service層 → Domain層
import 'package:battle_for_the_cats/domain/game_logic.dart';
```

---

## ファイル命名規則

### 1. スネークケース（Dart標準）

- ファイル名: `home_screen_view_model.dart`
- クラス名: `HomeScreenViewModel`

### 2. 接尾辞の使用

| 種類 | 接尾辞 | 例 |
|-----|-------|---|
| Screen | `_screen.dart` | `home_screen.dart` |
| ViewModel | `_view_model.dart` | `home_screen_view_model.dart` |
| State | `_state.dart` | `home_screen_state.dart` |
| Service | `_service.dart` | `game_service.dart` |
| Repository | `_repository.dart` | `room_repository.dart` |
| Model | なし | `game_room.dart` |
| View (UI部品) | `_view.dart` | `main_menu_view.dart` |

---

## 今後の拡張時の配置例

### 新しい画面を追加する場合

```
lib/screens/
├── home/
├── game/
└── settings/                        ← 新規追加
    ├── settings_screen.dart
    ├── settings_view_model.dart
    ├── settings_state.dart
    └── views/
        ├── profile_view.dart
        └── preferences_view.dart
```

### 新しいServiceを追加する場合

```
lib/services/
├── game_service.dart
├── room_service.dart
├── matchmaking_service.dart
├── game_flow_service.dart
└── analytics_service.dart           ← 新規追加
```

### 新しいRepositoryを追加する場合

```
lib/repositories/
├── firestore_repository.dart
├── room_repository.dart
└── user_repository.dart             ← 新規追加
```

---

## docs/ディレクトリ構造

```
docs/
└── architecture/                    - アーキテクチャドキュメント
    ├── README.md                   - 目次
    ├── 01_overview.md              - アーキテクチャ概要
    ├── 02_mvvm_home.md             - HomeScreen MVVM
    ├── 03_mvvm_game.md             - GameScreen MVVM
    ├── 04_class_diagram.md         - クラス関係図
    ├── 05_data_flow.md             - データフロー詳細
    └── 06_file_structure.md        - ファイル構成（本ドキュメント）
```

---

## test/ディレクトリ構造（推奨）

```
test/
├── unit/                            - 単体テスト
│   ├── domain/
│   │   └── game_logic_test.dart
│   ├── repositories/
│   │   └── room_repository_test.dart
│   └── services/
│       └── room_service_test.dart
│
├── widget/                          - Widgetテスト
│   └── screens/
│       ├── home_screen_test.dart
│       └── game_screen_test.dart
│
└── integration/                     - 統合テスト
    └── game_flow_test.dart
```

---

## VS Code での推奨設定

### .vscode/settings.json

```json
{
  "files.exclude": {
    "**/.dart_tool": true,
    "**/.git": true,
    "**/build": true
  },
  "search.exclude": {
    "**/build": true,
    "**/.dart_tool": true
  },
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.rulers": [80]
  }
}
```

---

## 関連ドキュメント

- [01_overview.md](./01_overview.md) - アーキテクチャ概要
- [02_mvvm_home.md](./02_mvvm_home.md) - HomeScreenのMVVM構造
- [03_mvvm_game.md](./03_mvvm_game.md) - GameScreenのMVVM構造
- [04_class_diagram.md](./04_class_diagram.md) - クラス関係図
- [05_data_flow.md](./05_data_flow.md) - データフロー詳細

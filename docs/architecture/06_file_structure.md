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
├── main.dart                                    (約50行) - エントリーポイント
├── firebase_options.dart                        (自動生成) - Firebase設定
│
├── constants/                                   【定数・Enum】
│   └── game_constants.dart                     (72行)
│       ├── GameConstants (static class)
│       ├── GameStatus (enum)
│       ├── MatchmakingStatus (enum)
│       └── Winner (enum)
│
├── domain/                                      【ドメイン層：純粋ロジック】
│   ├── battle_evaluator.dart                   (37行) - 勝敗捕捉判定
│   ├── round_resolver.dart                     (約60行) - ラウンド遷移制御
│   ├── dice.dart                               (21行) - サイコロインターフェース
│   └── win_condition.dart                      (52行) - 勝利条件判定
│
├── models/                                      【モデル層：データ構造と自己完結ロジック】
│   ├── game_room.dart                          (188行) - 部屋の状態管理
│   ├── player.dart                             (118行) - プレイヤーの状態管理
│   ├── bets.dart                               (約40行) - 賭け金管理
│   ├── round_result.dart                       (60行) - ラウンド結果
│   ├── round_winners.dart                      (約30行) - 勝者マップ
│   ├── won_cat.dart                            (約20行) - 獲得した猫のデータ
│   ├── cat_inventory.dart                      (約50行) - 猫のコレクション
│   └── cards/                                   【カード定義（静的データ）】
│       ├── round_cards.dart                    (約80行) - ラウンドの3枚
│       ├── game_card.dart                      (約40行) - 基本カード
│       ├── regular_cat.dart                    (約70行) - 通常の猫
│       ├── boss_cat.dart                       (約70行) - ボス猫
│       ├── fisherman.dart                      (約60行) - 漁師
│       ├── item_shop.dart                      (約60行) - アイテム屋
│       └── dog.dart                             (約70行) - 犬
│
├── repositories/                                【リポジトリ層：データアクセス】
│   ├── firestore_repository.dart               (104行)
│   └── room_repository.dart                    (82行)
│
├── services/                                    【サービス層：ユースケース】
│   ├── game_service.dart                       (約100行) - Facade
│   ├── room_service.dart                       (82行) - 部屋管理
│   ├── matchmaking_service.dart                (204行) - マッチング
│   └── game_flow_service.dart                  (110行) - ゲーム進行制御
│
└── screens/                                     【プレゼンテーション層：UI】
    ├── home/                                    【ホーム画面】
    │   ├── home_screen.dart                    (約60行)
    │   ├── home_screen_view_model.dart         (195行)
    │   ├── home_screen_state.dart              (約50行)
    │   └── views/
    │       ├── main_menu_view.dart             (約120行)
    │       └── matchmaking_view.dart           (約60行)
    │
    └── game/                                    【ゲーム画面】
        ├── game_screen.dart                    (約120行)
        ├── game_screen_view_model.dart         (434行)
        ├── game_screen_state.dart              (約120行)
        ├── player_data.dart                    (約150行)
        └── views/
            ├── waiting_view.dart               (約50行)
            ├── rolling_phase_view.dart         (約200行)
            ├── betting_phase_view.dart         (約250行)
            ├── round_result_view.dart          (約200行)
            └── final_result_view.dart          (約120行)
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
│   └── views/                        - サブビュー
│
└── game/
    ├── game_screen.dart              - Provider設定 + Navigator
    ├── game_screen_view_model.dart   - 状態管理 + Stream監視
    ├── game_screen_state.dart        - 型安全な状態クラス
    ├── player_data.dart              - 表示用データの集約・加工
    └── views/                        - フェーズごとのUI部品
```

**特徴**:
- **player_data.dart**: ホスト/ゲストの差異を吸収し、ViewModelがUIに向けた情報を整理するために使用。
- **GameScreenViewModel**: 最も複雑な状態管理（Stream監視、フェーズ遷移、ローカル入力）を担当。

---

### Service Layer (ビジネスロジック調整)

```
lib/services/
├── game_service.dart            - Facade: プレゼンテーション層への単一窓口
├── room_service.dart            - 部屋の基本的なライフサイクル
├── matchmaking_service.dart     - トランザクションを用いた高度なマッチング
└── game_flow_service.dart       - サイコロ・ベット・確定操作のワークフロー
```

---

### Domain Layer (純粋なビジネスロジック)

```
lib/domain/
├── battle_evaluator.dart        - 猫の足切り・勝敗判定ロジック
├── dice.dart                    - サイコロの抽選アルゴリズム
└── win_condition.dart           - 最終的な勝利判定（タイブレーク含む）
```

**特徴**:
- **インターフェース化**: `Dice` や `WinCondition` を abstract class とすることで、テスト時のモック化やルール変更を容易にしている。

---

### Models Layer (データ構造と自己完結ロジック)

```
lib/models/
├── game_room.dart               - ルーム全体のドキュメント構造と、ラウンド解決ロジック 
├── player.dart                  - 個々のプレイヤーの状態と、サイコロ・ベット等の行為
└── cards/                       - 猫の種類、コスト、エフェクト等の静的データ
```

---

### Repository Layer (データアクセス)

```
lib/repositories/
├── firestore_repository.dart    - 汎用的なFirestoreアクセスの抽象化
└── room_repository.dart         - `rooms` コレクションに特化した操作
```

---

## ファイルサイズ統計

### 層別の合計行数（概算）

| 層 | ファイル数 | 合計行数 | 特徴 |
|---|---|---|---|
| **Presentation** | 15 | 約2,400行 | ViewModelや詳細UIの分割が進んでいる |
| **Service** | 4 | 約500行 | マッチングとゲームフローに重み |
| **Domain** | 4 | 約170行 | RoundResolverによるオーケストレーション |
| **Models** | 16 | 約1,100行 | 特殊カードクラスの拡充 |
| **Repository** | 2 | 約200行 | 抽象化により簡潔 |
| **Constants** | 1 | 80行 | 定数・Enumの集約 |
| **合計** | 42 | 約4,450行 | 機能追加に伴いモデルとドメインが成長 |

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

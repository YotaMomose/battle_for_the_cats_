# アーキテクチャ概要

## 5層アーキテクチャ構成

このプロジェクトは、Clean Architectureの原則に基づいた5層構造を採用しています。

```mermaid
graph TB
    subgraph "Presentation Layer"
        View[View<br/>Stateless Widgets]
        ViewModel[ViewModel<br/>ChangeNotifier]
        State[State<br/>Typed State Classes]
    end
    
    subgraph "Service Layer"
        GameService[GameService<br/>Facade]
        RoomService[RoomService]
        MatchmakingService[MatchmakingService]
        GameFlowService[GameFlowService]
    end
    
    subgraph "Domain Layer"
        GameLogic[GameLogic<br/>Pure Functions]
        RoundResult[RoundResult]
    end
    
    subgraph "Repository Layer"
        RoomRepository[RoomRepository]
        FirestoreRepository[FirestoreRepository<br/>Abstraction]
    end
    
    subgraph "Data Layer"
        Firestore[(Cloud Firestore)]
    end
    
    View -->|context.watch| ViewModel
    ViewModel -->|notifyListeners| View
    ViewModel -->|Dependency Injection| GameService
    
    GameService -->|delegate| RoomService
    GameService -->|delegate| MatchmakingService
    GameService -->|delegate| GameFlowService
    
    RoomService -->|use| RoomRepository
    RoomService -->|use| GameLogic
    MatchmakingService -->|use| FirestoreRepository
    MatchmakingService -->|use| RoomService
    MatchmakingService -->|use| GameLogic
    GameFlowService -->|use| RoomRepository
    GameFlowService -->|use| GameLogic
    
    RoomRepository -->|extends| FirestoreRepository
    FirestoreRepository -->|CRUD + Stream| Firestore
    
    style View fill:#e1f5ff
    style ViewModel fill:#e1f5ff
    style State fill:#e1f5ff
    style GameService fill:#fff4e1
    style RoomService fill:#fff4e1
    style MatchmakingService fill:#fff4e1
    style GameFlowService fill:#fff4e1
    style GameLogic fill:#f0fff0
    style RoundResult fill:#f0fff0
    style RoomRepository fill:#ffe1f5
    style FirestoreRepository fill:#ffe1f5
    style Firestore fill:#f5f5f5
```

## 各層の責務

### 1. Presentation Layer（プレゼンテーション層）

**責務**: UI表示とユーザー操作の処理

**構成要素**:
- **View**: Statelessな画面ウィジェット
  - `HomeScreen`, `GameScreen`
  - `MainMenuView`, `MatchmakingView`
  - `WaitingView`, `RollingPhaseView`, `BettingPhaseView`, `RoundResultView`, `FinalResultView`
- **ViewModel**: ビジネスロジックと状態管理
  - `HomeScreenViewModel` (161行)
  - `GameScreenViewModel` (155行)
  - `ChangeNotifier`を継承
  - Serviceレイヤーへの依存性注入
- **State**: 型安全な状態表現
  - `HomeScreenState` (3状態: Idle, Loading, Matchmaking)
  - `GameScreenState` (6状態: Loading, Waiting, Rolling, Playing, RoundResult, Finished)

**パターン**:
- MVVM (Model-View-ViewModel)
- State Pattern (型安全な状態管理)
- Observer Pattern (Provider + ChangeNotifier)

---

### 2. Service Layer（サービス層）

**責務**: ビジネスロジックの調整とワークフローの制御

**構成要素**:
- **GameService** (58行): Facadeパターンで統一インターフェース提供
- **RoomService** (71行): 部屋のライフサイクル管理
- **MatchmakingService** (160行): ランダムマッチング処理
- **GameFlowService** (131行): ゲーム進行制御（サイコロ、ベット、ターン管理）

**パターン**:
- Facade Pattern (GameService)
- Transaction Control (マッチング処理)
- Dependency Injection (全サービス)

---

### 3. Domain Layer（ドメイン層）

**責務**: 純粋なビジネスロジック（Firestoreに依存しない）

**構成要素**:
- **GameLogic** (184行): ゲームルールの実装
  - `rollDice()`: サイコロを振る
  - `generateRoomCode()`: 部屋コード生成
  - `resolveRound()`: ラウンド決着処理
  - `checkWinCondition()`: 勝利条件判定
- **RoundResult**: ラウンド結果を表すデータクラス

**特徴**:
- Pure Functions（副作用なし）
- テスタビリティが高い
- 再利用性が高い

---

### 4. Repository Layer（リポジトリ層）

**責務**: データアクセスの抽象化

**構成要素**:
- **FirestoreRepository** (104行): Firestore操作の抽象化
  - CRUD操作: `getDocument()`, `setDocument()`, `updateDocument()`, `deleteDocument()`
  - Stream: `watchDocument()`
  - クエリ: `query()` with filters
  - トランザクション: `runTransaction()`
- **RoomRepository** (82行): 部屋データ専用のアクセス層
  - `getRoom()`, `createRoom()`, `updateRoom()`, `deleteRoom()`, `watchRoom()`
  - ヘルパーメソッド: `isHost()`, `getPlayerField()`, `updatePlayerData()`

**パターン**:
- Repository Pattern
- Dependency Inversion (抽象に依存)

---

### 5. Data Layer（データ層）

**責務**: 永続化されたデータの管理

**構成要素**:
- **Cloud Firestore**: NoSQLデータベース
  - リアルタイム同期
  - `snapshots()` Streamによる変更監視

---

## データフロー

### 読み取りフロー（リアルタイム同期）

```mermaid
sequenceDiagram
    participant F as Firestore
    participant FR as FirestoreRepository
    participant RR as RoomRepository
    participant S as Service
    participant VM as ViewModel
    participant V as View
    
    F->>FR: snapshots() Stream
    FR->>RR: watchDocument()
    RR->>S: watchRoom()
    S->>VM: Stream.listen()
    VM->>VM: _updateUiState()
    VM->>V: notifyListeners()
    V->>V: rebuild()
```

### 書き込みフロー（ユーザー操作）

```mermaid
sequenceDiagram
    participant V as View
    participant VM as ViewModel
    participant S as Service
    participant RR as RoomRepository
    participant FR as FirestoreRepository
    participant F as Firestore
    
    V->>VM: rollDice()
    VM->>S: rollDice(roomCode)
    S->>RR: updateRoom()
    RR->>FR: updateDocument()
    FR->>F: update()
    Note over F: データ変更
    F-->>FR: snapshots()通知
    Note over FR,V: 読み取りフローに続く
```

---

## 採用デザインパターン

| パターン | 適用箇所 | 目的 |
|---------|---------|------|
| **MVVM** | Presentation層 | UIとロジックの分離 |
| **State Pattern** | State classes | 型安全な状態管理 |
| **Facade Pattern** | GameService | 統一インターフェース |
| **Repository Pattern** | Repository層 | データアクセス抽象化 |
| **Dependency Injection** | 全層 | テスタビリティ向上 |
| **Observer Pattern** | Provider + Stream | リアルタイム同期 |
| **Factory Pattern** | State constructors | 状態オブジェクト生成 |

---

## リアルタイム同期の仕組み

ViewModelは初期化時にFirestoreのStream監視を開始します：

```dart
// GameScreenViewModel._init()
_roomSubscription = _gameService.watchRoom(roomCode).listen(
  (room) {
    _currentRoom = room;        // ① 最新データを保持
    _updateUiState(room);       // ② UI状態を判定
    _checkTurnChange(room);     // ③ ターン変更をチェック
    notifyListeners();          // ④ Viewに通知
  }
);
```

これにより、Firestoreのデータが変更されると自動的にUIが更新されます。

---

## アーキテクチャの利点

### 1. **テスタビリティ**
- 各層が独立しているため、モックを使った単体テストが容易
- Domain層は純粋関数のため、テストが簡単

### 2. **保守性**
- 責務が明確に分離されている
- 1ファイルあたり50〜200行程度で管理しやすい

### 3. **拡張性**
- 新機能追加時、影響範囲が限定的
- Repositoryを差し替えることで、Firestore以外のDBに変更可能

### 4. **型安全性**
- State Patternにより、存在しない状態への遷移を防止
- コンパイル時に多くのエラーを検出

### 5. **リアルタイム対応**
- Stream-based architectureにより、自然にリアルタイム同期を実現
- ポーリング不要で効率的

---

## 関連ドキュメント

- [02_mvvm_home.md](./02_mvvm_home.md) - HomeScreenのMVVM構造
- [03_mvvm_game.md](./03_mvvm_game.md) - GameScreenのMVVM構造
- [04_class_diagram.md](./04_class_diagram.md) - クラス関係図
- [05_data_flow.md](./05_data_flow.md) - データフロー詳細
- [06_file_structure.md](./06_file_structure.md) - ファイル構成

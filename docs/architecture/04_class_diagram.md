# クラス関係図

## 概要

このドキュメントでは、プロジェクト内の主要クラス間の関係を図示します。

---

## 全体クラス関係図

```mermaid
classDiagram
    %% Presentation Layer
    class HomeScreen {
        +build() Widget
    }
    
    class HomeScreenViewModel {
        -GameService _gameService
        -HomeScreenState _state
        -StreamSubscription _matchmakingSubscription
        +createRoom() Future~void~
        +startRandomMatch() Future~void~
        +joinRoom(String roomCode) Future~void~
        +cancelMatchmaking() Future~void~
        +dispose() void
    }
    
    class HomeScreenState {
        <<abstract>>
        +String? error
        +copyWithError(String? error) HomeScreenState
    }
    
    class GameScreen {
        +String roomCode
        +bool isHost
        +build() Widget
    }
    
    class GameScreenViewModel {
        -GameService _gameService
        -String _roomCode
        -bool _isHost
        -GameRoom _currentRoom
        -GameScreenState _uiState
        -StreamSubscription _roomSubscription
        -Map~int, int~ _bets
        -bool _hasRolled
        -bool _hasPlacedBet
        +rollDice() Future~void~
        +updateBet(int catIndex, int amount) void
        +placeBets() Future~void~
        +nextTurn() Future~void~
        -_init() void
        -_updateUiState(GameRoom room) void
        -_checkTurnChange(GameRoom room) void
        +dispose() void
    }
    
    class GameScreenState {
        <<abstract>>
        +String? error
    }
    
    %% Service Layer
    class GameService {
        -RoomService _roomService
        -MatchmakingService _matchmakingService
        -GameFlowService _gameFlowService
        +createRoom() Future~String~
        +joinRoom(String roomCode) Future~void~
        +watchRoom(String roomCode) Stream~GameRoom~
        +joinMatchmaking(String playerId) Future~void~
        +watchMatchmaking(String playerId) Stream~GameRoom?~
        +leaveMatchmaking(String playerId) Future~void~
        +rollDice(String roomCode) Future~void~
        +placeBets(String roomCode, Map bets) Future~void~
        +nextTurn(String roomCode) Future~void~
    }
    
    class RoomService {
        -RoomRepository _roomRepository
        -GameLogic _gameLogic
        +generateRoomCode() String
        +createRoom() Future~String~
        +joinRoom(String roomCode) Future~void~
        +watchRoom(String roomCode) Stream~GameRoom~
        +deleteRoom(String roomCode) Future~void~
    }
    
    class MatchmakingService {
        -FirestoreRepository _firestoreRepository
        -RoomService _roomService
        -GameLogic _gameLogic
        +joinMatchmaking(String playerId) Future~void~
        +watchMatchmaking(String playerId) Stream~GameRoom?~
        +leaveMatchmaking(String playerId) Future~void~
        -_tryToMatch(DocumentSnapshot doc) Future~void~
    }
    
    class GameFlowService {
        -RoomRepository _roomRepository
        -GameLogic _gameLogic
        +rollDice(String roomCode) Future~void~
        +placeBets(String roomCode, Map bets) Future~void~
        +nextTurn(String roomCode) Future~void~
        -_resolveRound(GameRoom room) Future~void~
    }
    
    %% Domain Layer
    class GameLogic {
        +rollDice() int
        +generateRoomCode() String
        +resolveRound(GameRoom room) RoundResult
        +checkWinCondition(List cats) Winner?
        -_determineWinners(Map hostBets, Map guestBets, List costs) Map
        -_clipFeet(int hostBet, int guestBet, int cost) ClipResult
    }
    
    class RoundResult {
        +Map~int, Winner~ winners
        +List~String~ hostWonCats
        +List~String~ guestWonCats
        +GameStatus? finalStatus
        +Winner? finalWinner
    }
    
    class GameRoom {
        +String roomCode
        +String hostId
        +String? guestId
        +GameStatus status
        +MatchmakingStatus? matchmakingStatus
        +int currentTurn
        +List~String~ currentCats
        +List~int~ currentCatCosts
        +int hostFish
        +int? guestFish
        +int? hostDiceResult
        +int? guestDiceResult
        +Map~int, int~ hostBets
        +Map~int, int~? guestBets
        +List~String~ hostCollectedCats
        +List~String~? guestCollectedCats
        +Winner? winner
        +DateTime createdAt
        +toMap() Map~String, dynamic~
        +fromMap(Map data) GameRoom
    }
    
    %% Repository Layer
    class FirestoreRepository {
        -FirebaseFirestore _firestore
        +getDocument(String path) Future~DocumentSnapshot~
        +setDocument(String path, Map data) Future~void~
        +updateDocument(String path, Map data) Future~void~
        +deleteDocument(String path) Future~void~
        +watchDocument(String path) Stream~DocumentSnapshot~
        +query(String collection, List filters) Future~List~
        +runTransaction(Function func) Future~T~
        +getDocumentReference(String path) DocumentReference
    }
    
    class RoomRepository {
        +getRoom(String roomCode) Future~GameRoom~
        +createRoom(GameRoom room) Future~void~
        +updateRoom(String roomCode, Map data) Future~void~
        +deleteRoom(String roomCode) Future~void~
        +watchRoom(String roomCode) Stream~GameRoom~
        +isHost(GameRoom room, String playerId) bool
        +getPlayerField(String field, bool isHost) String
        +updatePlayerData(String roomCode, Map data, bool isHost) Future~void~
    }
    
    %% Relationships
    
    HomeScreen --> HomeScreenViewModel : uses
    HomeScreenViewModel --> GameService : depends on
    HomeScreenViewModel --> HomeScreenState : holds
    
    GameScreen --> GameScreenViewModel : uses
    GameScreenViewModel --> GameService : depends on
    GameScreenViewModel --> GameScreenState : holds
    GameScreenViewModel --> GameRoom : holds
    
    GameService --> RoomService : delegates
    GameService --> MatchmakingService : delegates
    GameService --> GameFlowService : delegates
    
    RoomService --> RoomRepository : uses
    RoomService --> GameLogic : uses
    
    MatchmakingService --> FirestoreRepository : uses
    MatchmakingService --> RoomService : uses
    MatchmakingService --> GameLogic : uses
    
    GameFlowService --> RoomRepository : uses
    GameFlowService --> GameLogic : uses
    
    RoomRepository --|> FirestoreRepository : extends
    
    GameLogic --> RoundResult : creates
    GameFlowService --> RoundResult : uses
    
    RoomRepository --> GameRoom : converts to/from
    GameScreenViewModel --> GameRoom : receives from Stream
    
    note for GameService "Facade Pattern:\n統一インターフェース"
    note for GameLogic "Pure Functions:\nFirestore非依存"
    note for FirestoreRepository "Repository Pattern:\nデータアクセス抽象化"
```

---

## Service層の依存関係

```mermaid
graph TB
    subgraph "Presentation"
        VM[ViewModel]
    end
    
    subgraph "Service Layer (Facade Pattern)"
        GS[GameService<br/>Facade]
        RS[RoomService]
        MS[MatchmakingService]
        GFS[GameFlowService]
    end
    
    subgraph "Domain"
        GL[GameLogic<br/>Pure Functions]
    end
    
    subgraph "Repository"
        RR[RoomRepository]
        FR[FirestoreRepository]
    end
    
    VM -->|DI| GS
    
    GS -->|delegate| RS
    GS -->|delegate| MS
    GS -->|delegate| GFS
    
    RS -->|use| RR
    RS -->|use| GL
    
    MS -->|use| FR
    MS -->|use| RS
    MS -->|use| GL
    
    GFS -->|use| RR
    GFS -->|use| GL
    
    RR -.->|extends| FR
    
    style GS fill:#fff4e1,stroke:#ff9800,stroke-width:3px
    style RS fill:#fff4e1
    style MS fill:#fff4e1
    style GFS fill:#fff4e1
    style GL fill:#f0fff0
    style RR fill:#ffe1f5
    style FR fill:#ffe1f5
```

---

## Repository層の継承関係

```mermaid
classDiagram
    class FirestoreRepository {
        <<Base Class>>
        #FirebaseFirestore _firestore
        +getDocument(String path) Future~DocumentSnapshot~
        +setDocument(String path, Map data) Future~void~
        +updateDocument(String path, Map data) Future~void~
        +deleteDocument(String path) Future~void~
        +watchDocument(String path) Stream~DocumentSnapshot~
        +query(String collection, List filters) Future~List~
        +runTransaction(Function func) Future~T~
    }
    
    class RoomRepository {
        +getRoom(String roomCode) Future~GameRoom~
        +createRoom(GameRoom room) Future~void~
        +updateRoom(String roomCode, Map data) Future~void~
        +deleteRoom(String roomCode) Future~void~
        +watchRoom(String roomCode) Stream~GameRoom~
        +isHost(GameRoom room, String playerId) bool
        +getPlayerField(String field, bool isHost) String
        +updatePlayerData(String roomCode, Map data, bool isHost) Future~void~
    }
    
    FirestoreRepository <|-- RoomRepository : extends
    
    note for FirestoreRepository "汎用Firestore操作を提供\nパス指定で柔軟に操作"
    note for RoomRepository "Room専用の操作を提供\nGameRoomとの変換を担当"
```

**利点**:
- `RoomRepository`は`FirestoreRepository`の汎用メソッドを継承
- `rooms/`コレクション専用のヘルパーメソッドを追加
- `GameRoom`モデルとの変換ロジックを集約

---

## Domain層のクラス

```mermaid
classDiagram
    class GameLogic {
        <<Pure Functions>>
        +rollDice() int
        +generateRoomCode() String
        +resolveRound(GameRoom room) RoundResult
        +checkWinCondition(List~String~ cats) Winner?
        -_determineWinners(...) Map~int, Winner~
        -_clipFeet(int hostBet, int guestBet, int cost) ClipResult
    }
    
    class RoundResult {
        +Map~int, Winner~ winners
        +List~String~ hostWonCats
        +List~String~ guestWonCats
        +GameStatus? finalStatus
        +Winner? finalWinner
    }
    
    class GameRoom {
        <<Data Model>>
        +String roomCode
        +GameStatus status
        +int currentTurn
        +List~String~ currentCats
        +int hostFish
        +Map~int, int~ hostBets
        +List~String~ hostCollectedCats
        +toMap() Map
        +fromMap(Map) GameRoom
    }
    
    class GameConstants {
        <<Static>>
        +int roomCodeLength = 6
        +int diceMin = 1
        +int diceMax = 6
        +int catCount = 3
        +int winCondition = 3
    }
    
    class GameStatus {
        <<enumeration>>
        waiting
        rolling
        playing
        roundResult
        finished
    }
    
    class Winner {
        <<enumeration>>
        host
        guest
        draw
    }
    
    GameLogic --> RoundResult : creates
    GameLogic --> GameRoom : receives as input
    GameLogic --> GameConstants : uses
    GameLogic --> Winner : returns
    
    RoundResult --> Winner : uses
    RoundResult --> GameStatus : uses
    
    GameRoom --> GameStatus : has
    GameRoom --> Winner : has
    
    note for GameLogic "副作用なし\nFirestore非依存\nテスト容易"
```

---

## State Patternの実装

### HomeScreenState

```mermaid
classDiagram
    class HomeScreenState {
        <<abstract>>
        +String? error
        +copyWithError(String? error) HomeScreenState
    }
    
    class IdleState {
        +copyWithError(String? error) IdleState
    }
    
    class LoadingState {
        +copyWithError(String? error) LoadingState
    }
    
    class MatchmakingState {
        +String playerId
        +copyWithError(String? error) MatchmakingState
    }
    
    HomeScreenState <|-- IdleState
    HomeScreenState <|-- LoadingState
    HomeScreenState <|-- MatchmakingState
    
    note for HomeScreenState "Factory Constructors:\nIdleState(), LoadingState(), MatchmakingState()"
```

### GameScreenState

```mermaid
classDiagram
    class GameScreenState {
        <<abstract>>
        +String? error
    }
    
    class LoadingState {
    }
    
    class WaitingState {
        +GameRoom room
    }
    
    class RollingState {
        +GameRoom room
    }
    
    class PlayingState {
        +GameRoom room
    }
    
    class RoundResultState {
        +GameRoom room
    }
    
    class FinishedState {
        +GameRoom room
    }
    
    GameScreenState <|-- LoadingState
    GameScreenState <|-- WaitingState
    GameScreenState <|-- RollingState
    GameScreenState <|-- PlayingState
    GameScreenState <|-- RoundResultState
    GameScreenState <|-- FinishedState
    
    WaitingState --> GameRoom : holds
    RollingState --> GameRoom : holds
    PlayingState --> GameRoom : holds
    RoundResultState --> GameRoom : holds
    FinishedState --> GameRoom : holds
    
    note for GameScreenState "Pattern Matching:\nswitch (state) { case RollingState(:final room) => ... }"
```

---

## ViewModel - Service - Repository の詳細フロー

```mermaid
sequenceDiagram
    participant VM as ViewModel
    participant GS as GameService
    participant GFS as GameFlowService
    participant RR as RoomRepository
    participant FR as FirestoreRepository
    participant FS as Firestore
    
    VM->>GS: rollDice(roomCode)
    GS->>GFS: rollDice(roomCode)
    
    GFS->>RR: getRoom(roomCode)
    RR->>FR: getDocument("rooms/ABC123")
    FR->>FS: get()
    FS-->>FR: DocumentSnapshot
    FR-->>RR: DocumentSnapshot
    RR-->>GFS: GameRoom object
    
    GFS->>GFS: GameLogic.rollDice() → result
    GFS->>GFS: 両プレイヤー振った？
    
    alt 両者完了
        GFS->>GFS: status = playing
    end
    
    GFS->>RR: updateRoom(roomCode, data)
    RR->>FR: updateDocument("rooms/ABC123", data)
    FR->>FS: update()
    
    Note over FS: データ変更
    
    FS-->>FR: snapshots() Stream通知
    FR-->>RR: watchDocument() Stream
    RR-->>GS: watchRoom() Stream
    GS-->>VM: Stream.listen()
    VM->>VM: _updateUiState()
    VM->>VM: notifyListeners()
```

---

## 依存性注入の流れ

```mermaid
graph TB
    subgraph "main.dart"
        Main[main関数]
    end
    
    subgraph "Provider Setup"
        FR[FirestoreRepository<br/>instance]
        RR[RoomRepository<br/>instance]
        RS[RoomService<br/>instance]
        MS[MatchmakingService<br/>instance]
        GFS[GameFlowService<br/>instance]
        GS[GameService<br/>instance]
        GL[GameLogic<br/>instance]
    end
    
    subgraph "Screens"
        HS[HomeScreen]
        HSVM[HomeScreenViewModel]
        GScr[GameScreen]
        GSVM[GameScreenViewModel]
    end
    
    Main -->|create| FR
    Main -->|create| GL
    FR -->|inject| RR
    RR -->|inject| RS
    FR -->|inject| MS
    GL -->|inject| RS
    GL -->|inject| MS
    RS -->|inject| MS
    RR -->|inject| GFS
    GL -->|inject| GFS
    RS -->|inject| GS
    MS -->|inject| GS
    GFS -->|inject| GS
    
    Main -->|Provider| GS
    HS -->|read Provider| GS
    GS -->|inject| HSVM
    GScr -->|read Provider| GS
    GS -->|inject| GSVM
    
    style Main fill:#e1f5ff
    style HS fill:#e1f5ff
    style GScr fill:#e1f5ff
    style HSVM fill:#fff4e1
    style GSVM fill:#fff4e1
    style GS fill:#ffe1f5
```

**ポイント**:
- 全ての依存は`main.dart`で生成
- `MultiProvider`でツリーに提供
- 各クラスはコンストラクタで依存を受け取る
- テスト時にモック注入が容易

---

## 関連ドキュメント

- [01_overview.md](./01_overview.md) - アーキテクチャ概要
- [02_mvvm_home.md](./02_mvvm_home.md) - HomeScreenのMVVM構造
- [03_mvvm_game.md](./03_mvvm_game.md) - GameScreenのMVVM構造
- [05_data_flow.md](./05_data_flow.md) - データフロー詳細
- [06_file_structure.md](./06_file_structure.md) - ファイル構成

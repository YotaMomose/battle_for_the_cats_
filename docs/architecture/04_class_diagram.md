# クラス詳細設計

本作は、MVVMパターン、Facadeパターン、およびRepositoryパターンを採用し、責務の分離を徹底しています。

## 全体クラス図

```mermaid
classDiagram
    %% Presentation Layer
    class HomeScreenViewModel {
        -GameService _gameService
        -HomeScreenState _state
        +createRoom() Future
        +startRandomMatch() Future
        +joinRoom(String code) Future
    }
    
    class GameScreenViewModel {
        -GameService _gameService
        -GameRoom? _currentRoom
        -GameScreenState _uiState
        -Bets _bets
        +rollDice() Future
        +confirmRoll() Future
        +placeBets() Future
        +nextTurn() Future
        +confirmFatCatEvent() Future
    }
    
    %% Service Layer
    class GameService {
        <<Facade>>
        -RoomService _roomService
        -MatchmakingService _matchmakingService
        -GameFlowService _gameFlowService
    }
    
    class GameFlowService {
        -RoomRepository _repository
        -Dice _dice
        -RoundResolver _roundResolver
        +rollDice(roomCode, playerId) Future
        +confirmRoll(roomCode, playerId) Future
        +placeBets(roomCode, playerId, bets, itemPlacements) Future
        +nextTurn(roomCode, playerId) Future
        +confirmFatCatEvent(roomCode, playerId) Future
    }

    class RoundResolver {
        -Random _random
        +resolve(room) void
        +advanceFromRoundResult(room) void
        +advanceFromFatCatEvent(room) void
    }
    
    %% Domain Layer
    class BattleEvaluator {
        +evaluate(currentRound, host, guest) RoundWinners
    }
    
    class WinCondition {
        <<Interface>>
        +checkWin(inventory) bool
        +determineFinalWinner(host, guest) Winner?
    }
    
    class Dice {
        <<Interface>>
        +roll() int
    }
    
    %% Models Layer
    class GameRoom {
        +String roomId
        +Player host
        +Player? guest
        +GameStatus status
        +RoundCards? currentRound
        +RoundWinners? winners
        +applyRoundResults(winnersMap) void
        +triggerFatCatEvent() void
        +confirmRoundResult(playerId) void
        +confirmFatCatEvent(playerId) void
        +prepareNextTurn(nextRoundCards) void
    }
    
    class Player {
        +String id
        +int fishCount
        +CatInventory catsWon
        +Bets currentBets
        +bool rolled
        +bool confirmedRoll
        +bool ready
        +roll(Dice dice) void
        +placeBets(Map bets) void
        +prepareForNextTurn() void
    }
    
    class RoundResult {
        +List~WonCat~ cats
        +RoundWinners winners
        +Bets hostBets
        +Bets guestBets
    }

    %% Relationships
    GameScreenViewModel --> GameService
    GameService --> GameFlowService
    GameFlowService --> RoomRepository
    GameFlowService --> Dice
    
    GameRoom "1" *-- "1..2" Player : contains
    GameFlowService --> RoundResolver : uses
    RoundResolver --> BattleEvaluator : uses
    RoundResolver --> WinCondition : uses
    Player --> Dice : uses
    GameRoom --> RoundResult : creates
    
    class RoomRepository {
        <<Repository>>
        +getRoom(code) Future~GameRoom?~
        +updateRoom(code, data) Future
    }

    RoomRepository --|> FirestoreRepository
```

---

## サービス層の構成（Facadeパターン）

プレゼンテーション層（ViewModel）は `GameService` を通じてのみ、下層のサービスを呼び出します。

```mermaid
graph TB
    subgraph "ViewModel"
        VM[ViewModel]
    end
    
    subgraph "Service Layer"
        GS[GameService<br/>Facade]
        RS[RoomService]
        MS[MatchmakingService]
        GFS[GameFlowService]
    end
    
    VM --> GS
    GS --> RS
    GS --> MS
    GS --> GFS
```

---

## ドメイン・モデル層の相互作用

`GameRoom` はドメインサービス（`BattleEvaluator`, `WinCondition`）を利用して、ラウンドの状態を更新します。

```mermaid
graph LR
    subgraph "Models"
        GR[GameRoom]
        P[Player]
    end
    
    subgraph "Domain Services"
        BE[BattleEvaluator]
        WC[WinCondition]
        D[Dice / StandardDice]
    end
    
    GR -->|勝敗判定の委譲| BE
    GR -->|勝利条件の委譲| WC
    P -->|サイコロの委譲| D
```

---

## リポジトリ層の継承関係

```mermaid
classDiagram
    class FirestoreRepository {
        <<Base>>
        +getDocument(collection, id) Future
        +setDocument(collection, id, data) Future
        +runTransaction(callback) Future
    }
    
    class RoomRepository {
        +getRoom(code) Future~GameRoom?~
        +createRoom(room) Future
        +updateRoom(code, data) Future
    }
    
    FirestoreRepository <|-- RoomRepository : extends
```

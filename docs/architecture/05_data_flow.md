# データフロー詳細

## 概要

このドキュメントでは、プロジェクト内の主要なデータフローをシナリオ別に図示します。

---

## 1. 部屋作成フロー

```mermaid
sequenceDiagram
    participant U as User
    participant V as MainMenuView
    participant VM as HomeScreenViewModel
    participant GS as GameService
    participant RS as RoomService
    participant RR as RoomRepository
    participant FR as FirestoreRepository
    participant FS as Firestore
    
    U->>V: 部屋作成ボタン押下
    V->>VM: createRoom()
    VM->>VM: _state = LoadingState()
    VM->>V: notifyListeners()
    V->>V: ローディング表示
    
    VM->>GS: createRoom()
    GS->>RS: createRoom()
    
    RS->>RS: GameLogic.generateRoomCode() → "ABC123"
    RS->>RS: GameLogic.rollDice() × 3 → [3, 5, 2]
    RS->>RS: 猫リスト・コスト生成
    
    RS->>RR: createRoom(GameRoom)
    RR->>FR: setDocument("rooms/ABC123", data)
    FR->>FS: set()
    
    FS-->>FR: 成功
    FR-->>RR: 成功
    RR-->>RS: 成功
    RS-->>GS: roomCode = "ABC123"
    GS-->>VM: roomCode = "ABC123"
    
    VM->>VM: _onNavigateToGame("ABC123", true)
    VM->>V: GameScreenへ遷移
```

**ポイント**:
- 部屋コードはランダム生成（6桁英数字）
- 初期の猫・コストもランダム
- ホストとして部屋に入る（`isHost = true`）

---

## 2. ランダムマッチングフロー

### 2.1. マッチング参加

```mermaid
sequenceDiagram
    participant U1 as User 1
    participant VM1 as ViewModel (Player 1)
    participant GS as GameService
    participant MS as MatchmakingService
    participant FR as FirestoreRepository
    participant FS as Firestore
    
    U1->>VM1: startRandomMatch()
    VM1->>VM1: playerId = UUID生成
    VM1->>VM1: _state = MatchmakingState(playerId)
    VM1->>U1: notifyListeners() → マッチング画面表示
    
    VM1->>GS: joinMatchmaking(playerId)
    GS->>MS: joinMatchmaking(playerId)
    
    MS->>MS: 既存の待機者を検索
    
    alt 待機者なし
        MS->>FR: setDocument("matchmaking/playerId", ...)
        FR->>FS: マッチングキューに追加
        Note over FS: status = waiting, timestamp記録
    else 待機者あり
        MS->>MS: _tryToMatch() (Transaction)
        MS->>FR: runTransaction()
        FR->>FS: Transaction開始
        Note over FS: 最古の待機者とマッチング
        MS->>MS: RoomService.createRoom()
        FS->>FS: 部屋作成 + 両者のドキュメント更新
        FR-->>MS: Transaction成功
    end
    
    VM1->>GS: watchMatchmaking(playerId)
    GS->>MS: watchMatchmaking(playerId)
    MS->>FR: watchDocument("matchmaking/playerId")
    FR->>FS: snapshots()
    
    Note over VM1: Stream監視開始
```

### 2.2. マッチング成立

```mermaid
sequenceDiagram
    participant U2 as User 2
    participant FS as Firestore
    participant VM1 as ViewModel (Player 1)
    participant VM2 as ViewModel (Player 2)
    
    Note over FS: Player 2が参加
    Note over FS: Transactionでマッチング成立
    Note over FS: status = matched, roomCode設定
    
    FS-->>VM1: snapshots() 通知
    VM1->>VM1: status == matched ?
    VM1->>VM1: _matchmakingSubscription.cancel()
    VM1->>VM1: _onNavigateToGame(roomCode, isHost)
    VM1->>U2: GameScreenへ遷移
    
    FS-->>VM2: snapshots() 通知
    VM2->>VM2: status == matched ?
    VM2->>VM2: _matchmakingSubscription.cancel()
    VM2->>VM2: _onNavigateToGame(roomCode, isHost)
    VM2->>U2: GameScreenへ遷移
```

**ポイント**:
- Transactionで競合を防止
- 両プレイヤーが同時にStreamで通知を受け取る
- タイムスタンプ順で最古の待機者とマッチング

---

## 3. 部屋参加フロー

```mermaid
sequenceDiagram
    participant U as User (Guest)
    participant V as MainMenuView
    participant VM as HomeScreenViewModel
    participant GS as GameService
    participant RS as RoomService
    participant RR as RoomRepository
    participant FR as FirestoreRepository
    participant FS as Firestore
    
    U->>V: 部屋コード入力 + 参加ボタン
    V->>VM: joinRoom("ABC123")
    VM->>VM: _state = LoadingState()
    VM->>V: notifyListeners()
    
    VM->>GS: joinRoom("ABC123")
    GS->>RS: joinRoom("ABC123")
    
    RS->>RR: getRoom("ABC123")
    RR->>FR: getDocument("rooms/ABC123")
    FR->>FS: get()
    FS-->>FR: DocumentSnapshot
    FR-->>RR: DocumentSnapshot
    RR-->>RS: GameRoom object
    
    RS->>RS: 部屋が存在するか確認
    RS->>RS: guestId == null ? (空席確認)
    
    alt 参加可能
        RS->>RR: updateRoom("ABC123", {guestId: UUID, status: rolling})
        RR->>FR: updateDocument()
        FR->>FS: update()
        FS-->>RS: 成功
        RS-->>VM: 成功
        VM->>VM: _onNavigateToGame("ABC123", false)
        VM->>V: GameScreenへ遷移
    else 部屋が存在しない or 満席
        RS-->>VM: Exception
        VM->>VM: _state = IdleState().copyWithError()
        VM->>V: notifyListeners() → エラー表示
    end
```

**ポイント**:
- 部屋の存在確認
- 既にゲストがいる場合はエラー
- ゲスト参加と同時に`status = rolling`に変更

---

## 4. ゲームプレイフロー（1ターン）

### 4.1. サイコロフェーズ

```mermaid
sequenceDiagram
    participant H as Host
    participant G as Guest
    participant VMH as ViewModel (Host)
    participant VMG as ViewModel (Guest)
    participant GS as GameService
    participant GFS as GameFlowService
    participant RR as RoomRepository
    participant FS as Firestore
    
    Note over FS: status = rolling
    
    H->>VMH: rollDice()ボタン押下
    VMH->>VMH: _hasRolled = true
    VMH->>GS: rollDice(roomCode)
    GS->>GFS: rollDice(roomCode)
    
    GFS->>RR: getRoom(roomCode)
    RR->>FS: get()
    FS-->>RR: GameRoom
    
    GFS->>GFS: GameLogic.rollDice() → 5
    GFS->>GFS: 相手も振った？ → No
    GFS->>RR: updateRoom({hostDiceResult: 5})
    RR->>FS: update()
    
    FS-->>VMH: snapshots() 通知
    VMH->>VMH: _updateUiState() → RollingState
    
    FS-->>VMG: snapshots() 通知
    VMG->>VMG: _updateUiState() → RollingState
    VMG->>G: 相手が振ったことを表示
    
    G->>VMG: rollDice()ボタン押下
    VMG->>VMG: _hasRolled = true
    VMG->>GS: rollDice(roomCode)
    GS->>GFS: rollDice(roomCode)
    
    GFS->>RR: getRoom(roomCode)
    RR->>FS: get()
    FS-->>RR: GameRoom
    
    GFS->>GFS: GameLogic.rollDice() → 3
    GFS->>GFS: 相手も振った？ → Yes
    GFS->>GFS: hostFish += 5, guestFish += 3
    GFS->>RR: updateRoom({guestDiceResult: 3, status: playing, ...})
    RR->>FS: update()
    
    FS-->>VMH: snapshots() 通知
    VMH->>VMH: _updateUiState() → PlayingState
    VMH->>H: ベットフェーズへ遷移
    
    FS-->>VMG: snapshots() 通知
    VMG->>VMG: _updateUiState() → PlayingState
    VMG->>G: ベットフェーズへ遷移
```

### 4.2. ベットフェーズ

```mermaid
sequenceDiagram
    participant H as Host
    participant G as Guest
    participant VMH as ViewModel (Host)
    participant VMG as ViewModel (Guest)
    participant GS as GameService
    participant GFS as GameFlowService
    participant GL as GameLogic
    participant FS as Firestore
    
    Note over FS: status = playing
    
    H->>VMH: updateBet(0, 3) (猫0に魚3匹)
    VMH->>VMH: _bets[0] = 3 (ローカル状態)
    VMH->>H: notifyListeners() → UI更新
    
    H->>VMH: placeBets()ボタン押下
    VMH->>VMH: _hasPlacedBet = true
    VMH->>GS: placeBets(roomCode, {0: 3})
    GS->>GFS: placeBets(roomCode, {0: 3})
    
    GFS->>FS: getRoom() → GameRoom
    GFS->>GFS: 相手もベット済み？ → No
    GFS->>FS: updateRoom({hostBets: Bets({0: 3})})
    
    FS-->>VMH: snapshots() 通知
    FS-->>VMG: snapshots() 通知
    VMG->>G: 相手がベット済みを表示
    
    G->>VMG: updateBet(0, 2)
    VMG->>VMG: _bets[0] = 2
    
    G->>VMG: placeBets()
    VMG->>VMG: _hasPlacedBet = true
    VMG->>GS: placeBets(roomCode, Bets({0: 2}))
    GS->>GFS: placeBets(roomCode, Bets({0: 2}))
    
    GFS->>FS: getRoom() → GameRoom
    GFS->>GFS: 相手もベット済み？ → Yes
    GFS->>GFS: _resolveRound()
    
    GFS->>GL: GameLogic.resolveRound(room)
    GL->>GL: 勝敗判定・足切り処理
    GL-->>GFS: RoundResult
    
    GFS->>GFS: hostWonCats.addAll()
    GFS->>GFS: guestWonCats.addAll()
    GFS->>GFS: hostFish -= 消費分
    GFS->>GFS: guestFish -= 消費分
    
    GFS->>GL: GameLogic.checkWinCondition()
    
    alt 勝利条件達成
        GL-->>GFS: Winner.host or Winner.guest
        GFS->>FS: updateRoom({status: finished, winner: ...})
    else 継続
        GFS->>FS: updateRoom({status: roundResult, ...})
    end
    
    FS-->>VMH: snapshots() 通知
    VMH->>VMH: _updateUiState() → RoundResultState or FinishedState
    
    FS-->>VMG: snapshots() 通知
    VMG->>VMG: _updateUiState() → RoundResultState or FinishedState
```

### 4.3. ラウンド結果 → 次のターン

```mermaid
sequenceDiagram
    participant H as Host
    participant VMH as ViewModel (Host)
    participant GS as GameService
    participant GFS as GameFlowService
    participant FS as Firestore
    participant VMG as ViewModel (Guest)
    participant G as Guest
    
    Note over FS: status = roundResult
    
    H->>VMH: nextTurn()ボタン押下
    VMH->>GS: nextTurn(roomCode)
    GS->>GFS: nextTurn(roomCode)
    
    GFS->>FS: getRoom() → GameRoom
    GFS->>GFS: currentTurn++
    GFS->>GFS: 新しい猫3匹を生成
    GFS->>GFS: 残りの魚を次ターンに引き継ぎ
    GFS->>GFS: diceResult, betsをクリア
    GFS->>FS: updateRoom({currentTurn: 2, status: rolling, ...})
    
    FS-->>VMH: snapshots() 通知
    VMH->>VMH: _checkTurnChange() → ターン変更検知
    VMH->>VMH: _resetLocalState()
    Note over VMH: _hasRolled = false<br/>_hasPlacedBet = false<br/>_bets.clear()
    VMH->>VMH: _updateUiState() → RollingState
    VMH->>H: サイコロフェーズへ遷移
    
    FS-->>VMG: snapshots() 通知
    VMG->>VMG: _checkTurnChange() → ターン変更検知
    VMG->>VMG: _resetLocalState()
    VMG->>VMG: _updateUiState() → RollingState
    VMG->>G: サイコロフェーズへ遷移
```

---

## 5. リアルタイム同期の詳細

```mermaid
sequenceDiagram
    participant FS as Firestore
    participant FR as FirestoreRepository
    participant RR as RoomRepository
    participant GS as GameService
    participant VM as ViewModel
    participant V as View
    
    Note over VM: 初期化時
    VM->>GS: watchRoom(roomCode)
    GS->>RR: watchRoom(roomCode)
    RR->>FR: watchDocument("rooms/ABC123")
    FR->>FS: snapshots()
    
    Note over FS: Stream確立
    
    loop リアルタイム監視
        Note over FS: データ変更（相手の操作）
        FS->>FR: snapshots()通知
        FR->>FR: DocumentSnapshot受信
        FR->>RR: DocumentSnapshot
        RR->>RR: GameRoom.fromMap()
        RR->>GS: Stream<GameRoom>
        GS->>VM: Stream<GameRoom>
        
        VM->>VM: _currentRoom = room
        VM->>VM: _updateUiState(room)
        VM->>VM: _checkTurnChange(room)
        VM->>VM: notifyListeners()
        
        VM->>V: Provider通知
        V->>V: rebuild()
        V->>V: switch (state) で適切なViewを表示
    end
    
    Note over VM: dispose時
    VM->>VM: _roomSubscription.cancel()
    Note over FS: Stream終了
```

**ポイント**:
- Firestoreの`snapshots()`で自動監視
- データ変更が即座にStreamで通知
- ポーリング不要で効率的
- ViewModelが状態判定を一元管理

---

## 6. エラーハンドリングフロー

### 6.1. Service層でのエラー

```mermaid
sequenceDiagram
    participant U as User
    participant VM as ViewModel
    participant GS as GameService
    participant FS as Firestore
    
    U->>VM: createRoom()
    VM->>VM: _state = LoadingState()
    VM->>GS: createRoom()
    
    GS->>FS: setDocument()
    FS-->>GS: Exception (ネットワークエラー)
    GS-->>VM: throw Exception
    
    VM->>VM: catch (e)
    VM->>VM: _state = IdleState().copyWithError(e.toString())
    VM->>VM: notifyListeners()
    VM->>U: エラーメッセージ表示（SnackBar）
```

### 6.2. Stream監視中のエラー

```mermaid
sequenceDiagram
    participant FS as Firestore
    participant VM as ViewModel
    participant U as User
    
    Note over VM: Stream監視中
    
    FS->>VM: onError (接続エラー)
    VM->>VM: _uiState = LoadingState().copyWithError()
    VM->>VM: notifyListeners()
    VM->>U: エラーメッセージ表示
```

---

## 7. メモリ管理フロー

```mermaid
sequenceDiagram
    participant U as User
    participant Nav as Navigator
    participant VM as ViewModel
    participant FS as Firestore
    
    Note over VM: 画面表示中
    Note over VM: _roomSubscription active
    
    U->>Nav: 戻るボタン or Pop
    Nav->>VM: dispose()
    
    VM->>VM: _roomSubscription?.cancel()
    VM->>FS: Stream監視解除
    
    VM->>VM: super.dispose()
    
    Note over VM: ViewModelが破棄される
    Note over FS: メモリリークなし
```

**重要**: 必ず`dispose()`でStreamを解除

---

## 8. 依存性注入フロー

```mermaid
graph TB
    subgraph "main.dart"
        Main[main関数]
    end
    
    subgraph "Instances作成"
        Main -->|1. new| FR[FirestoreRepository]
        Main -->|2. new| GL[GameLogic]
        Main -->|3. new| RR[RoomRepository<br/>← FR注入]
        Main -->|4. new| RS[RoomService<br/>← RR, GL注入]
        Main -->|5. new| MS[MatchmakingService<br/>← FR, RS, GL注入]
        Main -->|6. new| GFS[GameFlowService<br/>← RR, GL注入]
        Main -->|7. new| GS[GameService<br/>← RS, MS, GFS注入]
    end
    
    subgraph "Provider Setup"
        Main -->|8. MultiProvider| App[runApp<br/>MultiProvider<br/>- GameService<br/>- ...他のProvider]
    end
    
    subgraph "画面遷移"
        App -->|Navigator| HS[HomeScreen]
        HS -->|context.read| GS
        HS -->|ViewModel作成時| HSVM[HomeScreenViewModel<br/>← GS注入]
    end
    
    style Main fill:#e1f5ff
    style GS fill:#fff4e1
    style HSVM fill:#ffe1f5
```

---

## 関連ドキュメント

- [01_overview.md](./01_overview.md) - アーキテクチャ概要
- [02_mvvm_home.md](./02_mvvm_home.md) - HomeScreenのMVVM構造
- [03_mvvm_game.md](./03_mvvm_game.md) - GameScreenのMVVM構造
- [04_class_diagram.md](./04_class_diagram.md) - クラス関係図
- [06_file_structure.md](./06_file_structure.md) - ファイル構成

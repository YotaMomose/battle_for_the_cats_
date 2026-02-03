# データフロー詳細

本作の主要なユースケースにおけるデータフローをシーケンス図で示します。

---

## 1. 部屋作成と参加

### 1.1 部屋作成 (Host)
ホストが部屋を作成し、Firestoreに初期状態を保存します。

```mermaid
sequenceDiagram
    participant H as Host ViewModel
    participant GS as GameService
    participant RS as RoomService
    participant RR as RoomRepository
    participant FS as Firestore
    
    H->>GS: createRoom(hostId)
    GS->>RS: createRoom(hostId)
    RS->>RS: generateRoomCode()
    RS->>RR: createRoom(GameRoom)
    RR->>FS: set("rooms/CODE", data)
    FS-->>H: Stream通知 (status: waiting)
```

### 1.2 部屋参加 (Guest)
ゲストがコード入力で参加し、トランザクション安全にプレイヤー情報を更新します。

```mermaid
sequenceDiagram
    participant G as Guest ViewModel
    participant GS as GameService
    participant RS as RoomService
    participant RR as RoomRepository
    participant FS as Firestore
    
    G->>GS: joinRoom(code, guestId)
    GS->>RS: joinRoom(code, guestId)
    RS->>RR: updateRoomTransaction(code, ...)
    Note over FS: guestIdが空であることを確認
    RR->>FS: update("rooms/CODE", {guest: ..., status: rolling})
    FS-->>G: Stream通知 (status: rolling)
    FS-->>H: Stream通知 (status: rolling)
```

---

## 2. マッチング (Transaction)

マッチングサービスは `Transaction` を使用し、二重マッチングを防ぎます。

```mermaid
sequenceDiagram
    participant P as Player
    participant MS as MatchmakingService
    participant FS as Firestore
    
    P->>MS: joinMatchmaking(playerId)
    MS->>FS: 待機リストを検索
    
    alt 待機者あり
        MS->>FS: runTransaction()
        Note over FS: 相手を選択し、リストから削除
        MS->>RS: createRoom()
        FS->>FS: Matchドキュメントを matched に更新
    else 待機者なし
        MS->>FS: 待機リストに登録 (waiting)
    end
```

---

## 3. ゲームプレイサイクル

各フェーズは両プレイヤーの「確認フラグ」によって同期されます。

### 3.1 サイコロフェーズ
両プレイヤーがサイコロを振り、結果を「確認」すると次に進みます。

```mermaid
sequenceDiagram
    participant H as Host
    participant G as Guest
    participant FS as Firestore
    
    H->>FS: rollDice() → diceRoll: 4, rolled: true
    G->>FS: rollDice() → diceRoll: 2, rolled: true
    Note over FS: 両者の rolled が true
    
    H->>FS: confirmRoll() → confirmedRoll: true
    G->>FS: confirmRoll() → confirmedRoll: true
    Note over FS: 全員確認完了
    FS->>FS: statusを playing に自動更新 (GameFlowService)
```

### 3.2 ベットフェーズ
両プレイヤーがベットを「確定」するとラウンド解決が走ります。

```mermaid
sequenceDiagram
    participant H as Host
    participant G as Guest
    participant FS as Firestore
    participant BE as BattleEvaluator
    
    H->>FS: placeBets(Map) → ready: true
    G->>FS: placeBets(Map) → ready: true
    
    Note over FS: 全員 ready
    FS->>BE: evaluate(cats, host, guest)
    BE-->>FS: RoundResult生成
    FS->>FS: 魚の消費・猫の付与・statusを roundResult に更新
```

### 3.3 退出処理 (Transaction)
レースコンディションを防ぎ、最新の状態に基づいて削除を判定するため、トランザクションを使用します。

```mermaid
sequenceDiagram
    participant P as Player
    participant RS as RoomService
    participant RR as RoomRepository
    participant FS as Firestore
    
    P->>RS: leaveRoom(code, playerId)
    RS->>RR: runTransaction()
    RR->>FS: get doc (LOCK)
    Note over FS: 最新の状態を読み取り
    
    alt 削除条件合致 (ホスト単独 または 両者退出)
        RS->>FS: delete("rooms/CODE")
    else 片方のみ退出
        RS->>FS: update("rooms/CODE", {abandoned: true})
    end
    Note over FS: Transaction Commit
```

---

## 4. リアルタイム同期

全てのレイヤーは `Stream<GameRoom>` を通じて同期しています。

```mermaid
graph LR
    FS[(Firestore)] -->|Stream snapshots| RR[RoomRepository]
    RR -->|Map to Model| GS[GameService]
    GS -->|Stream GameRoom| VM[ViewModel]
    VM -->|notifyListeners| V[View]
```

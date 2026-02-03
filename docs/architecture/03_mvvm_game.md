# MVVM詳細: GameScreen

## 構成

- **View**: `GameScreen`
  - サブビュー: `WaitingView`, `RollingPhaseView`, `BettingPhaseView`, `RoundResultView`, `FinalResultView`
- **ViewModel**: `GameScreenViewModel`
- **State**: `GameScreenState`
- **Helper**: `PlayerData`

## 状態遷移ロジック

`GameScreenViewModel` は Firestore からの `GameRoom` ストリームを監視し、以下のルールに基づいて `uiState` を決定します。

1.  **相手の退出チェック**: `abandoned` フラグが立っていれば退出用UIへ。
2.  **個別フェーズ遷移の整合性**:
    - ラウンド結果が未確認なら、`RoundResult` 画面を優先表示。
    - サイコロ確認が未完了なら、`Rolling` 画面を表示。
3.  **GameStatusに基づく基本遷移**:
    - `waiting`: 相手の入室待ち。
    - `rolling`: サイコロフェーズ。
    - `playing`: ベット中。
    - `round_result`: ラウンド結果。
    - `finished`: ゲーム終了。

## PlayerData の役割

ViewModelからUIに渡すデータを整理するためのヘルマークラスです。ホスト/ゲストの差異を吸収します。

```dart
class PlayerData {
  final int myFishCount;
  final int opponentFishCount;
  final bool myReady;
  final bool opponentReady;
  // ... getters for UI
}
```

## 主要メソッド

### 1. サイコロ操作 (`rollDice` / `confirmRoll`)
- `rollDice()`: サイコロを振り、`rolled: true` に更新。
- `confirmRoll()`: 結果を確認し、`confirmedRoll: true` に更新。

### 2. ベット操作 (`placeBets`)
- `updateBet()`: ローカル状態の `Bets` を更新。
- `placeBets()`: `ready: true` と共に現在の `Bets` を送信。

### 3. 進行操作 (`nextTurn`)
- `confirmedRoundResult: true` に更新。
- フィールドが両者埋まると、バックエンド（GameFlowService）側で次のターンへ移行。

## リアルタイム同期の仕組み

```mermaid
sequenceDiagram
    participant FS as Firestore
    participant VM as GameScreenViewModel
    participant V as GameScreen (View)
    
    FS->>VM: Stream Snapshots (roomData)
    VM->>VM: _updateUiState(room)
    VM->>VM: notifyListeners()
    VM->>V: 表示を更新
```

## メモリ管理

- `dispose()` 時に `StreamSubscription` を `cancel()` することを徹底しています。

graph TD
    %% 中心
    Flutter[Flutter<br/>アプリ基盤]

    %% 言語
    Dart[Dart言語]
    Dart -->|記述言語| Flutter

    %% UI
    UI[UI / Widget設計]
    UI -->|画面・入力| Flutter

    %% 状態管理
    State[状態管理]
    State -->|ゲーム状態<br/>UI状態| Flutter

    %% 非同期
    Async[同期 / 非同期処理]
    Async -->|Future / Stream<br/>待ち・同時確定| Flutter

    %% オンライン
    Online[オンライン通信]
    Online -->|リアルタイム同期| Flutter

    %% Firebase
    Firebase[Firebase]
    Firebase -->|Auth / Firestore| Online

    %% ゲーム設計
    GameDesign[ゲーム設計]
    GameDesign -->|ルール| State
    GameDesign -->|同時公開| Async
    GameDesign -->|心理戦| UI

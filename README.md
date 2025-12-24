graph TB

    %% ======================
    %% 中心
    Flutter[Flutter<br/>アプリ基盤]

    %% ======================
    %% Dart
    subgraph DartLayer["Dart（言語基盤）"]
        Dart[Dart言語]
        DartBasic[文法 / 型]
        DartNull[Null Safety]
        DartAsync[async / await]
        DartClass[クラス / enum]

        Dart --> DartBasic
        Dart --> DartNull
        Dart --> DartAsync
        Dart --> DartClass
    end

    Dart --> Flutter

    %% ======================
    %% UI
    subgraph UILayer["UI / Widget設計"]
        UI[UI設計]
        WidgetTree[Widgetツリー]
        Layout[Row / Column / Stack]
        Input[入力処理]
        Navigation[画面遷移]

        UI --> WidgetTree
        UI --> Layout
        UI --> Input
        UI --> Navigation
    end

    UI --> Flutter

    %% ======================
    %% 状態管理
    subgraph StateLayer["状態管理"]
        State[状態管理]
        UIState[UI状態]
        GameState[ゲーム状態]
        Turn[ターン管理]
        SyncState[同期状態]

        State --> UIState
        State --> GameState
        State --> Turn
        State --> SyncState
    end

    State --> Flutter

    %% ======================
    %% 非同期・オンライン
    subgraph AsyncLayer["非同期 / オンライン"]
        Async[同期 / 非同期処理]
        Future[Future]
        Stream[Stream]
        Waiting[相手待ち]
        Reveal[同時公開]

        Online[オンライン通信]
        Realtime[リアルタイム同期]
        Conflict[競合対策]
        Room[ルーム管理]

        Firebase[Firebase]
        Auth[認証]
        Firestore[Firestore]
        Listen[リアルタイム監視]
        Write[状態書き込み]

        Async --> Future
        Async --> Stream
        Async --> Waiting
        Async --> Reveal

        Online --> Realtime
        Online --> Conflict
        Online --> Room

        Firebase --> Auth
        Firebase --> Firestore
        Firestore --> Listen
        Firestore --> Write
    end

    Async --> Flutter
    Online --> Flutter
    Firebase --> Online

    %% ======================
    %% ゲーム設計
    subgraph GameLayer["ゲーム設計"]
        GameDesign[ゲーム設計]
        Rules[ルール]
        Win[勝利条件]
        Psychology[心理戦]
        Balance[バランス]

        GameDesign --> Rules
        GameDesign --> Win
        GameDesign --> Psychology
        GameDesign --> Balance
    end

    %% ゲーム設計の影響
    GameDesign --> State
    GameDesign --> Async
    GameDesign --> UI

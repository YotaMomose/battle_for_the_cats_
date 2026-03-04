import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 広告を管理するサービス
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;

  /// インタースティシャル広告のユニットIDを取得
  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // Android テスト用
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      // iOS テスト用
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  /// 初期化
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
  }

  /// インタースティシャル広告のロード
  void _loadInterstitialAd() {
    if (_isAdLoading) return;
    _isAdLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Ad loaded: ${ad.adUnitId}');
          _interstitialAd = ad;
          _isAdLoading = false;

          // フルスクリーンのリスナーを設定
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _loadInterstitialAd();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  ad.dispose();
                  _loadInterstitialAd();
                },
              );
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _isAdLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  /// インタースティシャル広告の表示
  Future<void> showInterstitialAd({required VoidCallback onAdClosed}) async {
    if (_interstitialAd == null) {
      onAdClosed();
      _loadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitialAd();
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitialAd();
        onAdClosed();
      },
    );

    await _interstitialAd!.show();
    _interstitialAd = null;
  }
}

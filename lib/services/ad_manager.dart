// File: lib/services/ad_manager.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:tetris_pro/core/app_theme.dart';

enum AdBannerType { home, game }

class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  // Ad instances
  NativeAd? _nativeAd;
  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  DateTime? _appPausedTime;
  bool _isShowingAd = false;

  // Interstitial ad management (limits removed)
  StreamSubscription? _connectivitySubscription;

  // Offline tracking
  final ValueNotifier<bool> isOffline = ValueNotifier(false);

  // Production Ad Unit IDs from environment variables
  static String _getBannerAdUnitId(AdBannerType type) {
    if (Platform.isAndroid) {
      return type == AdBannerType.home
          ? dotenv.env['ADMOB_BANNER_HOME_ANDROID']!
          : dotenv.env['ADMOB_BANNER_GAME_ANDROID']!;
    } else {
      return type == AdBannerType.home
          ? dotenv.env['ADMOB_BANNER_HOME_IOS']!
          : dotenv.env['ADMOB_BANNER_GAME_IOS']!;
    }
  }

  static String get _appOpenAdUnitId => Platform.isAndroid
      ? dotenv.env['ADMOB_APP_OPEN_ANDROID']!
      : dotenv.env['ADMOB_APP_OPEN_IOS']!;

  static String get _interstitialAdUnitId => Platform.isAndroid
      ? dotenv.env['ADMOB_INTERSTITIAL_ANDROID']!
      : dotenv.env['ADMOB_INTERSTITIAL_IOS']!;

  static String get _rewardedAdUnitId => Platform.isAndroid
      ? dotenv.env['ADMOB_REWARDED_ANDROID']!
      : dotenv.env['ADMOB_REWARDED_IOS']!;

  static String get _nativeAdUnitId => Platform.isAndroid
      ? dotenv.env['ADMOB_NATIVE_ANDROID']!
      : dotenv.env['ADMOB_NATIVE_IOS']!;

  // Helpers for Analytics
  void _logAdEvent(String eventName, String adType) {
    FirebaseAnalytics.instance.logEvent(
      name: eventName,
      parameters: {
        'ad_type': adType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('Analytics: $eventName ($adType)');
  }

  // Initialize all ads
  void initialize() {
    _loadAppOpenAd();
    _loadInterstitialAd();
    _loadRewardedAd();
    _loadNativeAd();

    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final result = results.first; // Get most recent result
      isOffline.value = result == ConnectivityResult.none;
      if (!isOffline.value) {
        // Retry loading ads if we just got online
        _loadAppOpenAd();
        _loadInterstitialAd();
        _loadRewardedAd();
        _loadNativeAd();
      }
    });
  }

  // ==================== BANNER AD ====================
  Widget buildBannerWidget(AdBannerType type) {
    return _BannerAdWidget(adUnitId: _getBannerAdUnitId(type));
  }

  // ==================== APP OPEN AD ====================
  void _loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('App Open ad loaded');
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('App Open ad failed to load: $error');
          _appOpenAd = null;
          // Check for network errors (simplified check for AdMob error codes)
          if (error.code == 0 || error.code == 2) isOffline.value = true;
        },
      ),
    );
  }

  void onAppPaused() {
    _appPausedTime = DateTime.now();
    debugPrint('App paused at: $_appPausedTime');
  }

  void onAppResumed() {
    if (_appPausedTime != null && !_isShowingAd) {
      final awayDuration = DateTime.now().difference(_appPausedTime!);
      debugPrint('App resumed after: ${awayDuration.inSeconds} seconds');

      if (awayDuration > const Duration(minutes: 2)) {
        showAppOpenAd();
      }
    }
    _appPausedTime = null;
  }

  void showAppOpenAd({VoidCallback? onAdClosed}) {
    if (_appOpenAd == null) {
      debugPrint('App Open ad not ready');
      _loadAppOpenAd();
      return;
    }

    _isShowingAd = true;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('App Open ad showed');
        _logAdEvent('ad_show', 'app_open');
      },
      onAdClicked: (ad) {
        debugPrint('App Open ad clicked');
        _logAdEvent('ad_click', 'app_open');
      },
      onAdImpression: (ad) {
        debugPrint('App Open ad impression');
        _logAdEvent('ad_impression', 'app_open');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('App Open ad dismissed');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('App Open ad failed to show: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
        onAdClosed?.call();
      },
    );

    _appOpenAd!.show();
  }

  // ==================== INTERSTITIAL AD MANAGEMENT ====================

  /// Whether an interstitial can show on Game Over (Always returns true).
  bool canShowGameOverAd() {
    return true;
  }

  /// Whether an interstitial can show on Resume (Always returns true).
  bool canShowResumeAd({required DateTime? pauseTime}) {
    return true;
  }

  // ==================== INTERSTITIAL AD ====================
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded');
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitialAd({VoidCallback? onAdClosed}) {
    if (_interstitialAd == null) {
      debugPrint('Interstitial ad not ready');
      onAdClosed?.call();
      _loadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Interstitial ad showed');
        _logAdEvent('ad_show', 'interstitial');
      },
      onAdClicked: (ad) {
        debugPrint('Interstitial ad clicked');
        _logAdEvent('ad_click', 'interstitial');
      },
      onAdImpression: (ad) {
        debugPrint('Interstitial ad impression');
        _logAdEvent('ad_impression', 'interstitial');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Interstitial ad dismissed');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial ad failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onAdClosed?.call();
      },
    );

    _interstitialAd!.show();
  }

  // ==================== REWARDED AD ====================
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded ad loaded');
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  void showRewardedAd({
    required VoidCallback onRewarded,
    VoidCallback? onAdClosed,
  }) {
    if (_rewardedAd == null) {
      debugPrint('Rewarded ad not ready');
      onAdClosed?.call();
      _loadRewardedAd();
      return;
    }

    bool rewardEarned = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Rewarded ad showed');
        _logAdEvent('ad_show', 'rewarded');
      },
      onAdClicked: (ad) {
        debugPrint('Rewarded ad clicked');
        _logAdEvent('ad_click', 'rewarded');
      },
      onAdImpression: (ad) {
        debugPrint('Rewarded ad impression');
        _logAdEvent('ad_impression', 'rewarded');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Rewarded ad dismissed');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();

        if (rewardEarned) {
          onRewarded();
        }
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        onAdClosed?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        _logAdEvent('ad_reward_earned', 'rewarded');
        rewardEarned = true;
      },
    );
  }

  // ==================== NATIVE AD ====================
  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: _nativeAdUnitId,
      factoryId: 'adFactory',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('Native ad loaded');
        },
        onAdOpened: (ad) {
          debugPrint('Native ad opened');
          AdManager.instance._logAdEvent('ad_open', 'native');
        },
        onAdClicked: (ad) {
          debugPrint('Native ad clicked');
          AdManager.instance._logAdEvent('ad_click', 'native');
        },
        onAdImpression: (ad) {
          debugPrint('Native ad impression');
          AdManager.instance._logAdEvent('ad_impression', 'native');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native ad failed to load: $error');
          ad.dispose();
          _nativeAd = null;
          Future.delayed(const Duration(seconds: 30), _loadNativeAd);
        },
      ),
    )..load();
  }

  Widget? getNativeAdWidget() {
    if (_nativeAd != null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 320,
          minHeight: 320,
          maxWidth: 400,
          maxHeight: 400,
        ),
        child: AdWidget(ad: _nativeAd!),
      );
    }
    return null;
  }

  // Dispose all ads
  void dispose() {
    _connectivitySubscription?.cancel();
    _nativeAd?.dispose();
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}

class _BannerAdWidget extends StatefulWidget {
  final String adUnitId;
  const _BannerAdWidget({required this.adUnitId});

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
              AdManager.instance.isOffline.value = false;
            });
          }
        },
        onAdOpened: (ad) {
          debugPrint('Banner ad opened');
          AdManager.instance._logAdEvent('ad_open', 'banner');
        },
        onAdClicked: (ad) {
          debugPrint('Banner ad clicked');
          AdManager.instance._logAdEvent('ad_click', 'banner');
        },
        onAdImpression: (ad) {
          debugPrint('Banner ad impression');
          AdManager.instance._logAdEvent('ad_impression', 'banner');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
              _bannerAd = null;
            });
          }
          Future.delayed(const Duration(seconds: 15), () {
            if (mounted && _bannerAd == null) _loadAd();
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        height: _bannerAd!.size.height.toDouble(),
        width: _bannerAd!.size.width.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Placeholder for offline/loading state
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Text(
          AdManager.instance.isOffline.value
              ? "PLAYING OFFLINE 🪵"
              : "LOADING...",
          style: AppTheme.bodyStyle.copyWith(
            fontSize: 10,
            letterSpacing: 2,
            color: AppTheme.primary.withValues(alpha: 0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

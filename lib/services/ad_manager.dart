// File: lib/services/ad_manager.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum AdBannerType { home, game }

class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  // Ad instances
  NativeAd? _nativeAd;
  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // State tracking
  DateTime? _appPausedTime;
  bool _isShowingAd = false;

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

  // Initialize all ads
  void initialize() {
    _loadAppOpenAd();
    _loadInterstitialAd();
    _loadRewardedAd();
    _loadNativeAd();
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
        _showAppOpenAd();
      }
    }
    _appPausedTime = null;
  }

  void _showAppOpenAd() {
    if (_appOpenAd == null) {
      debugPrint('App Open ad not ready');
      _loadAppOpenAd();
      return;
    }

    _isShowingAd = true;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('App Open ad showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('App Open ad dismissed');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('App Open ad failed to show: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
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
            });
          }
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
    return const SizedBox(height: 50);
  }
}

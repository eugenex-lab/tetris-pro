import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  // Ad instances
  BannerAd? _bannerAd;
  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // State tracking
  DateTime? _appPausedTime;
  bool _isShowingAd = false;

  // Production Ad Unit IDs from environment variables
  static String get _bannerAdUnitId => Platform.isAndroid
      ? dotenv.env['ADMOB_BANNER_ANDROID']!
      : dotenv.env['ADMOB_BANNER_IOS']!;

  static String get _appOpenAdUnitId => Platform.isAndroid
      ? dotenv.env['ADMOB_APP_OPEN_ANDROID']!
      : dotenv.env['ADMOB_APP_OPEN_IOS']!;

  static String get _interstitialAdUnitId => Platform.isAndroid
      ? dotenv.env['ADMOB_INTERSTITIAL_ANDROID']!
      : dotenv.env['ADMOB_INTERSTITIAL_IOS']!;

  static String get _rewardedAdUnitId => Platform.isAndroid
      ? dotenv.env['ADMOB_REWARDED_ANDROID']!
      : dotenv.env['ADMOB_REWARDED_IOS']!;

  // Initialize all ads
  void initialize() {
    _loadBannerAd();
    _loadAppOpenAd();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  // ==================== BANNER AD ====================
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          _bannerAd = null;
          // Retry after delay
          Future.delayed(const Duration(seconds: 5), _loadBannerAd);
        },
      ),
    )..load();
  }

  Widget? getBannerWidget() {
    if (_bannerAd != null) {
      return SizedBox(
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return null;
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

      // Show ad only if away for more than 2 minutes
      if (awayDuration > const Duration(minutes: 2)) {
        _showAppOpenAd();
      }
    }
    _appPausedTime = null;
  }

  void _showAppOpenAd() {
    if (_appOpenAd == null) {
      debugPrint('App Open ad not ready');
      _loadAppOpenAd(); // Preload for next time
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
        _loadAppOpenAd(); // Reload for next time
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
      _loadInterstitialAd(); // Preload for next time
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
        _loadInterstitialAd(); // Reload for next time
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
      _loadRewardedAd(); // Preload for next time
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
        _loadRewardedAd(); // Reload for next time

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

  // Dispose all ads
  void dispose() {
    _bannerAd?.dispose();
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}

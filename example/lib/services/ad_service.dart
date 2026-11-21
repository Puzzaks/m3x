// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart';
// // import 'package:google_mobile_ads/google_mobile_ads.dart';
//
// /// Real Google Mobile Ads service with official test ad units and debug inspector.
// ///
// /// Handles banner, interstitial, and rewarded ad lifecycles on Android/iOS while
// /// gracefully operating in mock/fallback mode on Windows desktop or web environments.
// class AdService extends ChangeNotifier {
//   static final AdService instance = AdService._();
//   AdService._();
//
//   bool _isInitialized = false;
//   bool _isInterstitialLoaded = false;
//   bool _isRewardedLoaded = false;
//   String? _statusMessage;
//   InterstitialAd? _interstitialAd;
//   RewardedAd? _rewardedAd;
//
//   // Official Google AdMob Test Ad Unit IDs
//   static const String testBannerIdAndroid =
//       'ca-app-pub-3940256099942544/6300978111';
//   static const String testInterstitialIdAndroid =
//       'ca-app-pub-3940256099942544/1033173712';
//   static const String testRewardedIdAndroid =
//       'ca-app-pub-3940256099942544/5224354917';
//
//   bool get isInitialized => _isInitialized;
//   bool get isInterstitialLoaded => _isInterstitialLoaded;
//   bool get isRewardedLoaded => _isRewardedLoaded;
//   String? get statusMessage => _statusMessage;
//
//   bool get isMobilePlatform =>
//       !kIsWeb && (Platform.isAndroid || Platform.isIOS);
//
//   /// Initializes the Google Mobile Ads SDK.
//   Future<void> initialize() async {
//     if (!isMobilePlatform) {
//       _isInitialized = true;
//       _statusMessage = 'Google Mobile Ads bypassed on desktop/web.';
//       notifyListeners();
//       return;
//     }
//
//     try {
//       await MobileAds.instance.initialize();
//       _isInitialized = true;
//       _statusMessage = 'Google Mobile Ads SDK initialized.';
//       loadInterstitialAd();
//       loadRewardedAd();
//     } catch (e) {
//       _statusMessage = 'Mobile Ads init error: $e';
//     }
//     notifyListeners();
//   }
//
//   /// Creates a configured banner ad ready for embedding in the UI.
//   BannerAd? createBannerAd({
//     required VoidCallback onLoaded,
//     required Function(LoadAdError) onFailed,
//   }) {
//     if (!isMobilePlatform) return null;
//
//     final banner = BannerAd(
//       adUnitId: testBannerIdAndroid,
//       size: AdSize.banner,
//       request: const AdRequest(),
//       listener: BannerAdListener(
//         onAdLoaded: (ad) {
//           _statusMessage = 'Test Banner Ad loaded.';
//           notifyListeners();
//           onLoaded();
//         },
//         onAdFailedToLoad: (ad, error) {
//           _statusMessage = 'Banner ad failed: ${error.message}';
//           ad.dispose();
//           notifyListeners();
//           onFailed(error);
//         },
//       ),
//     );
//
//     banner.load();
//     return banner;
//   }
//
//   /// Loads a test interstitial ad.
//   void loadInterstitialAd() {
//     if (!isMobilePlatform) return;
//
//     InterstitialAd.load(
//       adUnitId: testInterstitialIdAndroid,
//       request: const AdRequest(),
//       adLoadCallback: InterstitialAdLoadCallback(
//         onAdLoaded: (ad) {
//           _interstitialAd = ad;
//           _isInterstitialLoaded = true;
//           _statusMessage = 'Test Interstitial Ad loaded and ready.';
//           notifyListeners();
//         },
//         onAdFailedToLoad: (error) {
//           _isInterstitialLoaded = false;
//           _interstitialAd = null;
//           _statusMessage = 'Interstitial load failed: ${error.message}';
//           notifyListeners();
//         },
//       ),
//     );
//   }
//
//   /// Shows the preloaded interstitial ad.
//   void showInterstitialAd({VoidCallback? onDismissed}) {
//     if (_interstitialAd == null) {
//       _statusMessage = 'Interstitial ad not ready yet.';
//       notifyListeners();
//       return;
//     }
//
//     _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
//       onAdDismissedFullScreenContent: (ad) {
//         ad.dispose();
//         _interstitialAd = null;
//         _isInterstitialLoaded = false;
//         _statusMessage = 'Interstitial ad closed by user.';
//         notifyListeners();
//         loadInterstitialAd();
//         onDismissed?.call();
//       },
//       onAdFailedToShowFullScreenContent: (ad, error) {
//         ad.dispose();
//         _interstitialAd = null;
//         _isInterstitialLoaded = false;
//         _statusMessage = 'Interstitial failed to show: ${error.message}';
//         notifyListeners();
//         loadInterstitialAd();
//       },
//     );
//
//     _interstitialAd!.show();
//   }
//
//   /// Loads a test rewarded ad.
//   void loadRewardedAd() {
//     if (!isMobilePlatform) return;
//
//     RewardedAd.load(
//       adUnitId: testRewardedIdAndroid,
//       request: const AdRequest(),
//       rewardedAdLoadCallback: RewardedAdLoadCallback(
//         onAdLoaded: (ad) {
//           _rewardedAd = ad;
//           _isRewardedLoaded = true;
//           _statusMessage = 'Test Rewarded Ad loaded and ready.';
//           notifyListeners();
//         },
//         onAdFailedToLoad: (error) {
//           _isRewardedLoaded = false;
//           _rewardedAd = null;
//           _statusMessage = 'Rewarded load failed: ${error.message}';
//           notifyListeners();
//         },
//       ),
//     );
//   }
//
//   /// Shows the preloaded rewarded ad and delivers the reward callback.
//   void showRewardedAd({required Function(RewardItem reward) onRewarded}) {
//     if (_rewardedAd == null) {
//       _statusMessage = 'Rewarded ad not ready yet.';
//       notifyListeners();
//       return;
//     }
//
//     _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
//       onAdDismissedFullScreenContent: (ad) {
//         ad.dispose();
//         _rewardedAd = null;
//         _isRewardedLoaded = false;
//         _statusMessage = 'Rewarded ad closed.';
//         notifyListeners();
//         loadRewardedAd();
//       },
//       onAdFailedToShowFullScreenContent: (ad, error) {
//         ad.dispose();
//         _rewardedAd = null;
//         _isRewardedLoaded = false;
//         _statusMessage = 'Rewarded ad failed to show: ${error.message}';
//         notifyListeners();
//         loadRewardedAd();
//       },
//     );
//
//     _rewardedAd!.show(
//       onUserEarnedReward: (adWithoutView, reward) {
//         _statusMessage = 'User earned reward: ${reward.amount} ${reward.type}!';
//         notifyListeners();
//         onRewarded(reward);
//       },
//     );
//   }
//
//   @override
//   void dispose() {
//     _interstitialAd?.dispose();
//     _rewardedAd?.dispose();
//     super.dispose();
//   }
// }

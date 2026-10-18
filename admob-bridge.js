import {
  AdMob,
  BannerAdSize,
  BannerAdPosition
} from '@capacitor-community/admob';

(function () {
  const IDS = {
    banner: 'ca-app-pub-7956447630438100/7098615524',
    interstitial: 'ca-app-pub-7956447630438100/3159370511',
    rewarded: 'ca-app-pub-7956447630438100/4640807296'
  };

  let initialized = false;
  let bannerShown = false;

  async function initializeAdMob() {
    if (initialized) return;

    await AdMob.initialize();
    initialized = true;
    console.log('AdMob SDK initialized');
  }

  async function showBanner() {
    await initializeAdMob();

    await AdMob.showBanner({
      adId: IDS.banner,
      adSize: BannerAdSize.ADAPTIVE_BANNER,
      position: BannerAdPosition.BOTTOM_CENTER,
      margin: 0,
      isTesting: true
    });

    bannerShown = true;
  }

  async function hideBanner() {
    await AdMob.hideBanner();
    bannerShown = false;
  }

  async function showInterstitial() {
    await initializeAdMob();

    await AdMob.prepareInterstitial({
      adId: IDS.interstitial,
      isTesting: true
    });

    await AdMob.showInterstitial();
  }

  async function showRewarded() {
    await initializeAdMob();

    await AdMob.prepareRewardVideoAd({
      adId: IDS.rewarded,
      isTesting: true
    });

    const reward = await AdMob.showRewardVideoAd();

    console.log('Rewarded ad completed:', reward);

    return reward;
  }

  window.AdMobBridge = {
    initialize: initializeAdMob,
    showBanner,
    hideBanner,
    showInterstitial,
    showRewarded
  };

  console.log('IndianCraft AdMob bridge loaded');
})();

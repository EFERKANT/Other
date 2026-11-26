// Paylaşılan tarif bağlantısı: uygulama yüklüyse işletim sistemi bağlantıyı
// zaten uygulamada açar. Bu sayfa yalnız uygulama yüklü değilse görünür:
// önce evkahvesi:// şemasını dener, açılmazsa mağazaya yönlendirir
// (KHV-FR-SOC-003).
(function () {
  var PLAY = 'https://play.google.com/store/apps/details?id=__ANDROID_PACKAGE__';
  var APP_STORE = 'https://apps.apple.com/app/id__APP_STORE_ID__';
  var m = location.pathname.match(/\/r\/([A-Za-z0-9_=-]+)/);
  var ua = navigator.userAgent || '';
  var store = /iPhone|iPad|iPod/.test(ua) ? APP_STORE : PLAY;
  var links = document.getElementById('links');
  if (links) {
    document.getElementById('play').href = PLAY;
    document.getElementById('appstore').href = APP_STORE;
  }
  if (!m) return;
  var opened = false;
  document.addEventListener('visibilitychange', function () {
    if (document.hidden) opened = true;
  });
  location.href = 'evkahvesi://r/' + m[1];
  setTimeout(function () {
    if (!opened) location.href = store;
  }, 1500);
})();

#!/usr/bin/env bash
# Ev Kahvesi: macOS geliştirme ortamı kurulumu.
#
# Kullanım (depo kökünden):
#   tool/mac_setup.sh             # bağımlılıkları denetle/kur, iOS'u hazırla
#   tool/mac_setup.sh --keystore  # ayrıca Android yayın imza anahtarı oluştur
#
# Betik yalnız eksik olanı kurar; tekrar çalıştırmak güvenlidir. Şifreler
# terminalde sorulur, hiçbir yere yazdırılmaz; anahtar ve key.properties
# depoya eklenmez (app/android/.gitignore).
set -euo pipefail

FLUTTER_VERSION="3.50.1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/app"
WANT_KEYSTORE=0
[ "${1:-}" = "--keystore" ] && WANT_KEYSTORE=1

step() { printf '\n==> %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

if [ "$(uname -s)" != "Darwin" ]; then
  echo "Bu betik macOS içindir." >&2
  exit 1
fi

step "Xcode"
if ! xcode-select -p >/dev/null 2>&1 || ! have xcodebuild; then
  echo "Xcode bulunamadı. App Store'dan Xcode'u kurup bir kez açın, sonra:"
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  echo "  sudo xcodebuild -runFirstLaunch"
  exit 1
fi
xcodebuild -version | head -1

step "Homebrew"
if ! have brew; then
  echo "Homebrew bulunamadı. https://brew.sh adresindeki tek satırlık komutla kurun ve betiği yeniden çalıştırın."
  exit 1
fi

step "CocoaPods"
have pod || brew install cocoapods
pod --version

step "Flutter $FLUTTER_VERSION"
if ! have flutter; then
  ARCH="$(uname -m)"
  case "$ARCH" in
    arm64) ZIP="flutter_macos_arm64_${FLUTTER_VERSION}-stable.zip" ;;
    *) ZIP="flutter_macos_${FLUTTER_VERSION}-stable.zip" ;;
  esac
  mkdir -p "$HOME/development"
  curl -fL -o "/tmp/$ZIP" "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/$ZIP"
  unzip -q -o "/tmp/$ZIP" -d "$HOME/development"
  rm -f "/tmp/$ZIP"
  export PATH="$HOME/development/flutter/bin:$PATH"
  SHELL_RC="$HOME/.zshrc"
  # shellcheck disable=SC2016 # $HOME ve $PATH kabukta açılmalı.
  grep -q 'development/flutter/bin' "$SHELL_RC" 2>/dev/null ||
    echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >>"$SHELL_RC"
  echo "Flutter kuruldu; yeni terminallerde PATH otomatik gelir."
fi
INSTALLED="$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')"
if [ "$INSTALLED" != "$FLUTTER_VERSION" ]; then
  echo "Uyarı: Flutter $INSTALLED kurulu; proje $FLUTTER_VERSION ile test edildi."
fi
flutter config --no-analytics >/dev/null

step "Proje bağımlılıkları"
(cd "$ROOT/packages/kahve_core" && dart pub get)
(cd "$APP" && flutter pub get && dart run build_runner build --delete-conflicting-outputs)

step "iOS pod kurulumu"
(cd "$APP/ios" && pod install)

step "iOS derleme denemesi (imzasız)"
(cd "$APP" && flutter build ios --debug --no-codesign)

if [ "$WANT_KEYSTORE" = "1" ]; then
  step "Android yayın imza anahtarı"
  if ! have keytool; then
    echo "keytool bulunamadı; Java 17 kuruluyor."
    brew install --cask temurin@17
  fi
  KEYDIR="$HOME/.ev-kahvesi"
  KEYSTORE="$KEYDIR/upload-keystore.jks"
  PROPS="$APP/android/key.properties"
  mkdir -p "$KEYDIR"
  chmod 700 "$KEYDIR"
  if [ -f "$KEYSTORE" ]; then
    echo "Anahtar zaten var: $KEYSTORE (üzerine yazılmadı)."
  else
    read -r -s -p "Anahtar şifresi (en az 6 karakter): " PASS
    echo
    read -r -s -p "Şifre tekrar: " PASS2
    echo
    if [ "$PASS" != "$PASS2" ] || [ "${#PASS}" -lt 6 ]; then
      echo "Şifreler eşleşmiyor veya çok kısa." >&2
      exit 1
    fi
    read -r -p "Ad Soyad veya şirket adı: " CN
    # Şifre komut satırında görünmesin diye ortam değişkeninden okunur.
    KS_PASS="$PASS" keytool -genkeypair -v -keystore "$KEYSTORE" -keyalg RSA \
      -keysize 2048 -validity 10000 -alias upload \
      -storepass:env KS_PASS -keypass:env KS_PASS -dname "CN=$CN, C=TR"
    umask 077
    cat >"$PROPS" <<PROPS
storePassword=$PASS
keyPassword=$PASS
keyAlias=upload
storeFile=$KEYSTORE
PROPS
    unset PASS PASS2
    echo "Anahtar: $KEYSTORE"
    echo "Bu dosyayı ve şifreyi güvenli bir yere yedekleyin; kaybolursa güncelleme yayımlanamaz."
  fi
fi

step "Tamamlandı"
cat <<'NEXT'
Sıradaki adımlar (Xcode):
  1. open app/ios/Runner.xcworkspace
  2. Runner > Signing & Capabilities > Team: Apple hesabınız
  3. Bundle Identifier: uygulama kimliğiniz
  4. iPhone'u bağlayıp Run (⌘R)
NEXT

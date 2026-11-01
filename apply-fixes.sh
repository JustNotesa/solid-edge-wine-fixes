#!/bin/bash
# Fixes for Solid Edge 2026 Community Edition under wine-staging 11.21 (WineHQ build in /opt/wine-staging).
# Run AFTER installing Solid Edge (msiexec /i "Siemens Solid Edge 2026.msi") into $WINEPREFIX.
#   - WebView2 via the Fixed Version Runtime (no installer needed)
#   - Chromium flags that work under Wine
#   - patched d2d1.dll (SVG icons) and win32u.so (stale WebView drawing over the 3D view)
set -e
export WINEPREFIX="${WINEPREFIX:-$HOME/.wineprefixes/solidedge}"
HERE="$(cd "$(dirname "$0")" && pwd)"
WV_VER=156.0.4314.58
WV_CAB="Microsoft.WebView2.FixedVersionRuntime.$WV_VER.x64.cab"
WV_URL="https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/b7919cc9-680d-4253-bf32-732988e68aa6/$WV_CAB"
WINELIB=/opt/wine-staging/lib/wine

# 1. WebView2 Fixed Version Runtime
if [ ! -d "$WINEPREFIX/drive_c/WebView2/Microsoft.WebView2.FixedVersionRuntime.$WV_VER.x64" ]; then
    curl -L -o "/tmp/$WV_CAB" "$WV_URL"
    mkdir -p "$WINEPREFIX/drive_c/WebView2"
    cabextract -q -d "$WINEPREFIX/drive_c/WebView2" "/tmp/$WV_CAB"
fi
WV='C:\WebView2\Microsoft.WebView2.FixedVersionRuntime.'$WV_VER'.x64'
ARGS='--no-sandbox --disable-gpu --disable-gpu-compositing --disable-direct-composition --disable-d3d11 --disable-software-rasterizer --in-process-gpu'
for k in 'HKLM\Software\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}' \
         'HKCU\Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'; do
    wine reg add "$k" /v pv /d $WV_VER /f
    wine reg add "$k" /v location /d "$WV" /f
done
wine reg add 'HKCU\Environment' /v WEBVIEW2_BROWSER_EXECUTABLE_FOLDER /d "$WV" /f
for H in HKCU HKLM; do
    wine reg add "$H\\Software\\Policies\\Microsoft\\Edge\\WebView2\\AdditionalBrowserArguments" /v Edge.exe /d "$ARGS" /f
done
wine reg add 'HKCU\Software\Wine\AppDefaults\msedgewebview2.exe' /v Version /d win10 /f

# 2. Solid Edge: no legacy IE start window (would cover the 3D view), skip Ordered/Synchronous popup
wine reg add 'HKCU\Software\Wine\AppDefaults\Edge.exe\DllOverrides' /v mshtml /d "" /f
wine reg add 'HKCU\Software\Wine\AppDefaults\Edge.exe\DllOverrides' /v ieframe /d "" /f
wine reg add 'HKCU\Software\Siemens\Solid Edge\Version 226\PrefSets\Options-General' \
    /v DoNotShowOrderedDefaultDialog /t REG_BINARY /d 06000000000000000100000000000000 /f

# 3. License file shipped with the Community Edition download
SE="$WINEPREFIX/drive_c/Program Files/Siemens/Solid Edge 2026"
wine reg add 'HKCU\Environment' /v SPLM_LICENSE_SERVER /d 'C:\Program Files\Siemens\Solid Edge 2026\Preferences\SELicense.lic' /f
[ -f "$SE/Preferences/SELicense.lic" ] || echo "NOTE: copy LicenseFile/SELicense.lic from the installer zip to $SE/Preferences/"

# 4. Patched Wine modules (backups as *.orig)
wineserver -w
for f in x86_64-windows/d2d1.dll x86_64-unix/win32u.so; do
    [ -f "$WINELIB/$f.orig" ] || sudo cp "$WINELIB/$f" "$WINELIB/$f.orig"
    sudo cp "$HERE/bin/$(basename $f)" "$WINELIB/$f"
done
cp "$HERE/bin/d2d1.dll" "$WINEPREFIX/drive_c/windows/system32/d2d1.dll"
echo "done - start with: $HERE/run-solidedge.sh"

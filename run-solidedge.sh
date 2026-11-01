#!/bin/bash
export WINEPREFIX="$HOME/.wineprefixes/solidedge"
export WEBVIEW2_BROWSER_EXECUTABLE_FOLDER='C:\WebView2\Microsoft.WebView2.FixedVersionRuntime.156.0.4314.58.x64'
export WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS='--no-sandbox --disable-gpu --disable-gpu-compositing --disable-direct-composition --disable-d3d11 --disable-software-rasterizer --in-process-gpu'
export WINEDEBUG="${WINEDEBUG:--all}"
cd "$WINEPREFIX/drive_c/Program Files/Siemens/Solid Edge 2026/Program" && exec wine Edge.exe "$@"

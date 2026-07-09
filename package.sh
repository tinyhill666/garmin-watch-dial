#!/bin/zsh
# 打包成商店用的 .iq（含 manifest 里所有设备）。
# 用法：./package.sh [pulse|tempo]   不带参数则两个都打
# 产物在 <app>/bin/<app>.iq，用同一把 developer_key.der 签名。
set -e

export SDK_HOME="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b"
export JAVA_HOME="/opt/homebrew/opt/openjdk"
export PATH="$JAVA_HOME/bin:$SDK_HOME/bin:$PATH"

KEY="$HOME/Library/Application Support/Garmin/ConnectIQ/Keys/developer_key.der"
cd "$(dirname "$0")"

APPS=("${@:-pulse tempo}")
for app in ${=APPS}; do
    mkdir -p "$app/bin"
    echo "打包 $app …"
    # -e 打包成 .iq（全设备）  -r release（去调试）  -w 显示警告
    monkeyc -e -r -w -o "$app/bin/$app.iq" -f "$app/monkey.jungle" -y "$KEY"
    echo "  → $app/bin/$app.iq"
done
echo "完成。上传 .iq 到 https://apps.garmin.com 的开发者后台。"

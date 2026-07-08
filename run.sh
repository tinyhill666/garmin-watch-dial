#!/bin/zsh
# 构建并在模拟器中运行表盘。
# 用法：./run.sh [pulse|tempo] [设备]
#   ./run.sh              → pulse / fr955
#   ./run.sh tempo        → tempo / fr955
#   ./run.sh pulse fr970  → pulse / fr970
set -e

export SDK_HOME="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b"
export JAVA_HOME="/opt/homebrew/opt/openjdk"
export PATH="$JAVA_HOME/bin:$SDK_HOME/bin:$PATH"

APP="${1:-pulse}"
DEVICE="${2:-fr955}"
KEY="$HOME/Library/Application Support/Garmin/ConnectIQ/Keys/developer_key.der"

cd "$(dirname "$0")/$APP"

mkdir -p bin
monkeyc -o "bin/$DEVICE.prg" -d "$DEVICE" -f monkey.jungle -y "$KEY"

# 模拟器没启动就先启动，等它就绪
if ! pgrep -f "ConnectIQ.app/Contents/MacOS/simulator" > /dev/null; then
    connectiq
    sleep 5
fi

# monkeydo 会阻塞并输出 System.println 日志，Ctrl-C 退出
monkeydo "bin/$DEVICE.prg" "$DEVICE"

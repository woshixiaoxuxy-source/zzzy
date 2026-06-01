#!/bin/bash

# ============================================
#  历史粘贴板 - 一键构建脚本
# ============================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="历史粘贴板"
BUNDLE_NAME="${APP_NAME}.app"
BUILD_DIR="${PROJECT_DIR}/.build"
APP_DIR="${PROJECT_DIR}/${BUNDLE_NAME}"

echo "🔨 正在编译 ${APP_NAME}..."

# 1. 使用 SwiftPM 编译
cd "${PROJECT_DIR}"
swift build -c release --arch arm64 2>/dev/null || swift build -c release

# 2. 查找编译产物
EXECUTABLE=$(find "${BUILD_DIR}" -name "HistoryClipboard" -type f -not -path "*.dSYM*" | head -1)
if [ -z "${EXECUTABLE}" ]; then
    echo "❌ 找不到编译产物"
    exit 1
fi
echo "✅ 编译完成: ${EXECUTABLE}"

# 3. 创建 .app 包结构
echo "📦 创建应用包..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# 4. 复制可执行文件
cp "${EXECUTABLE}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_DIR}/Contents/MacOS/${APP_NAME}"

# 5. 创建 Info.plist
cat > "${APP_DIR}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>历史粘贴板</string>
    <key>CFBundleDisplayName</key>
    <string>历史粘贴板</string>
    <key>CFBundleIdentifier</key>
    <string>com.historyclipboard.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>历史粘贴板</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# 6. 创建简单的图标（使用 SF Symbol 导出作为占位图标）
# 这里我们使用一个最小的 PNG 图标
if command -v python3 &> /dev/null; then
    python3 -c "
import struct, zlib

def create_png(width, height, color):
    raw = b''
    for y in range(height):
        raw += b'\x00'  # filter byte
        for x in range(width):
            raw += bytes(color)  # RGBA
    compressed = zlib.compress(raw)

    def chunk(ctype, data):
        c = ctype + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) + chunk(b'IDAT', compressed) + chunk(b'IEND', b'')

png = create_png(64, 64, (126, 200, 227, 255))  # 淡蓝色
with open('${APP_DIR}/Contents/Resources/AppIcon.png', 'wb') as f:
    f.write(png)
"
    echo "🎨 图标已生成"
fi

echo ""
echo "============================================"
echo "  ✅ 构建完成！"
echo "  📍 应用位置: ${APP_DIR}"
echo ""
echo "  双击打开即可运行，也可以拖入「应用程序」文件夹"
echo ""
echo "  首次运行时，macOS 可能会提示安全警告。"
echo "  请在「系统偏好设置 → 安全性与隐私」中允许运行。"
echo "============================================"
echo ""

# 7. 询问是否立即打开
read -p "是否立即打开 ${APP_NAME}？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "${APP_DIR}"
    echo "🚀 ${APP_NAME} 已启动，请查看菜单栏（顶部栏右侧）"
fi

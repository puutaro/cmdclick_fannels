#!/bin/bash

### LABELING_SECTION_START
### LABELING_SECTION_END


### SETTING_SECTION_START
terminalDo=ON
openWhere=CW
terminalFocus=OFF
editExecute=NO
setVariableTypes=
beforeCommand=
afterCommand=
execBeforeCtrlCmd=
execAfterCtrlCmd=
appIconPath=
scriptFileName=f1_capture.sh
### SETTING_SECTION_END


### CMD_VARIABLE_SECTION_START
### CMD_VARIABLE_SECTION_END


### Please write bellow with shell script


# --- 設定項目 ---
readonly PARENT_DIR_PATH=$(dirname $0)
readonly CAPTURE_SHELL_DIR_PATH="${PARENT_DIR_PATH}/capture"
readonly CAPTURE_BASE_SHELL_PATH="${CAPTURE_SHELL_DIR_PATH}/capture_base.sh"
readonly CAPTURE_TMP_DIR_PATH="${CAPTURE_SHELL_DIR_PATH}/tmp"
readonly SAVE_DIR="CAPTURE_SAVE_DIR_PATH"
# "/home/haumi/デスクトップ/share/haumi-gp/erma-haumi/Public/娯楽/move/fujinext"
readonly FILE_NAME="CAPTURE_FILE_NAME_$(date +%Y%m%d_%H%M%S).mp4"
readonly DURATION="CAPTURE_DURATION"
# "01:00:00"
case "$(echo "${DURATION}" | grep -E "^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$")" in
    "") echo "DURATION is not correct :${DURATION}"
        exit 1
    ;;
esac
readonly RESOLUTION="$(xrandr | grep '*' | awk '{print $1}')"
# "1920x1080"
# ----------------
# 1. デフォルトの出力先(Sink)を取得
readonly DEFAULT_SINK=$(pactl get-default-sink)

# 2. その出力先の「モニター」名を音声入力として指定
# PipeWire環境でもPulseAudio環境でも動作する指定方法
readonly AUDIO_INPUT="${DEFAULT_SINK}.monitor"

# Firefoxをバックグラウンドで起動（もし既に開いているならこの行は不要）
# firefox &
# sleep 5 # 起動待ち

echo "録画を開始します: $SAVE_DIR/$FILE_NAME"

# ffmpeg 実行
# -f x11grab: 画面キャプチャ
# -f pulse -i default: システム音声をキャプチャ
ffmpeg -f x11grab \
    -video_size "$RESOLUTION" \
    -i :0.0 \
    -f pulse \
    -i "${AUDIO_INPUT}" \
    -t "$DURATION" \
    -c:v libx264 \
    -preset fast \
    -crf 23 \
    -c:a aac \
    -b:a 128k \
    "$SAVE_DIR/$FILE_NAME"

echo "録画が終了しました。"

# by gpu
# ffmpeg \
#     -vaapi_device /dev/dri/renderD128 \
#     -video_size "$RESOLUTION" \
#     -i "${AUDIO_INPUT}" \
#     -f pulse \
#     -t "$DURATION" \
#     -preset fast \
#     -vf 'format=nv12,hwupload' \
#     -c:v h264_vaapi \
#     -qp 24 \
#     "$SAVE_DIR/$FILE_NAME"

#!/bin/bash

### LABELING_SECTION_START
### LABELING_SECTION_END


### SETTING_SECTION_START
terminalDo=ON
openWhere=CW
terminalFocus=OFF
editExecute=ONCE
setVariableTypes="AFTER:CB=today!tomorrow"
setVariableTypes="MODE:CB=setQ!watchQ"
setVariableTypes="continueSwitch:CB=ON!OFF"
beforeCommand=
afterCommand=
execBeforeCtrlCmd=
execAfterCtrlCmd=
appIconPath=
scriptFileName=movie_capture.sh
### SETTING_SECTION_END


### CMD_VARIABLE_SECTION_START
MODE=setQ
CAPTURE_NAME=f1マイアミ予選-2026
CAPTURE_DURATION=02:30:00
CAPTURE_SAVE_DIR_PATH=/home/vubabu/デスクトップ/share/haumi-gp/erma-haumi/Public/娯楽/move/f1/2026_f1マイアミ
START_TIME=04:50
continueSwitch=OFF
AFTER=tomorrow
### CMD_VARIABLE_SECTION_END


### Please write bellow with shell script

set -ue

watchQue(){
	local qCon="$(atq)"
	case "${qCon}" in
		"")
			echo "q not found"
			;;
	esac
	echo "${qCon}" \
	| aku apl "echo -n '@{1} @{2} @{3} @{4} @{5} @{6}';at -c @{1} | sed '/^$/d' | tail -1 | sed 's/.*bash//'" \
	| sed "s/'//"\
	| fzf \
	| awk '{print "atrm "$1}'
}

case "${MODE}" in
	"watchQ")
		watchQue
		exit 0
		;;
esac


if [ ! -d "${CAPTURE_SAVE_DIR_PATH}"  ];then
	echo "CAPTURE_SAVE_DIR_PATH not found: ${CAPTURE_SAVE_DIR_PATH}"
	exit 1
fi
case "$(echo "${CAPTURE_DURATION}" | grep -E "^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$")" in
    "") echo "CAPTURE_DURATION is not correct :${CAPTURE_DURATION}"
        exit 1
    ;;
esac
case "$(echo "${START_TIME}" | grep -E "^[0-9][0-9]:[0-9][0-9]$")" in
    "") echo "START_TIME is not correct :${START_TIME}"
        exit 1
    ;;
esac

readonly NOW_TIME="00:00"
readonly FANNEL_DIR_PATH="$(dirname "${0}")"
readonly FILE_NAME_REGEX="$(basename "${0}")$"
readonly CAPTURE_DIR_PATH="${FANNEL_DIR_PATH}/movie_captureDir"
readonly CAPTURE_BASE_SHELL_PATH="${CAPTURE_DIR_PATH}/capture_base.sh"
readonly CAPTURE_FILE_NAME="${CAPTURE_NAME}_${START_TIME//[^a-zA-Z0-9]/}_${AFTER//[^a-zA-Z0-9]/}_${CAPTURE_DURATION//[^a-zA-Z0-9]/}_$(date "+%Y%m%d%H%M%S")"
readonly CAPTURE_SHELL_NAME="${CAPTURE_NAME}_${START_TIME//[^a-zA-Z0-9]/}_${AFTER//[^a-zA-Z0-9]/}_${CAPTURE_DURATION//[^a-zA-Z0-9]/}_$(date "+%Y%m%d%H%M%S").sh"
readonly CAPTURE_TMP_DIR_PATH="${CAPTURE_DIR_PATH}/tmp"
mkdir -p "${CAPTURE_TMP_DIR_PATH}"
readonly CAPTURE_SHELL_PATH="${CAPTURE_TMP_DIR_PATH}/${CAPTURE_SHELL_NAME}"
readonly continueBaseShellName="continue.sh"
readonly CONTINUE_BASE_SHELL_PATH="${CAPTURE_DIR_PATH}/${continueBaseShellName}"
readonly CONTINUE_SHELL_PATH="${CAPTURE_TMP_DIR_PATH}/${continueBaseShellName%.sh}_${RANDOM}.sh"
if [ -f "${CONTINUE_SHELL_PATH}" ];then
	echo "CONTINUE_SHELL_PATH is exist: ${CONTINUE_SHELL_PATH}"
	exit 1
fi
make_capture_shell(){
	awk \
		-v CAPTURE_BASE_SHELL_CON="$(cat "${CAPTURE_BASE_SHELL_PATH}")" \
		-v CAPTURE_FILE_NAME="${CAPTURE_FILE_NAME}" \
		-v CAPTURE_SAVE_DIR_PATH="${CAPTURE_SAVE_DIR_PATH}" \
		-v CAPTURE_DURATION="${CAPTURE_DURATION}" \
	'BEGIN{
		gsub("CAPTURE_FILE_NAME", CAPTURE_FILE_NAME, CAPTURE_BASE_SHELL_CON)
		gsub("CAPTURE_SAVE_DIR_PATH", CAPTURE_SAVE_DIR_PATH, CAPTURE_BASE_SHELL_CON)
		gsub("CAPTURE_DURATION", CAPTURE_DURATION, CAPTURE_BASE_SHELL_CON)
		print CAPTURE_BASE_SHELL_CON
	}' >> "${CAPTURE_SHELL_PATH}"
}
# --- 追加：終了処理の定義 ---
# バックグラウンドプロセスのPIDを格納する変数（初期値は空）
CHILD_PID=""

cleanup() {
    # CHILD_PID が空でなければ kill を実行
    if [ -n "${CHILD_PID}" ]; then
        echo "Terminating background process (PID: ${CHILD_PID})..."
        kill "${CHILD_PID}" 2>/dev/null || true
    fi
  # CHILD_PIDたスクリプトも削除
    if [ -f "${CONTINUE_SHELL_PATH:-}" ]; then
        rm -f "${CONTINUE_SHELL_PATH}"
    fi
    exit 0
}

# SIGINT(Ctrl+C), SIGTERM(終了要求), SIGTSTP(Ctrl+Z) をトラップ
# Ctrl+Zでも一時停止せず終了させる設定
trap cleanup SIGINT SIGTERM SIGTSTP
# ---------------------------
# readonly CAPTURE_FILE_PATH="${CAPTURE_SAVE_DIR_PATH}/${CAPTURE_FILE_NAME}"

case "${continueSwitch}" in
    "ON")
    	cp \
    		-vf \
    		"${CONTINUE_BASE_SHELL_PATH}" \
    		"${CONTINUE_SHELL_PATH}"
        bash "${CONTINUE_SHELL_PATH}" "${FILE_NAME_REGEX}" &
        # 直前に実行したバックグラウンドプロセスのPIDをグローバル変数に保持
        CHILD_PID=$!
        echo "Background prochild_pidted with PID: ${CHILD_PID}"
        ;;
esac

make_capture_shell

case "${START_TIME}" in
	"${NOW_TIME}")
		bash ${CAPTURE_SHELL_PATH}
		exit 0
	;;
esac


echo "export DISPLAY=:0 && bash '${CAPTURE_SHELL_PATH}'" | at ${START_TIME} ${AFTER}
cleanup

#!/bin/bash

### LABELING_SECTION_START
### LABELING_SECTION_END


### SETTING_SECTION_START
terminalDo=ON
openWhere=CW
terminalFocus=OFF
editExecute=ONCE
setVariableTypes=""
beforeCommand=
afterCommand=
execBeforeCtrlCmd=
execAfterCtrlCmd=
appIconPath=
scriptFileName=send_k_procecing1.sh
### SETTING_SECTION_END


### CMD_VARIABLE_SECTION_START
procNameRegex="movie_capture.sh$"
### CMD_VARIABLE_SECTION_END


### Please write bellow with shell script


set -ue
case "${1:-}" in
    "");;
    *)
        procNameRegex="${1}"
        ;;
esac

TIMES=0
while true; do
	# 30分（1800秒）待機
    sleep 600
    # sleep 1
    TIMES=$(( ${TIMES} + 1 ))
    # プロセスの存在を確認（pgrepの方が軽量でgrep自体の誤検知も防げます）
    if pgrep -f "${procNameRegex}" > /dev/null; then
        TIMES=0
    elif [ ${TIMES} -ge 3 ]; then
        echo "プロセスが見つからないため、監視を終了します。"
        break
    fi
    xdotool type @
done

 

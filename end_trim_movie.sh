#!/bin/bash

### LABELING_SECTION_START
### LABELING_SECTION_END


### SETTING_SECTION_START
terminalDo=ON
openWhere=CW
terminalFocus=OFF
editExecute=ONCE
setVariableTypes=
beforeCommand=
afterCommand=
execBeforeCtrlCmd=
execAfterCtrlCmd=
appIconPath=
scriptFileName=end_trim_movie.sh
### SETTING_SECTION_END


### CMD_VARIABLE_SECTION_START
srcPath=/home/haumi/デスクトップ/share/haumi-gp/erma-haumi/Public/娯楽/move/anime/gintama_first/gintama_first_1_29_0000_today_500000_20260418082113_20260418_082113.mp4
cutStartTime="00:45:00"
### CMD_VARIABLE_SECTION_END


### Please write bellow with shell script

if [ ! -f "${srcPath}" ];then
	echo "srcPath not found: ${srcPath}"
	exit 1
fi
case "$(echo "${cutStartTime}" | grep -E "^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$")" in
    "") echo "cutStartTime is not correct :${cutStartTime}"
        exit 1
    ;;
esac
readonly destPath="$(\
	echo "${srcPath}"\
	| sed -r 's/(\.mp4)/_end_trim\1/' \
)"

rm -f "${destPath}"
# 最初〜途中まで
ffmpeg \
  -ss "00:00:00" \
  -to "${cutStartTime}" \
  -i "${srcPath}" \
  -c copy \
  -sn "${destPath}"

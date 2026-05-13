#!/bin/bash

### LABELING_SECTION_START
### LABELING_SECTION_END


### SETTING_SECTION_START
terminalDo=ON
openWhere=CW
terminalFocus=OFF
editExecute=ONCE
setVariableTypes="width:CB=1080!768!384!200"
setVariableTypes="lang:CB=ja!en!ko"
setVariableTypes="model:CB=tiny!base!large-v3-turbo!ko"
# setVariableTypes="outDirPath:DIR="
beforeCommand=
afterCommand=
execBeforeCtrlCmd=
execAfterCtrlCmd=
appIconPath=
scriptFileName=kamisibai.sh
### SETTING_SECTION_END


### CMD_VARIABLE_SECTION_START
srcMp4Path=/mnt/bigvol/bigshare/娯楽/move/story_neta/hack_wirus/3hhack/3時間でハッキング実践入門_0000_today_040000_20260512150845_20260512_150845.mp4
outDirPath=/mnt/bigvol/bigshare/娯楽/move/story_neta/hack_wirus/3hhack/3時間でハッキング実践入門kami
prompt=kaliLinuxでもってハッキングを初心者にもわかりやすく体験してもらう動画
lang=ja
model=large-v3-turbo
### CMD_VARIABLE_SECTION_END


### Please write bellow with shell script


set -ue
aku iro "bold,green" -i "mp4: $(basename "${srcMp4Path}")"
aku iro  "blue" -i "outDirPath: ${outDirPath}"
aku iro "color:green,bold" -i "prompt: ${prompt}"
aku iro "color:green" -i "lang: ${lang}"

rm -rf "${outDirPath}"
mkdir -p "${outDirPath}"
readonly KAMISIBAI_DIR_PATH="$(dirname $0)/kamisibaiDir"
readonly PY_SCRIPT_PATH="${KAMISIBAI_DIR_PATH}/kamisibai3.py"

time \
	/home/haumi/venv/bin/python \
	"${PY_SCRIPT_PATH}" \
	--src "${srcMp4Path}" \
	--out "${outDirPath}" \
	--prompt "${prompt}" \
	--lang "${lang}" \
	--model "${model}"
readonly HTML_PATH="${outDirPath}/index.html"
brave-browser \
	"${HTML_PATH}"

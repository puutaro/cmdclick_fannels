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
srcMp4Path=/home/haumi/デスクトップ/share/haumi-gp/erma-haumi/Public/娯楽/move/anime/gintama_first/gintama_45_min_first_1_29_0000_today_500000_20260418082113_20260418_082113_end_trim.mp4
outDirPath=/home/haumi/デスクトップ/share/temp/pra/kami
width=384
prompt=ああ、んっ、はぁ、はぁ.声なき声が多いアダルトビデオ。おじさん舐めて欲しいの？チンしゃぶ大好き制服少女のキスしてタマ舐め竿パックンに中年チ○ポが爆発_小野六花
lang=ja
model=tiny
### CMD_VARIABLE_SECTION_END


### Please write bellow with shell script


set -ue
aku iro "bold,green" -i "mp4: $(basename "${srcMp4Path}")"
aku iro  "blue" -i "outDirPath: ${outDirPath}"
aku iro "color:green,bold" -i "prompt: ${prompt}"
aku iro "color:blue" -i "width: ${width}"
aku iro "color:green" -i "lang: ${lang}"

rm -rf "${outDirPath}"
mkdir -p "${outDirPath}"
readonly KAMISIBAI_DIR_PATH="$(dirname $0)/kamisibaiDir"
readonly PY_SCRIPT_PATH="${KAMISIBAI_DIR_PATH}/kamisibai.py"

time \
	/home/haumi/venv/bin/python \
	"${PY_SCRIPT_PATH}" \
	--src "${srcMp4Path}" \
	--out "${outDirPath}" \
	--width "${width}" \
	--prompt "${prompt}" \
	--lang "${lang}" \
	--model "${model}"
readonly HTML_PATH="${outDirPath}/index.html"
brave-browser \
	"${HTML_PATH}"

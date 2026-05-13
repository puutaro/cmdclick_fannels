#!/bin/bash

### LABELING_SECTION_START
### LABELING_SECTION_END


### SETTING_SECTION_START
terminalDo=ON
openWhere=CW
terminalFocus=ON
editExecute=ONCE
setVariableTypes="onLoop:CB=ON!OFF"
setVariableTypes="mode:CB=history!search!play!paste"
setVariableTypes="onDebug:CB=ON!OFF"
beforeCommand=
afterCommand=
execBeforeCtrlCmd=
execAfterCtrlCmd=
appIconPath=
scriptFileName=vlc_play.sh
### SETTING_SECTION_END


### CMD_VARIABLE_SECTION_START
mode=search
playMp4Name=f1マイアミスプリント予選-2026_2220_today_021000_20260502165021_20260502_222000.mp4
moveDirPrefix=/mnt/bigvol/bigshare/娯楽/move
onLoop=ON
onDebug=OFF
### CMD_VARIABLE_SECTION_END


### Please write bellow with shell script


set -ue

readonly VLC_PLAY_DIR_PATH="$(dirname "${0}")/vlc_playDir"
readonly VLC_PLAY_HISTORY_PATH="${VLC_PLAY_DIR_PATH}/history.txt"

exec_vlc_play(){
	local playMp4PathArg="${1}"
	if [ ! -f "${playMp4PathArg}" ];then
		echo "playMp4Path not exit: ${playMp4PathArg}"
		exit 1
	fi

	local option="-f"
	case "${onLoop}" in
		ON)
			option="${option} --loop"
			;;
		*) ;;
	esac
	local debugRedirect=" "
	case "${onDebug}" in
		OFF)
			vlc \
				${option} \
				"${playMp4PathArg}" \
				>/dev/null 2>&1 &
			;;
		*)
			vlc \
				${option} \
				"${playMp4PathArg}" &
			;;
	esac
	local save_play_history_con=$(\
		cat \
			<(cat "${VLC_PLAY_HISTORY_PATH}") \
			<(echo -e "$(date '+%Y-%m-%d_%H:%M')\t${playMp4PathArg}") \
		| sed '/^$/d' \
		| tac \
		| uniq -f 1 \
		| tac \
		| tail -100  \
	)
	sleep 0.5
	echo "${save_play_history_con}" \
		> "${VLC_PLAY_HISTORY_PATH}"
}
get_mp4_path_from_history(){
	local vlc_play_history_con=$(\
		cat "${VLC_PLAY_HISTORY_PATH}")
	case "${vlc_play_history_con}" in
		"")
			echo "vlc_play_history_con is blank: ${vlc_play_history_con}"
			exit 1
			;;
	esac
	local vlc_play_history_file_name_con=$(\
		echo "${vlc_play_history_con}" \
		| awk -F'\t' '{
	    n = split($2, path, "/");
	    file_name=path[n]
	    file_prefix=path[n-3]"|"path[n-2]
	    print $1 "\t" file_prefix"|"file_name "\t" $2"\t"file_prefix
	}')
	echo "${vlc_play_history_file_name_con}"\
		| tac \
		| fzf \
			--cycle \
			--preview 'echo {} | cut -f 4; echo {} | cut -f 2 | sed "s/\.mp4//"  | cut -d"|" -f 3 | sed -E "s/[0-9]{4}.*//"; echo "";echo {} | cut -f 2 | sed "s/\.mp4//" | cut -d"|" -f 3 | curl -s "https://www.themoviedb.org/search/movie?language=ja-JP&query=$(cat | sed -E "s/_.*//" |  jq -sRr @uri)"  | grep -oP "(?<=<p>).*?(?=</p>)" | head -1 | fold -w 40; echo "";echo {}| cut -f 3 | mediainfo "$(cat)"' \
			--bind 'alt-b:execute(echo {} | cut -f 2 | sed "s/\.mp4//" | cut -d"|" -f 3 | brave-browser "https://www.google.com/search?q=$(cat | sed -E "s/_.*//" | sed "s/$/ どんな内容？/" |  jq -sRr @uri)")' \
		| awk -F'\t' '{print $3}'
}
focus_termial(){
	local SEARCH_WINDOW="xfce4-terminal.Xfce4-terminal"

	local ACTIVATE_ACTIVE_WINDOW_ID=$(wmctrl -xl | grep "${SEARCH_WINDOW}" | tail -n -1 | awk '{print $1}')
	case "${ACTIVATE_ACTIVE_WINDOW_ID}" in 
		"") 
			xfce4-terminal --title "${SEARCH_WINDOW}" --maximize &
			exit 0
			;;
		*) 
			wmctrl -i -a ${ACTIVATE_ACTIVE_WINDOW_ID} 
			;; esac
}
PLAY_MP4_NAME_ENTRY=""
MODE_ENTRY=""
read_args(){
	local STR=""
	while (( $# > 0 ))
	do
	case "${1}" in
		--mode)
			MODE_ENTRY="${2}"
			shift
			;;
		-*)
			echo "no option: ${1}"
			exit 1
			;;
		*)	
			PLAY_MP4_NAME_ENTRY+="${1:-}"
			;;
	esac
	shift
	done
}
read_args "${@}"

case "${MODE_ENTRY}" in
	"");;
	*)
		mode="${MODE_ENTRY}"
		;;
		*)
		;;
esac

echo "mode: ${mode}"
case "${mode}" in
	"history")
		playMp4Path=$(\
			get_mp4_path_from_history)
		test -z "${playMp4Path}" \
		&& exit 0
		;;
	"search")
		playMp4Name=$(\
			find "${moveDirPrefix}"\
				-type f  -name '*.mp4'\
			| tac \
			| awk '{
			    n = split($0, path, "/");
			    file_name=path[n]
			    file_prefix=path[n-3]"|"path[n-2]
			    print file_prefix "|" file_name "\t"$0"\t"file_prefix
			}' \
			| fzf \
				--cycle \
				--preview 'echo {} | cut -f 3 ;echo {} | cut -f 1  | cut -d"|" -f 3 | sed "s/\.mp4//" | sed -E "s/[0-9]{4}.*//"; echo "";echo {} | cut -f 1 | sed "s/\.mp4//" | cut -d"|" -f 3 | curl -s "https://www.themoviedb.org/search/movie?language=ja-JP&query=$(cat | sed -E "s/_.*//" |  jq -sRr @uri)"  | grep -oP "(?<=<p>).*?(?=</p>)" | head -1 | fold -w 40; echo ""; echo {}  | cut -f 2 | mediainfo "$(cat)"' \
			--bind 'alt-b:execute(echo {} | cut -f 1 | sed "s/\.mp4//" | cut -d"|" -f 3 | brave-browser "https://www.google.com/search?q=$(cat | sed -E "s/_.*//" | sed "s/$/ どんな内容？/" |  jq -sRr @uri)")' \
			| cut -f 1\
			| awk '{
			    n = split($1, path, "|");
			    file_name=path[n]
			    gsub(/\.mp4$/, "", file_name)
			    print file_name
			}'\
		)
		test -z "${playMp4Name}" \
		&& exit 0
		echo playMp4Name ${playMp4Name}
		playMp4Path=$(\
			find "${moveDirPrefix}"\
				-type f \
			| awk '{
				if($0 !~ /\.mp4$/) next
				if($0 !~ "'${playMp4Name//\/\\\\/}'") next
				print $0
			}'\
		)
		echo aa
		echo ${playMp4Path}
		test $(echo "${playMp4Path}" | wc -l) -ge 2 \
			&& echo -e "playMp4Path is multiple:\n\n${playMp4Path}" \
				| aku iro "color:red" \
			&& exit 1
		sleep 0.5
		;;
	paste)
		playMp4Name="$(basename "${PLAY_MP4_NAME_ENTRY}")"
		test -z "${playMp4Name}" && exit 1 || echo ""
		cat "${0}" > "${VLC_PLAY_DIR_PATH}/$(basename $0).bk"
		sed \
			-e "s|^playMp4Name=.*|playMp4Name=${playMp4Name}|" \
			-i "${0}"
		sleep 0.5
		focus_termial
		sleep 0.2
		xdotool type "bash ${0} --mode play"
		xdotool key  Return
		exit 1

		;;
	*)
		aku iro -i "playMp4Name: ${playMp4Name}"
		playMp4Path=$(\
			find "${moveDirPrefix}"\
				-type f \
			| awk '{
				if($0 !~ /\.mp4$/) next
				if($0 !~ "'${playMp4Name//\/\\\\/}'") next
				print $0
			}'
		)
		test $(echo "${playMp4Path}" | wc -l) -ge 2 \
			&& echo -e "playMp4Path is multiple:\n\n${playMp4Path}" \
				| aku iro "color:red" \
			&& exit 1
		sleep 0.5
		;;
esac
aku iro "color:blue" -i "playMp4Path: ${playMp4Path}"
exec_vlc_play \
	"${playMp4Path}" \
	"${onLoop}"

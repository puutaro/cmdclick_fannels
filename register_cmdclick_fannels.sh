#!/bin/bash

### LABELING_SECTION_START
### LABELING_SECTION_END


### SETTING_SECTION_START
terminalDo=ON
openWhere=CW
terminalFocus=ON
editExecute=ONCE
setVariableTypes="mode:CB=register!status!reset!commit"
setVariableTypes="targetFannelNum:CB=ONE!ALL"
beforeCommand=
afterCommand=
execBeforeCtrlCmd=
execAfterCtrlCmd=
appIconPath=
scriptFileName=register_cmdclick_fannels.sh
### SETTING_SECTION_END


### CMD_VARIABLE_SECTION_START
mode=register
targetFannelNum=ONE
### CMD_VARIABLE_SECTION_END


### Please write bellow with shell script

set -ue

readonly GIT_DIR_PATH="/home/haumi/デスクトップ/share/shell/cmdclick_fannels"
readonly APP_DIR_PATH="$(dirname "$0")"
readonly FANNEL_DIR_NAME="$(basename "${0}" | sed 's/\.sh$/Dir/')"
readonly FANNEL_DIR_PATH="${APP_DIR_PATH}/${FANNEL_DIR_NAME}"
readonly FANNEL_LIST_PATH="${FANNEL_DIR_PATH}/fannel_list.txt"
readonly TMP_DIR_PATH="${FANNEL_DIR_PATH}/tmp"
readonly CP_SHELL_PATH="${TMP_DIR_PATH}/exec_cp.sh"

make_cp_and_mkdir(){
	local path_and_relativepath="$(cat -)"
	local target_fannel_app_dir_path_arg="${1}"
	echo "${path_and_relativepath}" \
		| awk \
		-v target_fannel_app_dir_path_arg="^${target_fannel_app_dir_path_arg//\//\\\/}"\
	 '{
	 	src_path=$0
	 	dest_path=$0
	 	gsub(target_fannel_app_dir_path_arg, "'${GIT_DIR_PATH}'", dest_path)
	 	cp_cmd=sprintf("cp -avf \x22%s\x22 \x22%s\x22", src_path, dest_path)
	 	mkdir_cmd=sprintf("mkdir -p \x22$(dirname \x22%s\x22)\x22", dest_path)
	 	printf("%s || %s && %s\n", cp_cmd, mkdir_cmd, cp_cmd)
	}'
}

make_cp_list(){
	while IFS= read -r line; do
		local target_fannel_path="${line}"
		local target_fannel_app_dir_path="$(dirname "${target_fannel_path}")"
		local target_fannel_dir_path="${target_fannel_app_dir_path}/$(basename "${target_fannel_path}" | sed 's/\.sh$/Dir/')"
		echo "${target_fannel_path}"\
		| make_cp_and_mkdir \
			"${target_fannel_app_dir_path}"
		if [ ! -d "${target_fannel_dir_path}"  ]	;then
			return
		fi
		local escape_list_path="${target_fannel_dir_path}/escape_list.txt"
		eval "\
			fd -IH -t f \
				$(\
					cat "${escape_list_path}" \
						| rga -v "^#" \
						| sed \
							-e 's/\[/\\\[/g' \
							-e 's/\]/\\\]/g' \
							-re "s/^([^ ])/\/\1/" \
							-re "s/([^ ])$/\1/" \
							-e 's/\/\//\//' \
							-re 's/^([^ ])/ -E\ \1/' \
						| tr '\n' " "\
				) \
				. \
				\"${target_fannel_dir_path}\"\
			" \
		| make_cp_and_mkdir \
			"${target_fannel_app_dir_path}"
	done
}
handle_one_or_all(){
	local conArg="$(cat -)"
	case "${targetFannelNum}" in
	"ONE")
		echo "${conArg}" | awk '{
			full_path = $0
		    n = split($1, path, "/");
		    file_name=path[n]
		    print file_name "\t" $0
		}' | fzf \
		| cut -f 2
		;;
	"ALL")
		echo "${conArg}"
		;;
esac \

}
git_status(){
	cd "${GIT_DIR_PATH}"
	git status \
	| aku iro "color:blue"

}
git_reset(){
	cd "${GIT_DIR_PATH}"
	git checkout .
	git_status

}
git_commit(){
	cd "${GIT_DIR_PATH}"
	git commit
}

exec_register(){
	cat "${FANNEL_LIST_PATH}" \
	| aku trm -p "#" \
	| sed '/^$/d' \
	| handle_one_or_all \
	| make_cp_list \
	| sed '1i #!/bin/bash' \
	> "${CP_SHELL_PATH}"

	bash "${CP_SHELL_PATH}" \
			| aku iro
	git_status
}
case  "${mode}" in
	"status")
		git_status
		;;
	"reset")
		git_reset
		;;
	"commit")
		git_commit
		;;
	*)
		exec_register
		;;
esac

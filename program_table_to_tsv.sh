#!/bin/bash

### LABELING_SECTION_START
### LABELING_SECTION_END


### SETTING_SECTION_START
terminalDo=ON
openWhere=CW
terminalFocus=ON
editExecute=ONCE
setVariableTypes="grepMode:CB=OFF!OR!AND"
setVariableTypes="ignoreLine:NUM=0!0..100000!5"
beforeCommand=
afterCommand=
execBeforeCtrlCmd=
execAfterCtrlCmd=
appIconPath=
scriptFileName=program_table_to_tsv.sh
### SETTING_SECTION_END


### CMD_VARIABLE_SECTION_START
cutDays=04月11日
grepMode=OR
grepWords1=F1
grepWords2=ダンス
grepWords3=スケート
grepWords4=FORMULA
grepWords5=女
grepWords6=
programUrl1=https://otn.fujitv.co.jp/schedule/next/next_week.html
programUrl2=https://otn.fujitv.co.jp/schedule/next/next2_week.html
programUrl3=https://otn.fujitv.co.jp/schedule/next/next3_week.html
programUrl4=""
### CMD_VARIABLE_SECTION_END


### Please write bellow with shell script

ignore_word(){
	case "${cutDays}" in
		"")
			cat "${1:-/dev/stdin}"
			return
			;;
	esac
	cat "${1:-/dev/stdin}" \
	| tac \
	| awk \
		-v cutDays="^${cutDays}"\
		 '!found && $0 ~ cutDays{
			 	found=1;
			 	next
			 }
	 	!found {
 		 	print $0
	 	}
		 ' \
		 | tac
}
# echo a
# cd "/home/haumi/デスクトップ/share/shell/cmdclick/full_use/"
# cat "table.html" 
output_program(){
	curl -s "${1}" |awk '
		function get_row_span(tag_line, rstart, rlength){
			td_tag = substr(tag_line, rstart, rlength)
			# print "td_tag "td_tag
		    # rowspan="数字" の部分を抽出
		    if (match(td_tag, /rowspan="([0-9]+)"/, arr)) {
		        # matchの第3引数(arr)が使えるのはGNU awk (gawk) です
		        return arr[1]
		    }
		    # rowspanの記述がない場合はデフォルトの1
		    return 1
		}
		function detect_less_col(arr){
		    min_idx = 1
		    min_val = 10000000000
		    for (i = 1; i <= 7; i++) {
		        if (arr[i] < min_val) {
		            min_val = arr[i]
		            min_idx = i
		        }
		    }
		    return min_idx
		}
		function fix_time(t,    arr) {
		    # コロンで分割して配列 arr に入れる
		    split(t, arr, ":")
		    # arr[1]（時）を2桁ゼロ埋め、arr[2]（分）をそのまま結合
		    res = sprintf("%02d:%s", arr[1], arr[2])
		    gsub(/\r/, "", res)
		    return res
		}
		function fix_date(d,    arr) {
		    # 正規表現で「数字 月 数字 日」の部分を抽出する
		    # 例: "4月5日" から "4" と "5" を取り出す
		    if (match(d, /([0-9]+)月([0-9]+)日/, arr)) {
		        month = arr[1]
		        day = arr[2]

		        # 曜日（例：「（日）」や「日」など）が後ろについている場合はそれも取得
		        # "日" の後ろに続く文字列をすべて取得
		        sub(/.*[0-9]+日/, "", d)
		        weekday = d

		        # 月と日を2桁にゼロ埋めして再結合
		        return sprintf("%02d月%02d日%s", month, day, weekday)
		    }
		    # マッチしない場合はそのまま返す
		    return d
		}
		BEGIN {
		    # タブ区切り
		    OFS = "\t"
		    # 曜日のインデックス
		    # 1:月, 2:火, 3:水, 4:木, 5:金, 6:土, 7:日
		    col_idx = 0
		    col_rowspan[1] = 0
			is_date_update = 0
			is_time_update = 0
			is_title_update = 0
			is_sub_update = 0
		}

		# 1. <thead>から日付（ヘッダー）を抽出
		/<thead>/,/<\/thead>/ {
		    if (/<p class="oa">/) {
		        # タグを除去して日付を抽出
		        gsub(/<[^>]*>/, "", $0)
		        gsub(/^[ \t]+|[ \t]+$/, "", $0)
		        # gsub(/[（）]/, "", $0)
		        gsub(/\r/, "", $0)
                # gsub(/[（）]/, "", $0)
		        dates_str[++num_dates] = fix_date($0)
		    }
		}

		# 2. <tbody>から時間、タイトル、サブタイトルを抽出
		/<tbody>/,/<\/tbody>/ {
		    # <td>の開始を見つけたら、曜日（列）のカウンタを進める
		  	if (match($0, /<td[^>]*>/)) {
				is_date_update = 1
				# print "td " $0
				cur_row_span = get_row_span($0, RSTART, RLENGTH)
				# print "get row_span "cur_row_span
				less_col = detect_less_col(col_rowspan)
				# print "less col "less_col
				col_rowspan[less_col] += cur_row_span
				# next
				# col_idx++
				# # 1行に7日分を超えるtdがある場合はリセット（不規則テーブルの補正）
				# if (col_idx > 7) col_idx = 1

		  	}

		    # 放送時間
		    if (/<p class="time">/) {
				is_time_update = 1
			    current_time_entry = $0
			    # gsub(/<[^>]*>/, "", current_time_entry)
			    # gsub(/^[ \t]+|[ \t]+$/, "", current_time_entry)
			    gsub(/<[^>]*>/, "", current_time_entry)
			    gsub(/^[ \t]+|[ \t]+$/, "", current_time_entry)
			    # print "current_time_entry "current_time_entry
			    # print "current_time "current_time
			    current_time = fix_time(current_time_entry)
			    # print "current_time "current_time

		    }

		    # 番組タイトル
		    if (/<h2 class="title">/) {
				is_title_update = 1
			    current_title_entry = $0
			    gsub(/<[^>]*>/, "", current_title_entry)
			    gsub(/^[ \t]+|[ \t]+$/, "", current_title_entry)
			    gsub(/\r/, "", current_title_entry)
			    current_title = current_title_entry
			    # print "current_title "current_title
			}

		    # サブタイトル
		    if (/<h3 class="subtitle">/) {
				is_sub_update = 1
			    subtitle_entry = $0
			    gsub(/<[^>]*>/, "", subtitle_entry)
			    gsub(/^[ \t]+|[ \t]+$/, "", subtitle_entry)
			    gsub(/\r/, "", csubtitle_entry)
			    current_sub = subtitle_entry
			    # print "current_sub "current_sub
			}
			if(!current_title) next
			if(!current_sub) next
			if(\
				!is_date_update \
				|| !is_time_update \
				|| !is_title_update \
				|| !is_sub_update \
			) next

			is_date_update = 0
			is_time_update = 0
			is_title_update = 0
			is_sub_update = 0
		    printf("%s\t%s\t%s\t%s\n", dates_str[less_col], current_time, current_title, current_sub)
		}' | sort
}
and_grep(){
	local conArg="${1}"
	echo "${conArg}" \
		| awk '
		function set_grep_color(lineArg, grepWordArgs, color){
		    RESET = "\033[1;0m"
			if(\
				grepWordArgs != ""\
			) {
				lineArg = gensub(grepWordArgs, color "&" RESET, "g", lineArg)
			}
			return lineArg
		}
		BEGIN {
			GREEN = "\033[1;32m"
			RED    = "\033[1;31m"   # 赤
		    BLUE   = "\033[1;34m"   # 青
		    BROWN  = "\033[1;33m"   # 茶色（黄色）
		    BOLD_CYAN   = "\033[1;36m" # 太字の青緑
		    BOLD_PURPLE = "\033[1;35m" # 太字の紫
		}
		{
			if(\
				"'${grepWords1}'" == ""\
				&& "'${grepWords2}'" == ""\
				&& "'${grepWords3}'" == ""\
				&& "'${grepWords4}'" == ""\
				&& "'${grepWords5}'" == ""\
				&& "'${grepWords6}'" == ""\
			) {
				print $0
				next
			}
			if(\
				$0 !~ "'${grepWords1}'"\
				&& "'${grepWords1}'" != ""\
			) {
				next
			}
			if(\
				$0 !~ "'${grepWords2}'"\
				&& "'${grepWords2}'" != ""\
			) {
				next
			}
			if(\
				$0 !~ "'${grepWords3}'"\
				&& "'${grepWords3}'" != ""\
			) {
				next
			}
			if(\
				$0 !~ "'${grepWords4}'"\
				&& "'${grepWords4}'" != ""\
			) {
				next
			}
			if(\
				$0 !~ "'${grepWords5}'"\
				&& "'${grepWords5}'" != ""\
			) {
				next
			}
			if(\
				$0 !~ "'${grepWords6}'"\
				&& "'${grepWords6}'" != ""\
			) {
				next
			}
			$0 = set_grep_color($0, "'${grepWords1}'", GREEN)
			$0 = set_grep_color($0, "'${grepWords2}'", BLUE)
			$0 = set_grep_color($0, "'${grepWords3}'", RED)
			$0 = set_grep_color($0, "'${grepWords4}'", BROWN)
			$0 = set_grep_color($0, "'${grepWords5}'", BOLD_CYAN)
			$0 = set_grep_color($0, "'${grepWords6}'", BOLD_PURPLE)
			print $0
		}'
}

or_grep(){
	local conArg="${1}"
	echo "${conArg}" \
		| awk '
		function set_grep_color(lineArg, grepWordArgs, color){
		    RESET = "\033[1;0m"
			if(\
				grepWordArgs != ""\
			) {
				lineArg = gensub(grepWordArgs, color "&" RESET, "g", lineArg)
			}
			return lineArg
		}
		BEGIN {
			GREEN = "\033[1;32m"
			RED    = "\033[1;31m"   # 赤
		    BLUE   = "\033[1;34m"   # 青
		    BROWN  = "\033[1;33m"   # 茶色（黄色）
		    BOLD_CYAN   = "\033[1;36m" # 太字の青緑
		    BOLD_PURPLE = "\033[1;35m" # 太字の紫
		    RESET = "\033[1;0m"
		}
		{
			is_output = 0
			if(\
				"'${grepWords1}'" == ""\
				&& "'${grepWords2}'" == ""\
				&& "'${grepWords3}'" == ""\
				&& "'${grepWords4}'" == ""\
				&& "'${grepWords5}'" == ""\
				&& "'${grepWords6}'" == ""\
			) {
				print $0
				next
			}
			if(\
				$0 ~ "'${grepWords1}'"\
				&& "'${grepWords1}'" != ""\
			) {
				is_output++
			}
			if(\
				$0 ~ "'${grepWords2}'"\
				&& "'${grepWords2}'" != ""\
			) {
				is_output++
			}
			if(\
				$0 ~ "'${grepWords3}'"\
				&& "'${grepWords3}'" != ""\
			) {
				is_output++
			}
			if(\
				$0 ~ "'${grepWords4}'"\
				&& "'${grepWords4}'" != ""\
			) {
				is_output++
			}
			if(\
				$0 ~ "'${grepWords5}'"\
				&& "'${grepWords5}'" != ""\
			) {
				is_output++
			}
			if(\
				$0 ~ "'${grepWords6}'"\
				&& "'${grepWords6}'" != ""\
			) {
				is_output++
			}
			if(!is_output) next
			$0 = set_grep_color($0, "'${grepWords1}'", GREEN)
			$0 = set_grep_color($0, "'${grepWords2}'", BLUE)
			$0 = set_grep_color($0, "'${grepWords3}'", RED)
			$0 = set_grep_color($0, "'${grepWords4}'", BROWN)
			$0 = set_grep_color($0, "'${grepWords5}'", BOLD_CYAN)
			$0 = set_grep_color($0, "'${grepWords6}'", BOLD_PURPLE)
			print $0
		}'
}
concat_con(){
	local baseArg="${1}"
	local conArg="${2}"
	case "${baseArg}" in
		"")
			echo "${conArg}"
			return
		;;
	esac
	cat \
		<(echo "${baseArg}")\
		<(echo "${conArg}")

}
OUTPUT_CON=""
for url in "${programUrl1}" \
			"${programUrl2}" \
			"${programUrl3}" \
			"${programUrl4}"
do
	case "${url}" in
		"") continue;;
	esac
	con=$(\
		output_program \
			"${url}"\
	)
	case "${grepMode}" in
		"OFF")
			OUTPUT_CON=$(\
				concat_con \
					"${OUTPUT_CON}"\
					"$(echo "${con}")"\
			)
			;;
		"AND")
			OUTPUT_CON=$(\
				concat_con \
					"${OUTPUT_CON}"\
					"$(and_grep "${con}")"\
			)
			;;
		"OR")
			OUTPUT_CON=$(\
				concat_con \
					"${OUTPUT_CON}"\
					"$(or_grep "${con}")"\
			)
			continue
			;;
	esac
done

echo "${OUTPUT_CON}" \
	| ignore_word \
	| less -XR
# echo ${ignoreLine}
# case "${ignoreLine}" in
# 	0|"")
# 		echo "${OUTPUT_CON}" \
# 		| ignore_word \
# 		 | less -XR
# 		;;
# 	*) echo "${OUTPUT_CON}" \
# 		| ignore_word \
# 		# | tail  -n +${ignoreLine}\
# 		| less -XR
# 		;;
# esac

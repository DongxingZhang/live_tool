#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 颜色选择
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
font="\033[0m"
# 定义推流地址和推流码
#rtmp="rtmp://www.tomandjerry.work/live/livestream"
#rtmp="rtmp://127.0.0.1:1935/live/1"
rtmp="rtmp://live-push.bilivideo.com/live-bvc/?streamname=live_97540856_1852534&key=a042d1eb6f69ca88b16f4fb9bf9a5435&schedule=rtmp&pflag=1"


# 配置水印文件
curdir=`pwd`
playlist="${curdir}/list/playlist.m3u"
playlist_done="${curdir}/list/playlist_done.m3u"

restlist="${curdir}/list/rest.m3u"
waitingvc="${curdir}/count/videono"

news=${curdir}/log/news.txt
logo=${curdir}/logo/logo.png

fontdir=${curdir}/fonts/STFANGSO.TTF
fontsize=70
fontcolor=#FDE6E0
fontbg="box=1:boxcolor=black@0.3:boxborderw=3"

logging="repeat+level+warning"
preset_decode_speed="ultrafast"

enter=`echo -e "\n''"`
split=`echo -e "\t''"`

#休息时间
rest_start=23
rest_end=6

get_rest(){
    hours=$(TZ=Asia/Shanghai date +%H)
    #测试是否为休息时间
    if [ ${hours} -ge ${rest_start} ] && [ ${hours} -le ${rest_end} ];then
        echo rest
    else
        if [ ${rest_start} -gt ${rest_end} ];then
            if [ ${hours} -ge ${rest_start} ] || [ ${hours} -le ${rest_end} ];then
                echo rest
            else
                echo playing
            fi
        else  
            echo playing
        fi
    fi
}

get_rest_videos_real(){
    waitingdir=$1
    videonofile=$2
    mode=$3
    videono=0
    declare -a filenamelist
    for line in `cat ${waitingdir}`
    do
        line=`echo ${line} | tr -d '\r'`
        line=`echo ${line} | tr -d '\n'`

        arr=(${line//|/ }) 
        video_type=${arr[0]} 
        lighter=${arr[1]} 
        audio=${arr[2]}
        subtitle=${arr[3]}
        param=${arr[4]}
        videopath=${arr[5]}

        for subdirfile in ${videopath}/*; do
            filename=`echo ${subdirfile} | awk -F "/" '{print $NF}'`
            filenamelist[$videono]=${videopath}/${filename}
            videono=$(expr $videono + 1)   
        done
    done	
    video_lengh=${#filenamelist[@]}
    touch ${videonofile}
    next_video=`cat ${videonofile}`

    if [ "${next_video}" =  "" ]; then
        next_video=0
    fi
    if [ ${next_video} -ge ${video_lengh} ]; then
        next_video=0
    fi
    if [ "${mode}" != "test" ];then 
       next_next_video=$(expr $next_video + 1)
       echo "${next_next_video}" > ${videonofile}
    fi
    echo "${video_type}|${lighter}|${audio}|${subtitle}|${param}|${filenamelist[$next_video]}||"
}

get_rest_video(){
    mode=$1
    get_rest_videos_real ${restlist} ${waitingvc} ${mode}
}


echo "推流地址和推流码:${rtmp}"
echo "水印文件:${image}"
echo "播放列表:${playlist}"
echo "已播放列表:${playlist_done}"

ffmpeg_install(){
    # 安装FFMPEG
    read -p "你的机器内是否已经安装过FFmpeg4.x?安装FFmpeg才能正常推流,是否现在安装FFmpeg?(yes/no):" Choose
    if [ $Choose = "yes" ];then
        apt-get install wget
        wget --no-check-certificate https://www.johnvansickle.com/ffmpeg/old-releases/ffmpeg-4.0.3-64bit-static.tar.xz
        tar -xJf ffmpeg-4.0.3-64bit-static.tar.xz
        cd ffmpeg-4.0.3-64bit-static
        mv ffmpeg /usr/bin && mv ffprobe /usr/bin && mv qt-faststart /usr/bin && mv ffmpeg-10bit /usr/bin
    fi
    if [ $Choose = "no" ]
    then
        echo -e "${yellow} 你选择不安装FFmpeg,请确定你的机器内已经自行安装过FFmpeg,否则程序无法正常工作! ${font}"
        sleep 2
    fi
}

get_stream_track(){
    track=`ffprobe -loglevel repeat+level+warning  -i "$1" -show_streams -print_format csv | awk -F, '{print $1,$2,$3,$6}' | grep "$2" | awk 'NR==1{print $2}'`
    echo ${track}
}

get_stream_track_decode(){
    track=`ffprobe -loglevel repeat+level+warning  -i "$1" -show_streams -print_format csv | awk -F, '{print $1,$2,$3,$6}' | grep "$2" | awk 'NR==1{print $3}'`
    echo ${track}
}

get_duration(){
    duration=`ffprobe -loglevel repeat+level+warning  -i "$1" -show_entries format=duration -v quiet -of csv="p=0"`
    echo ${duration}
}

get_duration2(){
    data=`ffprobe -hide_banner -show_format -show_streams "$1" 2>&1`
    Duration=`echo $data |awk -F 'Duration: ' '{print $2}' | awk -F ',' '{print $1}' | awk -F '.' '{print $1}' | awk -F ':' '{print $1"\:"$2"\:"$3}'`
    echo ${Duration} 
}

get_fontsize(){
    data=`ffprobe -hide_banner -show_format -show_streams "$1" 2>&1`
    width=`echo $data |  awk -F 'width=' '{print $2}' | awk -F ' ' '{print $1}'`
    height=`echo $data |  awk -F 'height=' '{print $2}' | awk -F ' ' '{print $1}'`
    newfontsize=`echo "scale=5;sqrt($width*$width+$height*$height)/2203*$fontsize" | bc`
    newfontsize=`echo "scale=0;$newfontsize/1" | bc`
    echo $newfontsize
}

digit_half2full(){
    if [ $1 -lt 10 ] && [ $1 -ge 0 ]; then
        res=$(echo $1 | sed 's/0/０/g' | sed 's/1/１/g'  | sed 's/2/２/g'  | sed 's/3/３/g'  | sed 's/4/４/g'  | sed 's/5/５/g'  | sed 's/6/６/g'  | sed 's/7/７/g'  | sed 's/8/８/g' | sed 's/9/９/g')
        echo $res
    else
        echo $1
    fi
}

stream_play_main(){
    line=$1

    line=`echo ${line} | tr -d '\r'`
    line=`echo ${line} | tr -d '\n'`

    arr=(${line//|/ }) 
    video_type=${arr[0]} 
    lighter=${arr[1]} 
    audio=${arr[2]}
    subtitle=${arr[3]}
    param=${arr[4]}
    videopath=${arr[5]}
    cur_file=${arr[6]}
    file_count=${arr[7]}
    play_mode=$2
    mode=$3

    if [[ -d "${videopath}" ]];then
        return 0
    fi

    if [ "${mode}" != "test" ];then
        killall ffmpeg
    fi
   
    # 文件超过5GB不要播放
    maxsize=5000000000
    actualsize=$(wc -c <"$videopath")
    echo 文件大小:$actualsize
    if [ $actualsize -ge $maxsize ]; then
        return 0
    fi

    echo "推送${videopath}"

    video_track=$(get_stream_track "${videopath}" "video")
    video_track_decode=$(get_stream_track "${videopath}" "video")
    audio_track=$(get_stream_track "${videopath}" "audio")
    audio_track_decode=$(get_stream_track "${videopath}" "audio")
    sub_track=$(get_stream_track "${videopath}" "subtitle")
    sub_track_decode=$(get_stream_track "${videopath}" "subtitle")
    
    if [ "$video_track" = "" ];then
        echo "${videopath} 没有视频轨道"
        echo "${videopath}" >> "${playlist_done}"
        return 
    fi
    
    if [ "$audio_track" = "" ];then
        echo "${videopath} 没有音频轨道"
        echo "${videopath}" >> "${playlist_done}"
        return 
    fi
    
    maps=
    if [ "$sub_track" != "" ];then
        maps="[0:s:0]"
    fi

    mapv="[0:v:0]"
    mapa="[0:a:0]"

    if [ "${audio}" != "F" ]; then
        mapa="[0:a:${audio}]"
    fi
    
    if [ "${subtitle}" != "F" ]; then
        maps="[0:a:${subtitle}]"
    fi

    echo ${mapv}, ${mapa}, ${maps}

    #读取天气预报
    cat <( curl -s http://www.nmc.cn/publish/forecast/  ) | tr -s '\n' ' ' |  sed  's/<div class="col-xs-4">/\n/g' | sed -E 's/<[^>]+>//g' | awk -F ' ' 'NF==5{print $1,$2,$3}' | head -n 32 | tr -s '\n' ';' | sed 's/徐家汇/上海/g' | sed 's/长沙市/长沙/g' >  ${news}
    strline=$(cat ${news})

    echo $strline   

    echo video_type=${video_type}   
    #去掉logo
    if [ "${video_type}" = "YOU" ];then
        delogo="delogo=x=795:y=25:w=160:h=35:show=0,"
    elif [ "${video_type}" = "TV0" ];then
        delogo="delogo=x=965:y=40:w=75:h=60:show=0,"
    elif [ "${video_type}" = "TV1" ];then
        delogo="delogo=x=400:y=30:w=75:h=60:show=0,"
    elif [ "${video_type}" = "TV2" ];then
        delogo="delogo=x=525:y=30:w=85:h=60:show=0,"
    elif [ "${video_type}" = "TV3" ];then
        delogo="delogo=x=795:y=30:w=75:h=60:show=0,"
    elif [ "${video_type}" = "CCV" ];then
        delogo="delogo=x=80:y=50:w=155:h=120:show=0,"
    elif [ "${video_type}" = "CC2" ];then
        delogo="delogo=x=50:y=45:w=120:h=60:show=0,"
    elif [ "${video_type}" = "TR0" ];then
        delogo="delogo=x=5:y=5:w=1270:h=40:show=0,delogo=x=1050:y=610:w=200:h=100:show=0,delogo=x=250:y=580:w=750:h=120:show=0,"
    elif [ "${video_type}" = "CC1" ];then #去掉CCTV6的标题
        delogo="scale=w=1080:h=-1,delogo=x=945:y=40:w=75:h=60:show=0,delogo=x=945:y=500:w=75:h=60:show=0,delogo=x=60:y=40:w=200:h=80:show=0,delogo=x=20:y=490:w=400:h=100:show=0,delogo=x=945:y=340:w=75:h=100:show=0,"
    elif [ "${video_type}" = "AT0" ];then
        delogo="delogo=x=560:y=5:w=64:h=68:show=0,delogo=x=560:y=490:w=140:h=45:show=0,"
    elif [ "${video_type}" = "TWV" ];then
        delogo="delogo=x=1042:y=58:w=190:h=86:show=0,delogo=x=94:y=38:w=248:h=60:show=0,"
    else
        delogo=""
    fi

    if [ "${lighter}" != "F" ];then
        video_format="${mapv}${delogo}eq=contrast=1:brightness=0.2,curves=preset=lighter"
    else
        video_format="${mapv}${delogo}eq=contrast=1"
    fi

    #计算真正字体大小
    newfontsize=$(get_fontsize ${videopath})
    echo newfontsize=${newfontsize}
    #计算时间字体大小
    halfnewfontsize=$(expr ${newfontsize} \* 82 / 100)

    #显示时长
    duration=$(get_duration2 "${videopath}")
    content="%{pts\:gmtime\:0\:%H\\\\\:%M\\\\\:%S}${enter}${duration}"
    drawtext1="drawtext=fontsize=${halfnewfontsize}:fontcolor=${fontcolor}:text='${content}':fontfile=${fontdir}:expansion=normal:x=w-line_h\*5-15:y=line_h\*2:shadowx=2:shadowy=2:${fontbg}"
    
    #天气预报
    #从左往右drawtext2="drawtext=fontsize=${newfontsize}:fontcolor=${fontcolor}:text='${news}':fontfile=${fontdir}:expansion=normal:x=(mod(5*n\,w+tw)-tw):y=h-line_h-10:shadowx=2:shadowy=2:${fontbg}"
    #从右到左
    drawtext2="drawtext=fontsize=${newfontsize}:fontcolor=${fontcolor}:text='${strline}':fontfile=${fontdir}:expansion=normal:x=w-mod(max(t-1\,0)*(w+tw)/215\,(w+tw)):y=h-line_h-5:shadowx=2:shadowy=2:${fontbg}"
    
    echo ${cur_file}
    echo ${file_count}

    if [ "${file_count}" = "" ]; then
        rest_start2=$(digit_half2full ${rest_start})
        res_end2=$(expr $rest_end + 1)
        res_end2=$(digit_half2full ${res_end2})
        content2="${rest_start2}${enter}点${enter}到${enter}${res_end2}${enter}点${enter}休${enter}息${enter}"
    else
        cur_file2=$(digit_half2full ${cur_file})
        file_count2=$(digit_half2full ${file_count})
        content2="第${enter}${cur_file2}${enter}集${enter}${enter}共${enter}${file_count2}${enter}集"
    fi
    drawtext3="drawtext=fontsize=${newfontsize}:fontcolor=${fontcolor}:text='${content2}':fontfile=${fontdir}:expansion=normal:x=line_h\*2:y=h/2-line_h\*3:shadowx=2:shadowy=2:${fontbg}"
        
    watermark="[1:v]scale=-1:${newfontsize}\*2[wm];[bg][wm]overlay=30:overlay_h/3[bg1]"
    video_format="${video_format},${drawtext1},${drawtext2},${drawtext3}[bg];${mapa}volume=1.0[bga];${watermark};"

    echo ${video_format}

    date1=$(date +"%Y-%m-%d %H:%M:%S")     

    if [ "${maps}" = "" ]; then
      echo ffmpeg -loglevel "${logging}"  -re -i "$videopath" -i "${logo}" -preset ${preset_decode_speed} -filter_complex "${video_format}" -map "[bg1]" -map "[bga]" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv ${rtmp}
      if [ "${mode}" != "test" ];then
          ffmpeg -loglevel "${logging}" -re -i "$videopath" -i "${logo}"  -preset ${preset_decode_speed} -filter_complex "${video_format}" -map "[bg1]" -map "[bga]" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv -y ${rtmp}
      fi
    else
      video_format="${video_format};${maps}overlay[bgs]"
      echo ffmpeg -loglevel "${logging}" -re -i "$videopath" -i "${logo}"  -preset ${preset_decode_speed} -filter_complex "${video_format}" -map "[bg1]" -map "[bga]" -map "[bgs]" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv ${rtmp}
      if [ "${mode}" != "test" ];then
          ffmpeg -loglevel "${logging}" -re -i "$videopath" -i "${logo}"  -preset ${preset_decode_speed} -filter_complex "${video_format}" -map "[bg1]" -map "[bga]" -map "[bgs]" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv -y ${rtmp}
      fi
    fi

    date2=$(date +"%Y-%m-%d %H:%M:%S")

    sys_date1=$(date -d "$date1" +%s)
    sys_date2=$(date -d "$date2" +%s)
    time_seconds=`expr $sys_date2 - $sys_date1`

    if [ "${mode}" != "test" ] && [ ${time_seconds} -ge 700 ] && [ "${file_count}" != "" ]; then
        echo "$videopath" >> "${playlist_done}"
    fi
   
}


get_playing_video(){
    mode=$1
    for line in $(cat ${playlist})
    do    
        line=`echo ${line} | tr -d '\r'`
        line=`echo ${line} | tr -d '\n'`     
        # 判断是否要跳过   
        flag=${line:0:1}
        if [ "${flag}" = "#" ];then
            continue 
        fi       
        arr=(${line//|/ }) 
        video_type=${arr[0]} 
        lighter=${arr[1]} 
        audio=${arr[2]}
        subtitle=${arr[3]}
        param=${arr[4]}
        videopath=${arr[5]}

        if [[ -d "${videopath}" ]];then
            found=0
            cur_file=0
            file_count=`ls -l ${videopath}  |grep "^-"|wc -l`
            for subdirfile in "${videopath}"/*; do           
                cur_file=$(expr $cur_file + 1)
                if [[ -e "${playlist_done}" ]] && cat "${playlist_done}" | grep "$subdirfile" > /dev/null; then
                    continue
                fi
                found=1
      	        echo "${video_type}|${lighter}|${audio}|${subtitle}|${param}|${subdirfile}|${cur_file}|${file_count}"
	            break
            done
            if [[ "${found}" = "1" ]];then
                break
	        fi
        elif [[ -f "${videopath}" ]] ; then
            echo "${video_type}|${lighter}|${audio}|${subtitle}|${param}|${videopath}|1|1"
	        break
        fi
    done
}


get_play_next(){
    mode=$1
    if [ "$(get_rest)" = "rest" ]; then
        next_video_path=$(get_rest_video ${mode})
    else
        next_video_path=$(get_playing_video ${mode})
    fi    
    echo ${next_video_path}
}


stream_start(){    
    play_mode=$1
    mode=$2

    if [[ $rtmp =~ "rtmp://" ]];then
        echo -e "${green} 推流地址输入正确,程序将进行下一步操作. ${font}"
    else  
        echo -e "${red} 你输入的地址不合法,请重新运行程序并输入! ${font}"
        exit 1
    fi 

    while true
    do
        next=$(get_play_next ${mode})
        stream_play_main "${next}" "${play_mode}" "${mode}"  
        sleep 1
    done
}

stream_append(){
    param=$1
    while true
    do
        clear
        echo "====视频列表===="
        videono=0
        for subdirfile in $(find /mnt/smb/电视剧 -maxdepth 1 -type d | grep "${param}"  | awk -F ':' '{print $1}')
        do
            filename=`echo ${subdirfile} | awk -F "/" '{print $NF}'`
            filenamelist[$videono]=${filename}
            videono=$(expr $videono + 1)
            echo "[${videono}]: ${filename}"
        done
        read -p "请输入视频序号:(1-${videono}),:" vindex
        if [ $vindex -ge 1 ] && [ $vindex -le ${videono}  ]; then
            vindex=$(expr $vindex - 1)
            echo '你选择了:'${filenamelist[$vindex]}
            read -p "输入(yes/no/y/n)确认:" yes
            if [ "$yes" = "y" ] || [ "$yes" = "yes" ]; then
                # 已经存在不要添加
                if [[ -e "${playlist}" ]] && cat "${playlist}" | grep "${filenamelist[$vindex]}" > /dev/null; then
                    echo "已经添加过/mnt/smb/电视剧/${filenamelist[$vindex]},不要再添加."
                else
                    echo "000|0|9|9|0|/mnt/smb/电视剧/${filenamelist[$vindex]}" >> ${playlist}
                    echo "添加/mnt/smb/电视剧/${filenamelist[$vindex]}成功"  
                fi                
            fi
            read -p "还要继续添加吗(yes/no/y/n)?:" yes_addagain
            if [ "$yes_addagain" = "n" ] || [ "$yes_addagain" = "no" ]; then
                break
            fi
        elif [ "$vindex" = "q"  ]; then
            break
        fi
    done
    cat ${playlist}
}

# 停止推流
stream_stop(){
    killall ffmpeg
}


# 开始菜单设置
echo -e "${yellow} FFmpeg无人值守直播工具(version 1.1) ${font}"
echo -e "${green} 1.安装FFmpeg (机器要安装FFmpeg才能正常推流) ${font}"
echo -e "${green} 2.开始无人值守循环推流 ${font}"
echo -e "${green} 3.开始播放的单个目录 ${font}"
echo -e "${green} 4.增加视频目录 ${font}"
echo -e "${green} 5.停止推流 ${font}"
start_menu(){
    echo $1
    echo $2
    echo $3

    if [ "$1" = "" ]; then
        read -p "请输入数字(1-3),选择你要进行的操作:" num
        if [ "$num" = "2" ]; then
            read -p "请输入播放模式(seq, random):" param
        elif [ "$num" = "3" ]; then
            read -p "请输入视频目录:" param
        fi
    else
        num=$1
        param=$2
        mode=$3
    fi
    case "$num" in
        1)
        ffmpeg_install
        ;;
        2)
        stream_start "${param}" "${mode}"
        ;;
        3)
        stream_play_main "000|0|9|9|0|${param}"
        ;;
        4)
        stream_append "${param}"
        ;;
        5)
        stream_stop
        ;;
        *)
        echo -e "${red} 请输入正确的数字 (1-4) ${font}"
        ;;
    esac
	}

# 运行开始菜单
start_menu $1 $2 $3


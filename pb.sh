#!/bin/bash

# 颜色选择
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
font="\033[0m"

# 定义推流地址和推流码
#rtmp="rtmp://www.tomandjerry.work/live/livestream"
#rtmp="rtmp://127.0.0.1:1935/live/1"
rtmp="rtmp://live-push.bilivideo.com/live-bvc/?streamname=live_97540856_1852534&key=a042d1eb6f69ca88b16f4fb9bf9a5435&schedule=rtmp&pflag=1"


# 配置目录和文件
curdir=`pwd`

logodir=${curdir}/logo

news=${curdir}/log/news.txt

subfile=${curdir}/sub/sub.srt

#配置字体
fontdir=${curdir}/fonts/STFANGSO.TTF
fontsize=70
fontcolor=#FDE6E0
fontbg="box=1:boxcolor=black@0.3:boxborderw=3"

#ffmpeg参数
logging="repeat+level+warning"
preset_decode_speed="ultrafast"

enter=`echo -e "\n''"`
split=`echo -e "\t''"`


if [ ! -d ${curdir}/log ];then
    echo create ${curdir}/log
    mkdir ${curdir}/log
fi

if [ ! -d ${curdir}/sub ];then
    echo create ${curdir}/sub
    mkdir ${curdir}/sub
fi


####功能函数START
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
    echo ${newfontsize}
}

get_size(){
    data=`ffprobe -hide_banner -show_format -show_streams "$1" 2>&1`
    width=`echo $data |  awk -F 'width=' '{print $2}' | awk -F ' ' '{print $1}'`
    height=`echo $data |  awk -F 'height=' '{print $2}' | awk -F ' ' '{print $1}'`
    echo "${width}|${height}"
}


digit_half2full(){
    if [ $1 -lt 10 ] && [ $1 -ge 0 ]; then
        res=$(echo $1 | sed 's/0/０/g' | sed 's/1/１/g'  | sed 's/2/２/g'  | sed 's/3/３/g'  | sed 's/4/４/g'  | sed 's/5/５/g'  | sed 's/6/６/g'  | sed 's/7/７/g'  | sed 's/8/８/g' | sed 's/9/９/g')
        echo $res
    else
        echo $1
    fi
}
####功能函数END

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
    play_time=${arr[8]}
    playlist_done=${arr[9]}
    videoname=${arr[10]}
    mode=$2

    echo -e ${yellow}视频类别（delogo）:${font} ${video_type}
    echo -e ${yellow}是否明亮（F为维持原亮度）:${font} ${lighter}
    echo -e ${yellow}音轨（F为不选择）:${font} ${audio}
    echo -e ${yellow}字幕轨（F为不选择）:${font} ${subtitle}
    echo -e ${yellow}LOGO（F武侠logo）:${font} ${param}
    echo -e ${yellow}视频路径:${font} ${videopath}
    echo -e ${yellow}当前集数:${font} ${cur_file}
    echo -e ${yellow}总集数:${font} ${file_count}
    echo -e ${yellow}播放标记:${font} ${play_time}
    echo -e ${yellow}已播放:${font} ${playlist_done}
    echo -e ${yellow}电视剧名称:${font} ${videoname}
    echo -e ${yellow}播放模式（bg, fg, test）:${font} ${mode}


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
        maps="0:s:0"
    fi

    mapv="[0:v:0]"
    mapa="[0:a:0]"

    if [ "${audio}" != "F" ]; then
        mapa="[0:a:${audio}]"
    fi
    
    if [ "${subtitle}" != "F" ]; then
        maps="0:s:${subtitle}"
    fi

    echo ${mapv}, ${mapa}, ${maps}

    #读取天气预报
    cat <( curl -s http://www.nmc.cn/publish/forecast/  ) | tr -s '\n' ' ' |  sed  's/<div class="col-xs-4">/\n/g' | sed -E 's/<[^>]+>//g' | awk -F ' ' 'NF==5{print $1,$2,$3}' | head -n 32 | tr -s '\n' ';' | sed 's/徐家汇/上海/g' | sed 's/长沙市/长沙/g' >  ${news}

    #logo
    if [ "${param}" != "F" ]; then
        #怀旧logo
        logo=${logodir}/logo2.png
    else
        #武侠logo
        logo=${logodir}/logo.png
    fi

    echo logo=${logo} 

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
    elif [ "${video_type}" = "TV4" ];then
        delogo="delogo=x=1100:y=30:w=120:h=55:show=0,"
    elif [ "${video_type}" = "TV5" ];then
        delogo="delogo=x=582:y=26:w=74:h=52:show=0,"
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

    if [ "${maps}" != "" ];then  
        echo ffmpeg -i ${videopath} -map ${maps} -y ${subfile}      
        ffmpeg -i ${videopath} -map ${maps} -y ${subfile}        
        cat ${subfile} | sed -E 's/<[^>]+>//g' > ./sub/tmp
        mv ./sub/tmp ${subfile}
        mapv="${mapv}subtitles=filename=${subfile}:fontsdir=${curdir}/fonts:force_style='Fontname=华文仿宋,Fontsize=18,Alignment=0,MarginV=50'[v];[v]"
    fi

    if [ "${lighter}" != "F" ];then
        video_format="${mapv}${delogo}eq=contrast=1:brightness=0.2,curves=preset=lighter"
    else
        video_format="${mapv}${delogo}eq=contrast=1"
    fi

    #分辨率
    ssize=$(get_size ${videopath})
    sizearr=(${ssize//|/ })
    size_width=${sizearr[0]}
    size_height=${sizearr[1]}
    echo size_width=$size_width

    #计算真正字体大小
    newfontsize=$(get_fontsize ${videopath})
    echo newfontsize=${newfontsize}
    #计算时间字体大小
    halfnewfontsize=$(expr ${newfontsize} \* 75 / 100)

    #显示时长
    #播放百分比%{eif\:n\/nb_frames\:d}%%
    duration=$(get_duration2 "${videopath}")
    content="%{pts\:gmtime\:0\:%H\\\\\:%M\\\\\:%S}${enter}${duration}"
    drawtext1="drawtext=fontsize=${halfnewfontsize}:fontcolor=${fontcolor}:text='${content}':fontfile=${fontdir}:expansion=normal:x=w-line_h\*8:y=line_h\*3:shadowx=2:shadowy=2:${fontbg}"
    
    #天气预报
    #从左往右drawtext2="drawtext=fontsize=${newfontsize}:fontcolor=${fontcolor}:text='${news}':fontfile=${fontdir}:expansion=normal:x=(mod(5*n\,w+tw)-tw):y=h-line_h-10:shadowx=2:shadowy=2:${fontbg}"
    #从右到左
    crop_width=$(expr ${size_width} / 4)
    crop_x=$(expr ${size_width} \* 3 / 4)
    drawtext2="drawtext=fontsize=${halfnewfontsize}:fontcolor=${fontcolor}:textfile='${news}':fontfile=${fontdir}:expansion=normal:x=w-mod(max(t-1\,0)*(w+tw\*3)/415\,(w+tw\*3)):y=5:shadowx=2:shadowy=2:${fontbg}"
    
    echo ${cur_file}
    echo ${file_count}
    
    if [ "${file_count}" = "1" ]; then
        content2=
    else
        cur_file2=$(digit_half2full ${cur_file})
        content2=`echo ${videoname} | sed 's#.#&\'"${enter}"'#g'`${cur_file2}
        echo ${content2}
    fi

#    if [ "${play_time}" = "playing" ]; then
#        cur_file2=$(digit_half2full ${cur_file})
#        file_count2=$(digit_half2full ${file_count})
#        content2="第${enter}${cur_file2}${enter}集${enter}${enter}共${enter}${file_count2}${enter}集"
#    else
#        cur_file2=$(digit_half2full ${cur_file})
#        file_count2=$(digit_half2full ${file_count})
#        content2="第${enter}${cur_file2}${enter}集${enter}${enter}共${enter}${file_count2}${enter}集"
#        #rest_start2=$(digit_half2full ${rest_start})
#        #res_end2=$(expr $rest_end + 1)
#        #res_end2=$(digit_half2full ${res_end2})
#        #content2="${rest_start2}${enter}点${enter}到${enter}${res_end2}${enter}点${enter}休${enter}息${enter}第${enter}${cur_file2}${enter}集"
#    fi
    drawtext3="drawtext=fontsize=${newfontsize}:fontcolor=${fontcolor}:text='${content2}':fontfile=${fontdir}:expansion=normal:x=w-line_h\*3:y=h/2-tw/4:shadowx=2:shadowy=2:${fontbg}"
        
    watermark="[1:v]scale=-1:${newfontsize}\*2[wm];[bg][wm]overlay=overlay_w/3:overlay_h/2[bg1]"
    video_format="${video_format},${drawtext1},${drawtext2},${drawtext3}[bg];${mapa}volume=1.0[bga];${watermark};"

    echo ${video_format}
    echo ${enter}

    date1=$(TZ=Asia/Shanghai date +"%Y-%m-%d %H:%M:%S")

    echo ffmpeg -loglevel "${logging}" -re -i "$videopath" -i "${logo}"  -preset ${preset_decode_speed} -filter_complex "${video_format}" -map "[bg1]" -map "[bga]" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv -y ${rtmp}
    if [ "${mode}" != "test" ];then
        ffmpeg -loglevel "${logging}" -re -i "$videopath" -i "${logo}"  -preset ${preset_decode_speed} -filter_complex "${video_format}" -map "[bg1]" -map "[bga]" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv -y ${rtmp}
    fi

    date2=$(TZ=Asia/Shanghai date +"%Y-%m-%d %H:%M:%S")

    sys_date1=$(date -d "$date1" +%s)
    sys_date2=$(date -d "$date2" +%s)
    time_seconds=`expr $sys_date2 - $sys_date1`

    if [ "${mode}" != "test" ] && [ ${time_seconds} -lt 120 ]; then
        echo "$(TZ=Asia/Shanghai date +"%Y-%m-%d %H:%M:%S") ffmpeg 命令失败！！需要调试" >> "${playlist_done}"
        exit 1
    fi

    echo mode=${mode}
    echo time_seconds=${time_seconds}

    if [ "${mode}" != "test" ] && [ ${time_seconds} -ge 120 ]; then
        echo "$videopath" >> "${playlist_done}"
    fi

}


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


get_rest(){
    hours=$(TZ=Asia/Shanghai date +%H)
    playlistfile="${curdir}/list/playlist.txt|${curdir}/list/playlist_done.m3u"
    #测试是否为休息时间
    if [ ${hours} -ge 0 ] && [ ${hours} -le 5 ];then
        echo "${playlistfile}|0"
    elif [ ${hours} -ge 6 ] && [ ${hours} -le 11 ];then
        echo "${playlistfile}|1"
    elif [ ${hours} -ge 12 ] && [ ${hours} -le 17 ];then
        echo "${playlistfile}|2"
    else
        echo "${playlistfile}|3"
    fi
}


get_playing_video(){
    mode=$1
    playlist=$2
    playlist_done=$3
    playlist_index=$4
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
        video_index=${arr[0]}
        video_type=${arr[1]} 
        lighter=${arr[2]} 
        audio=${arr[3]}
        subtitle=${arr[4]}
        param=${arr[5]}
        videopath=${arr[6]}
        videoname=${arr[7]}

        #搜索时间段 分四个时间段
        #0: 0点-6点  1:6点-12点  2:12点-18点 3:18点-24点
        if [[ "${video_index}" != "${playlist_index}" ]];then
            continue
        fi

        if [[ -d "${videopath}" ]];then            
            found=0
            cur_file=0
            file_count=`ls -l ${videopath}  |grep "^-"|wc -l`
            for subdirfile in "${videopath}"/*; do           
                cur_file=$(expr $cur_file + 1)
                if [[ -e "${playlist_done}" ]] && cat "${playlist_done}" | grep "${subdirfile}" > /dev/null; then
                    continue
                fi
                found=1
                echo "${video_type}|${lighter}|${audio}|${subtitle}|${param}|${subdirfile}|${cur_file}|${file_count}|playing|${playlist_done}|${videoname}"
                break
            done
            if [[ "${found}" = "1" ]];then
                break
            fi
        elif [[ -f "${videopath}" ]] ; then
            if [[ -e "${playlist_done}" ]] && cat "${playlist_done}" | grep "${videopath}" > /dev/null; then
                continue
            fi
            echo "${video_type}|${lighter}|${audio}|${subtitle}|${param}|${videopath}|1|1|playing|${playlist_done}|${videoname}"
            break
        fi
    done
}


get_next(){
    rest=$(get_rest)
    restarr=(${rest//|/ }) 
    playlist=${restarr[0]} 
    playlist_done=${restarr[1]}
    playlist_index=${restarr[2]}
    #echo ${playlist} ${playlist_done} ${playlist_index}
    next_video_path=$(get_playing_video $1 ${playlist} ${playlist_done} ${playlist_index}) 
    echo ${next_video_path}
}


stream_start(){    
    play_mode=$1

    if [[ $rtmp =~ "rtmp://" ]];then
        echo -e "${green} 推流地址输入正确,程序将进行下一步操作. ${font}"
    else  
        echo -e "${red} 你输入的地址不合法,请重新运行程序并输入! ${font}"
        exit 1
    fi 

    echo "推流地址和推流码:${rtmp}"
    echo "播放模式:${play_mode}"

    while true
    do
        next=$(get_next ${play_mode})
        stream_play_main "${next}" "${play_mode}"        
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
        for subdirfile in $(find /mnt/smb/电视剧 -maxdepth 1 | grep "${param}"  | awk -F ':' '{print $1}')
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
                    echo 0:0点到6点
                    echo 1:6点到12点
                    echo 2:12点到18点
                    echo 3:18点到24点
                    read -p "请输入视频序号:(0-3),:" timed
                    if [ $timed -lt 0 ] || [ $timed -gt 3  ]; then
                        continue
                    fi
                    echo 你选择了：$timed
                    echo "${timed}|000|F|F|F|0|/mnt/smb/电视剧/${filenamelist[$vindex]}|${filenamelist[$vindex]}" >> ${playlist}
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


# 开始菜单设置
echo -e "${yellow} FFmpeg无人值守直播工具(version 1.1) ${font}"
echo -e "${green} 1.安装FFmpeg (机器要安装FFmpeg才能正常推流) ${font}"
echo -e "${green} 2.开始无人值守循环推流 ${font}"
echo -e "${green} 3.开始播放的单个目录 ${font}"
echo -e "${green} 4.增加视频目录 ${font}"
echo -e "${green} 5.停止推流 ${font}"
start_menu(){

    if [ "$1" = ""  ]; then
        read -p "请输入选项:" num
        read -p "请输入模式:" mode
    else
        num=$1
        mode=$2       
    fi

    case "$num" in
        1)
        ffmpeg_install
        ;;
        2)
        stream_start "${mode}"
        ;;
        3)
        stream_append "${mode}"
        ;;
        4)
        stream_stop
        ;;
        *)
        echo -e "${red} 请输入正确的数字 (1-4) ${font}"
        ;;
    esac
	}

# 运行开始菜单
start_menu $1 $2


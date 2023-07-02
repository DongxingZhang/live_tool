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
image=
curdir=`pwd`
playlist=${curdir}/playlist.m3u
playlist_done=${curdir}/playlist_done.m3u
waiting=/mnt/smb/videos
fontdir=${curdir}/FZYTK.TTF
fontsize=50

#休息时间
rest_start=0
rest_end=5

#videos下一个视频
get_videos(){
    videono=0
    declare -a filenamelist
    for subdirfile in ${waiting}/*; do
        filename=`echo ${subdirfile} | awk -F "/" '{print $NF}'`
        filenamelist[$videono]=${filename}
        videono=$(expr $videono + 1)   
    done
    video_lengh=${#filenamelist[@]}
    touch ./myvideono
    next_video=`cat ./myvideono`

    if [ "${next_video}" =  "" ]; then
        next_video=0
    fi
    if [ ${next_video} -ge ${video_lengh} ]; then
        next_video=0
    fi
    next_next_video=$(expr $next_video + 1)
    echo "${next_next_video}" > ./myvideono
    echo "${waiting}/${filenamelist[$next_video]}"
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

get_rest(){
    hours=$(TZ=Asia/Shanghai date +%H)
    #测试是否为休息时间
    if [ ${hours} -ge ${rest_start} ] && [ ${hours} -le ${rest_end} ];then
        echo rest
    else    
        echo playing
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


stream_play(){
    file=$1
    video_type=$2
    audio=$3
    subtitle=$4
    file_count=$5
    cur_file=$6
    mode=$7

    if [[ -d "${file}" ]];then
        return
    fi

    echo "$mode"	
    if [ "${mode}" != "test" ];then
        killall ffmpeg
    fi
   
    # 文件超过50GB不要播放
    maxsize=50000000000
    actualsize=$(wc -c <"$file")
    echo $actualsize
    if [ $actualsize -ge $maxsize ]; then
        return 0
    fi
    
    # 已经播放过的不要播放
    if [[ -e "${playlist_done}" ]] && cat "${playlist_done}" | grep "$file" > /dev/null; then
        echo "已经播放过视频${file}"
        return
    fi
   
    echo "推送${file}"
    logging="repeat+level+warning"
    preset_decode_speed="ultrafast"
    video_format="eq=contrast=1:brightness=0.2,curves=preset=lighter"
    #去掉logo
    if [ "$video_type" = "YOUK" ];then
        video_format="delogo=x=795:y=25:w=160:h=35:show=0,eq=contrast=1:brightness=0.15,curves=preset=lighter"
    elif [ "$video_type" = "TVB0" ];then
        video_format="delogo=x=965:y=40:w=75:h=60:show=0,eq=contrast=1:brightness=0.15,curves=preset=lighter"
    elif [ "$video_type" = "TVB1" ];then
        video_format="delogo=x=400:y=30:w=75:h=60:show=0,eq=contrast=1:brightness=0.15,curves=preset=lighter"
    elif [ "$video_type" = "TVB2" ];then
        video_format="delogo=x=525:y=30:w=85:h=60:show=0,eq=contrast=1:brightness=0.15,curves=preset=lighter"
    elif [ "$video_type" = "TVB3" ];then
        video_format="delogo=x=795:y=30:w=75:h=60:show=0,eq=contrast=1:brightness=0.15,curves=preset=lighter"
    elif [ "$video_type" = "CCTV" ];then
        video_format="delogo=x=80:y=50:w=155:h=120:show=0,eq=contrast=1:brightness=0.15,curves=preset=lighter"
    elif [ "$video_type" = "CCT2" ];then
        video_format="delogo=x=50:y=45:w=120:h=60:show=0,eq=contrast=1:brightness=0.15,curves=preset=lighter"
    elif [ "$video_type" = "TRB0" ];then
        video_format="delogo=x=5:y=5:w=1270:h=40:show=0,delogo=x=1050:y=610:w=200:h=100:show=0,delogo=x=250:y=580:w=750:h=120:show=0,eq=contrast=1:brightness=0.15,curves=preset=lighter"
    elif [ "$video_type" = "CCT1" ];then #去掉CCTV6的标题
        video_format="scale=w=1080:h=-1,delogo=x=945:y=40:w=75:h=60:show=0,delogo=x=945:y=500:w=75:h=60:show=0,delogo=x=60:y=40:w=200:h=80:show=0,delogo=x=20:y=490:w=400:h=100:show=0,delogo=x=945:y=340:w=75:h=100:show=0,eq=contrast=1:brightness=0.15,curves=preset=lighter"
    elif [ "$video_type" = "ATV0" ];then
        video_format="delogo=x=560:y=5:w=64:h=68:show=0,delogo=x=560:y=490:w=140:h=45:show=0,eq=contrast=1:brightness=0.15,curves=preset=lighter"
    elif [ "$video_type" = "TWTV" ];then
        video_format="delogo=x=1042:y=58:w=190:h=86:show=0,delogo=x=94:y=38:w=248:h=60:show=0,eq=contrast=1:brightness=0.15,curves=preset=lighter"
    else
        video_format="eq=contrast=1:brightness=0.15,curves=preset=lighter"
    fi
    
    # 叠加字体
    #cat <( curl -s https://top.baidu.com/board?tab=realtime  ) | sed  's/\"desc\"\:\"/\n/g' | awk -F '\"\,\"hotChange\"' 'NF==2{print $1}' | sed 's/[[:space:]]//g' > ./news.txt
    duration=$(get_duration2 "${file}")
    enter=`echo -e "\n''"`
    content="第${cur_file}集/共${file_count}集${enter}时长\:${duration}${enter}播放\:%{pts\:gmtime\:0\:%H\\\\\:%M\\\\\:%S}"
    drawtext="drawtext=fontsize=${fontsize}:fontcolor=red:text='${content}':fontfile=${fontdir}:expansion=normal:x=5:y=5:shadowx=2:shadowy=2"
    strline=$(cat ${curdir}/news.txt)
    #从左往右drawtext2="drawtext=fontsize=${fontsize}:fontcolor=red:text='${news}':fontfile=${fontdir}:expansion=normal:x=(mod(5*n\,w+tw)-tw):y=h-line_h-10:shadowx=2:shadowy=2"
    drawtext2="drawtext=fontsize=${fontsize}:fontcolor=red:text='${strline}':fontfile=${fontdir}:expansion=normal:x=w-tw-w/10*mod(t\,25):y=h-line_h-10:shadowx=2:shadowy=2"
    video_format="${video_format},${drawtext},${drawtext2}"
    
    video_track=$(get_stream_track "${file}" "video")
    video_track_decode=$(get_stream_track "${file}" "video")
    audio_track=$(get_stream_track "${file}" "audio")
    audio_track_decode=$(get_stream_track "${file}" "audio")
    sub_track=$(get_stream_track "${file}" "subtitle")
    sub_track_decode=$(get_stream_track "${file}" "subtitle")
    
    if [ "$video_track" = "" ];then
        echo "${file} 没有视频轨道"
        echo "$file" >> "${playlist_done}"
        return 
    fi
    
    if [ "$audio_track" = "" ];then
        echo "${file} 没有音频轨道"
        echo "$file" >> "${playlist_done}"
        return 
    fi
    
    mapv="0:${video_track}"
    mapa="0:${audio_track}"
    if [ "$sub_track" != "" ];then
        maps="0:${sub_track}"
    fi
    if [ "${audio}" != "9" ]; then
        mapa="0:${audio}"
    fi
    if [ "${subtitle}" != "9" ]; then
        maps="0:${subtitle}"
    fi
    
    echo ${mapv}, ${mapa}, ${maps}
    
    if [ "${mode}" != "test" ]; then
            while true 
            do
                #min=$(TZ=Asia/Shanghai date +%M)
                if [ "$(get_rest)" = "rest" ]; then
                    next_video=$(get_videos)
                    duration=$(get_duration2 "${next_video}")
                    content="${rest_start}点到$(expr $rest_end + 1)点休息${enter}时长\:${duration}${enter}播放\:%{pts\:gmtime\:0\:%H\\\\\:%M\\\\\:%S}"
                    video_format1="eq=contrast=1:brightness=0.15,curves=preset=lighter"
                    drawtext1="drawtext=fontsize=${fontsize}:fontcolor=red:text='${content}':fontfile=${fontdir}:expansion=normal:x=5:y=5:shadowx=2:shadowy=2"
                    video_format1="${video_format1},${drawtext1},${drawtext2}"
                    echo ffmpeg -loglevel "${logging}" -re -i "${next_video}" -preset ${preset_decode_speed} -vf "${video_format1}" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv ${rtmp}
                    ffmpeg -loglevel "${logging}" -re -i "${next_video}" -preset ${preset_decode_speed} -vf "${video_format1}" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv ${rtmp}
                #elif [ ${min} -le 59 ] && [ ${min} -ge 35 ];then
                else                
                    #content="休息一下稍后播出"
                    #video_format1="eq=contrast=1:brightness=0.15,curves=preset=lighter"
                    #drawtext1="drawtext=fontsize=${fontsize}:fontcolor=red:text=${content}:fontfile=${fontdir}:expansion=normal:x=(mod(5*n\,w+tw)-tw):y=line_h+10:shadowx=2:shadowy=2"
                    #video_format1="${video_format1},${drawtext1}"
                    #ffmpeg -loglevel "${logging}" -re -i "$(get_videos)" -preset ${preset_decode_speed} -vf "${video_format1}" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv ${rtmp}
                    break
                #else
                #    break
                fi
            done
    fi
    
    date1=$(date +"%Y-%m-%d %H:%M:%S") 
    
    if [ "$image" = "" ];then
        echo -e "${yellow} 你选择不添加水印,程序将开始推流. ${font}"
        if [ "${maps}" = "" ]; then
          echo ffmpeg -loglevel "${logging}"  -re -i "$file"  -map ${mapv} -map ${mapa} -preset ${preset_decode_speed} -vf "${video_format}" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv ${rtmp}
          if [ "${mode}" != "test" ];then
              ffmpeg -loglevel "${logging}" -re -i "$file" -map ${mapv} -map ${mapa} -preset ${preset_decode_speed} -vf "${video_format}" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv ${rtmp}
          fi
        else
          echo ffmpeg -loglevel "${logging}" -re -i "$file" -map ${mapv} -map ${mapa} -preset ${preset_decode_speed} -vf "${video_format}" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv ${rtmp}
          if [ "${mode}" != "test" ];then
              ffmpeg -loglevel "${logging}" -re -i "$file" -map ${mapv} -map ${mapa} -preset ${preset_decode_speed} -vf "${video_format}" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv ${rtmp}
          fi
        fi
    else
        echo -e "${yellow} 添加水印完成,程序将开始推流. ${font}" 
        watermark="overlay=W-w-5:5"
        if [ "${maps}" = "" ]; then
          echo ffmpeg -loglevel "${logging}" -re  -i "$file"  -map ${mapv} -map ${mapa} -preset ${preset_decode_speed} -vf "${video_format}"  -i "${image}" -filter_complex "${watermark}" -c:v libx264 -c:a aac -b:a 192k  -strict -2 -f flv ${rtmp}
          if [ "${mode}" != "test" ];then
              ffmpeg -loglevel "${logging}" -re -i "$file"  -map ${mapv} -map ${mapa} -preset ${preset_decode_speed} -vf "${video_format}"  -i "${image}" -filter_complex "${watermark}" -c:v libx264 -c:a aac -b:a 192k  -strict -2 -f flv ${rtmp}
          fi
        else
          echo ffmpeg -loglevel "${logging}" -re -i "$file"  -map ${mapv} -map ${mapa} -preset ${preset_decode_speed} -vf "${video_format}"  -i "${image}" -filter_complex "${watermark}" -c:v libx264 -c:a aac -b:a 192k  -strict -2 -f flv ${rtmp}
          if [ "${mode}" != "test" ];then
              ffmpeg -loglevel "${logging}" -re -i "$file" -map ${mapv} -map ${mapa} -preset ${preset_decode_speed} -vf "${video_format}"  -i "${image}" -filter_complex "${watermark}" -c:v libx264 -c:a aac -b:a 192k  -strict -2 -f flv ${rtmp}
          fi
        fi
    fi

    date2=$(date +"%Y-%m-%d %H:%M:%S")

    sys_date1=$(date -d "$date1" +%s)
    sys_date2=$(date -d "$date2" +%s)
    time_seconds=`expr $sys_date2 - $sys_date1`
    
    if [ "${mode}" != "test" ] && [ "$?" = "0" ] && [ ${time_seconds} -ge 700 ]; then
        echo "$file" >> "${playlist_done}"
    fi
}

stream_play_main(){
    line=$1   
    line=`echo ${line} | tr -d '\r'`
    line=`echo ${line} | tr -d '\n'`
    play_mode=$2
    mode=$3
   
    # 判断是否要跳过   
    flag=${line:0:1}
    if [ "${flag}" = "#" ];then
        return
    fi
   
    video_type=${line:0:4}
    audio=${line:4:1}
    subtitle=${line:5:1}
    line=${line:6}
    echo $line
    
    if [[ -d "${line}" ]];then
        echo $line
        echo $play_mode
        file_count=`ls -l $line  |grep "^-"|wc -l`
        cur_file=0
        for subdirfile in "$line"/*; do
            cur_file=$(expr $cur_file + 1)
            if [ "${play_mode}" = "random"  ] && [[ -e "${playlist_done}" ]] && cat "${playlist_done}" | grep "$subdirfile" > /dev/null; then
                continue
            fi
            stream_play "${subdirfile}" "${video_type}" "${audio}" "${subtitle}" "${file_count}" "${cur_file}" "${mode}"    
            if [ "${play_mode}" = "random"  ]; then
                echo "next folder"
                break
            fi
        done
        echo "播放完毕"
    elif [[ -f "${line}" ]] ; then
        stream_play "${line}" "${video_type}" "${audio}" "${subtitle}" 1 1 "${mode}"
        echo "播放完毕"
    else
        echo "目录或者文件${line}不识别"
    fi
   
}

stream_start(){    
    play_mode=$1
    mode=$2

    if [[ $rtmp =~ "rtmp://" ]];then
        echo -e "${green} 推流地址输入正确,程序将进行下一步操作. ${font}"
        sleep 2
    else  
        echo -e "${red} 你输入的地址不合法,请重新运行程序并输入! ${font}"
        exit 1
    fi 


    while true
    do
      for line in `cat ${playlist}`
      do
          echo "File:${line}"
	        date
          stream_play_main "${line}" "${play_mode}" "${mode}"
          date
      done
      # 等待1秒钟再一次读取播放列表
      sleep 1
      echo “再次读取下一个目录......................”
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
                    echo "000099/mnt/smb/电视剧/${filenamelist[$vindex]}" >> ${playlist}
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
        stream_play_main "000099${param}"
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


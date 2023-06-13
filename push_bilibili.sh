#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 颜色选择
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
font="\033[0m"
# 定义推流地址和推流码
rtmp="rtmp://live-push.bilivideo.com/live-bvc/?streamname=live_97540856_1852534&key=a042d1eb6f69ca88b16f4fb9bf9a5435&schedule=rtmp&pflag=1"
# 配置水印文件
image=
playlist=`pwd`/playlist.m3u
playlist_done=`pwd`/playlist_done.m3u
waiting=`pwd`/waiting.mp4

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

stream_play(){
    file=$1
    video_type=$2
    audio=$3 

    killall ffmpeg
    
    # 文件超过50GB不要播放
    maxsize=50000000000
    actualsize=$(wc -c <"$file")
    echo $actualsize
    if [ $actualsize -ge $maxsize ]; then
        return 0
    fi
    
    # 已经播放过的不要播放
    if [[ -e "${playlist_done}" ]]; then
      if cat "${playlist_done}" |grep "$file" > /dev/null; then
        echo "已经播放过视频${file}"
        return
      fi
    fi
    
    echo "推送${file}"

    logging="repeat+level+warning"
    preset_decode_speed="ultrafast"
    video_format="eq=contrast=1:brightness=0.2,curves=preset=lighter"
    mapv="0:0"
    mapa="0:${audio}"

    #去掉logo
    if [ "$video_type" = "YOUK" ];then
      video_format="delogo=x=795:y=25:w=160:h=35:show=0,eq=contrast=1:brightness=0.2,curves=preset=lighter"
    elif [ "$video_type" = "TVB0" ];then
      video_format="delogo=x=965:y=40:w=75:h=60:show=0,eq=contrast=1:brightness=0.2,curves=preset=lighter"
    elif [ "$video_type" = "TVB1" ];then
      video_format="delogo=x=400:y=30:w=75:h=60:show=0,eq=contrast=1:brightness=0.2,curves=preset=lighter"
    else
      video_format="eq=contrast=1:brightness=0.2,curves=preset=lighter"
    fi

    if [ "$image" = "" ];then
      echo -e "${yellow} 你选择不添加水印,程序将开始推流. ${font}"
      echo ffmpeg -loglevel ${logging} -re -i "$file" -map ${mapv} -map ${mapa} -preset ${preset_decode_speed} -vf "${video_format}" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv ${rtmp} 
      ffmpeg -loglevel ${logging} -re -i "$file" -map ${mapv} -map ${mapa} -preset ${preset_decode_speed} -vf "${video_format}" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv ${rtmp}
    else
      echo -e "${yellow} 添加水印完成,程序将开始推流. ${font}" 
      watermark="overlay=W-w-5:5"
      echo ffmpeg -re -loglevel ${logging} -i "$file" -map ${mapv} -map ${mapa} -preset ${preset_decode_speed} -vf "${video_format}"  -i "${image}" -filter_complex "${watermark}" -c:v libx264 -c:a aac -b:a 192k  -strict -2 -f flv ${rtmp} 
      ffmpeg -re -loglevel ${logging} -i "$file" -map ${mapv} -map ${mapa} -preset ${preset_decode_speed} -vf "${video_format}"  -i "${image}" -filter_complex "${watermark}" -c:v libx264 -c:a aac -b:a 192k  -strict -2 -f flv ${rtmp}
    fi

    if [ "$?"  =  "0"  ];then
      echo "$file" >> "${playlist_done}"
    fi
    
    while true
    do
      hours=$(TZ=Asia/Shanghai date +%H)
      if [ ${hours} -gt 6 ];then
        break
      fi
      video_format="drawtext=fontcolor=black:fontsize=50:text='晚上0点到6点休息，停止播放':x=0:y=0"
      ffmpeg -loglevel ${logging} -re -i "${waiting}" -preset ${preset_decode_speed} -vf "${video_format}" -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv ${rtmp}
    done 
}

stream_play_main(){
   line=$1   
   line=`echo ${line} | tr -d '\r'`
   line=`echo ${line} | tr -d '\n'`
   
   video_type=${line:0:4}
   audio=${line:4:1}
   line=${line:5}
   if [[ -d "${line}" ]];then
     for subdirfile in "$line"/*; do
       stream_play "${subdirfile}" "${video_type}" "${audio}"
     done
     elif [[ -f "${line}" ]] ; then
       stream_play "${line}" "${video_type}" "${audio}"
     fi
}

stream_start(){    
    if [[ $rtmp =~ "rtmp://" ]];then
      echo -e "${green} 推流地址输入正确,程序将进行下一步操作. ${font}"
        sleep 2
      else  
        echo -e "${red} 你输入的地址不合法,请重新运行程序并输入! ${font}"
        exit 1
    fi 

    while true
    do
      line_no=1  
      while read line; do 
        stream_play_main "${line}" 
        line_no=$((line_no+1))
      done < "${playlist}"
      # 等待60秒钟再一次读取播放列表
      sleep 60
    done
}

# 停止推流
stream_stop(){
  killall ffmpeg
}

# 开始菜单设置
echo -e "${yellow} FFmpeg无人值守直播工具(version 1.1) ${font}"
echo -e "${green} 1.安装FFmpeg (机器要安装FFmpeg才能正常推流) ${font}"
echo -e "${green} 2.开始无人值守循环推流 ${font}"
echo -e "${green} 3.开始无人值守循环推流 ${font}"
echo -e "${green} 4.停止推流 ${font}"
start_menu(){
    echo $1
    if [ "$1" = "" ]; then
      read -p "请输入数字(1-3),选择你要进行的操作:" num
    else
      num=$1
    fi
    case "$num" in
        1)
        ffmpeg_install
        ;;
        2)
        stream_start
        ;;
        3)
        stream_play_main "0000$2"
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
start_menu $1

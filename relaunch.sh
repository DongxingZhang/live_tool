echo $1
echo $2
if [ "$2" != "test" ];then    
    killall ffmpeg
    killall push_bilibili.sh    
    ps -elf | grep ffmpeg 
    ps -elf | grep push_bilibili
fi

if [ "$2" = "bg" ]; then
  echo "background pushing"
  nohup ./push_bilibili.sh 2 $1 $2 >./log/ffmpeg.log 2>&1 &
  tail ./log/ffmpeg.log
elif [ "$2" = "fg" ]; then
  echo "foreground pushing"
  ./push_bilibili.sh 2 $1 $2
elif [ "$2" = "test" ]; then
  echo "test pushing"
  ./push_bilibili.sh 2 $1 $2
else
  echo "exit"
fi


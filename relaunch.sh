mode=$1

if [ "${mode}" != "test" ];then    
    killall ffmpeg
    killall push_bilibili.sh
    sleep 4    
    ps -elf | grep ffmpeg 
    ps -elf | grep push_bilibili
fi

read -p "请输入任意继续:" any

if [ "${mode}" = "bg" ]; then
  echo "background pushing"
  nohup ./push_bilibili.sh 2 any ${mode} >./log/ffmpeg.log 2>&1 &
  sleep 2
  ps -elf | grep ffmpeg
  ps -elf | grep push_bilibili
elif [ "${mode}" = "fg" ]; then
  echo "foreground pushing"
  ./push_bilibili.sh 2 any ${mode}
elif [ "${mode}" = "test" ]; then
  echo "test pushing"
  ./push_bilibili.sh 2 any ${mode}
else
  echo "exit"
fi


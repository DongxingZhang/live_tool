mode=$1

if [ "${mode}" != "test" ];then    
    killall ffmpeg
    killall pb.sh
    sleep 4    
    ps -elf | grep ffmpeg 
    ps -elf | grep pb.sh
fi

read -p "请输入任意继续:" any

if [ "${mode}" = "bg" ]; then
  echo "background pushing"
  nohup ./pb.sh 2 ${mode} >./log/ffmpeg.log 2>&1 &
  sleep 2
  ps -elf | grep ffmpeg
  ps -elf | grep pb.sh
elif [ "${mode}" = "fg" ]; then
  echo "foreground pushing"
  ./pb.sh 2 ${mode}
elif [ "${mode}" = "test" ]; then
  echo "test pushing"
  ./pb.sh 2 ${mode}
else
  echo "exit"
fi


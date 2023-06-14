killall ffmpeg
killall push_bilibili.sh
ps -elf | grep ffmpeg 
ps -elf | grep push_bilibili
sleep 5
if [ "$2" = "bg" ]; then
  echo "background pushing"
  nohup ./push_bilibili.sh 2 $1 &
elif [ "$2" = "fg" ]; then
  echo "foreground pushing"
  ./push_bilibili.sh 2 $1
else
  echo "exit"
fi


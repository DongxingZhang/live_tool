killall ffmpeg
killall push_bilibili.sh
ps -elf | grep ffmpeg 
ps -elf | grep push_bilibili
sleep 5
nohup ./push_bilibili.sh 2 &

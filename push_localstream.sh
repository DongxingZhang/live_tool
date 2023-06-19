#ffmpeg -i  搬到千般恨.mp4 -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2  -f flv rtmp://127.0.0.1:1935/live/1
#ps -ef|grep -v grep|grep "${command_line}"|awk '{print $2}' | while read pid
#do
#   kill -9  $pid
#done    
#tail -f ./trans.log
       
killall nginx
sleep 3
ps -elf | grep nginx
/usr/local/nginx/sbin/nginx
sleep 3
#rtmp="rtmp://live-push.bilivideo.com/live-bvc/?streamname=live_97540856_1852534&key=a042d1eb6f69ca88b16f4fb9bf9a5435&schedule=rtmp&pflag=1"
rtmp="rtmp://www.tomandjerry.work/live/livestream"
local_rtmp="rtmp://127.0.0.1:1935/live/1"    
while true
do
    command_line="ffmpeg -i ${local_rtmp} -acodec copy -vcodec copy -f flv ${rtmp}"
    pids=$(ps -ef|grep -v grep|grep "${command_line}"|awk '{print $2}')
    if [ "${pids}" = "" ];then
        echo "进程退出，重新"
        nohup ffmpeg -i ${local_rtmp} -acodec copy -vcodec copy -f flv ${rtmp} >./trans.log 2>&1 &
    fi
    echo $pids
    sleep 2
done

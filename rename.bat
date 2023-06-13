@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
 
REM 要扫描的目录作为参数传入（未传值则默认为bat文件所在目录）
CD /d "%~dp0"
 
FOR /F "delims=" %%a IN ('DIR /A /B *.mkv1') DO (
    SET FILE_NAME=%%~na
    SET FILE_NAME_EXT=%%~xa
    ECHO "%%a" "!FILE_NAME!.mkv"
    RENAME "%%a" "!FILE_NAME!.mkv"
    
    REM 或者使用如下这2行
    REM ECHO "%%a" "%%~na(公开)%%~xa"
    REM RENAME "%%a" "%%~na(公开)%%~xa"
)
PAUSE&
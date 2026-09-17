@REM Stabilize a video with ffmpeg
@REM Usage: stab.bat <video file> [zoom factor (default: 1.25)] [ratio Y (default: 0.75)]
@REM Requires: ffmpeg essentials (ffmpeg, libvidstab): https://www.gyan.dev/ffmpeg/builds/

@REM Sources: https://www.paulirish.com/2021/video-stabilization-with-ffmpeg-and-vidstab/, https://blog.pesky.moe/posts/2024-09-21-video-stabilise/

set vid=%1
set vidName=%~n1
set vidExt=%~x1
set VidPath=%~dp1

set zoomfactor=%2
set ratioY=%3

if "%zoomfactor%"=="" set zoomfactor=1.25
if "%ratioY%"=="" set ratioY=0.75

set vidOut=%vidPath%%vidName%_stabZoom_%zoomfactor%Y%ratioY%%vidExt%

echo "%vidName% %vidExt% %vidPath% %vid% %vidOut%"

@REM ffmpeg -i "%vid%" -vf vidstabdetect -f null - & ffmpeg -i "%vid%" -vf vidstabtransform "%vidOut%"



echo "Zoom factor: %zoomfactor% Ratio Y: %ratioY%"


ffmpeg -i "%vid%" -vf vidstabdetect -f null - & ffmpeg -i "%vid%" -vf "vidstabtransform,crop=w=in_w/%zoomfactor%:h=in_h/%zoomfactor%:x=0:y=(in_h-out_h)*%ratioY%, scale=3840x2160" "%vidOut%"
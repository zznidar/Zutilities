@REM Stabilize a video with ffmpeg
@REM Usage: stab.bat <video file> [zoom factor (default: 1.25)] [ratio Y (default: 0.75)] [ratio X (default: 0)] [skip (default: do_not_skip)]
@REM Requires: ffmpeg essentials (ffmpeg, libvidstab): https://www.gyan.dev/ffmpeg/builds/

@REM Sources: https://www.paulirish.com/2021/video-stabilization-with-ffmpeg-and-vidstab/, https://blog.pesky.moe/posts/2024-09-21-video-stabilise/

@ECHO OFF

echo.
echo "**************************************"
echo "*** Stabilize a video with ffmpeg. ***" 
echo "*** Usage: stab.bat <video file> [zoom factor (default: 1.25)] [ratio Y (default: 0.75)] [ratio X (default: 0)] [skip (default: do_not_skip)] ***"
echo "*** (this defaults to almost-bottom left corner) ***"
echo "**************************************"
echo.
echo.

set vid=%1
set vidName=%~n1
set vidExt=%~x1
set VidPath=%~dp1

set zoomfactor=%2
set ratioY=%3
set ratioX=%4

set skip=%5

if "%zoomfactor%"=="" set zoomfactor=1.25
if "%ratioY%"=="" set ratioY=0.75
if "%ratioX%"=="" set ratioX=0
if "%skip%"=="" set skip=0

set vidOut=%vidPath%%vidName%_stabZoom_%zoomfactor%Y%ratioY%X%ratioX%%vidExt%

echo "%vidName% %vidExt% %vidPath% %vid% %vidOut%"

@REM ffmpeg -i "%vid%" -vf vidstabdetect -f null - & ffmpeg -i "%vid%" -vf vidstabtransform "%vidOut%"



echo "Zoom factor: %zoomfactor% Ratio Y: %ratioY% Ratio X: %ratioX%"
echo.

if "%skip%"=="skip" (
    echo "Skipping detection and going directly to transformation (using existing transforms.trf matrix file)."
    goto :apply
    )

:detect
ffmpeg -i "%vid%" -vf vidstabdetect -f null - 

:apply
ffmpeg -i "%vid%" -vf "vidstabtransform,crop=w=in_w/%zoomfactor%:h=in_h/%zoomfactor%:x=(in_w-out_w)*%ratioX%:y=(in_h-out_h)*%ratioY%, scale=3840x2160" "%vidOut%"
# Zutilities
Various scripts and utilities to speed up everyday tasks.

## stab.bat
Stabilises video using ffmpeg. Additionally, zooms it to the requested Y ratio (0 = top-left corner; 1 = bottom-left corner).
```bat
stab.bat <video file> [zoom factor (default: 1.25)] [ratio Y (default: 0.75)] [ratio X (default: 0)] [skip (default: do_not_skip)]
```
If you need to change the zoom/ratio after already analysing the clip once, you can pass `skip` as the last (5th) parameter.

## translateCSV.jl
Translates American .csv into European .csv (semicolon-separated, with comma as decimal separator). This allows you to open .csv files in Excel by double-clicking.  
For quick access on hpc, add this line to .bashrc:
```sh
# Convert American .csv into European .csv (semicolon-separated, with comma as decimal separator)
alias csv2ssv="module load Julia && julia --threads=auto --project='/ceph/hpc/home/User/JulesEnv' /ceph/hpc/home/User/julči/translateCSV.jl"
```

## best10ofScenario.jl
Get 10 best Prosculpt designs of each scenario, sorted by ddg.  
```sh
julia --threads=auto --project='/ceph/hpc/home/User/JulesEnv' /ceph/hpc/home/User/julči/best10ofScenario.jl '/ceph/hpc/home/User/julči/test.csv'
```
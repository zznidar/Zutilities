#= Translate American .csv into European .csv (semicolon-separated, with comma as decimal separator) 
Requires: julia, CSV, DataFrames =#


# All code should be run in the environment /ceph/hpc/home/User/JulesEnv

# Run as: 
# julia --threads=auto --project="/ceph/hpc/home/User/JulesEnv" /ceph/hpc/home/User/julči/translateCSV.jl '/ceph/hpc/home/User/julči/test.csv'

#= using Pkg
Pkg.activate("/ceph/hpc/home/User/JulesEnv")
 =#
using CSV
using DataFrames

#=
This code translates English .csv files to Slovenian (aka European) .csv files.
This allows non-american users to open .csv files in Microsoft Excel

Traditional ("American") .csv files use a comma (",") as the delimiter and a period (".") as the decimal separator.
European .csv files use a semicolon (";") as the delimiter and a comma (",") as the decimal separator.

In all of its history, Microsoft Excel hasn't figured out yet that people share .csv files around the world and that they should be compatible with each other.
It really does not excel at that. 

Funnily, user can import a .csv file in a rigurous way (not by double-clicking it, but by Importing Data from Text),
then selecting the delimiter. However, decimal separator is fixed to current Excel language and cannot be changed. 🤦🏻‍♀️
=#

for f in ARGS
    println("Translating file: $f")
    data = CSV.read(f, DataFrame; delim=',', decimal='.', #= typemap=IdDict(Float64 => BigFloat) =# )
    out_f = replace(f, ".csv" => "_EU.csv")
    CSV.write(out_f, data; delim=';', decimal=',')
    println("Written translated file: $out_f")
end

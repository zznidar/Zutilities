# All code should be run in the environment /ceph/hpc/home/User/JulesEnv

# Run as: 
# julia --threads=auto --project="/ceph/hpc/home/User/JulesEnv" /ceph/hpc/home/User/julči/best10ofScenario.jl '/ceph/hpc/home/User/julči/test.csv'

#= using Pkg
Pkg.activate("/ceph/hpc/home/User/JulesEnv")
 =#


using CSV, DataFrames

# Take rosetta.csv as input arg, e. g. /ceph/hpc/home/User/bind2mt/ANALIZA/2026-01-30/pooled_best_pdbs/2026-01-30_rosetta.csv
input_csv = ARGS[1]

df = CSV.read(input_csv, DataFrame)

# /ceph/hpc/data/Users/User/bind2mt/output/dinein_brezScaffolda_2026-01-19/03/1_rfdiff/_1.pdb -> get dinein_brezScaffolda_2026-01-19 by splitting by / an taking from the back
df.scenario = [split(path, "/")[end-3] for path in df.path_rfdiff]

# Group them by scenario
grouped = groupby(df, :scenario)
best10 = DataFrame()

# For each group, sort by ddg ascending (and if they have same ddg value, sort also by monomer_plddt descending and take the top 10
for g in grouped
    sorted_g = sort(g, [:ddg, :monomer_plddt], rev = [false, true])
    top10 = first(sorted_g, 10)
    append!(best10, top10)
end

# Save best10ofScenario.csv into grandparent folder of input_csv
CSV.write(joinpath(splitpath(input_csv)[1:end-2]..., "best10ofScenario.csv"), best10)
mkpath(joinpath(splitpath(input_csv)[1:end-2]..., "best10ofScenario"))
# make hardlinks to the pdb files in best10
for row in eachrow(best10)
    src = "$(joinpath(splitpath(input_csv)[1:end-2]..., "pooled_best_pdbs", "minimized", row.ID))"
    scenario = row.scenario
    filename = split(src, "/")[end]
    dest = "$(joinpath(splitpath(input_csv)[1:end-2]..., "best10ofScenario", "$(scenario)_$(filename)"))"
    run(`ln $src $dest`)
end

# Convert csv to EU-csv
run(`bash -ic "csv2ssv $(joinpath(splitpath(input_csv)[1:end-2]..., "best10ofScenario.csv"))"`)
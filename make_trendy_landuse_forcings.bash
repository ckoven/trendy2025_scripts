#! /bin/bash

cd /Users/CDKoven/datasets/tools-fates-landusedata/src

python -m landusedata luh2 ~/datasets/trendy2025/surfdata_1.9x2.5_simyr1850_c130927.nc ~/datasets/trendy2025/multiple-static_input4MIPs_landState_CMIP_UofMD-landState-3-1_gn.nc ~/datasets/trendy2025/states4.nc ~/datasets/trendy2025/transitions4.nc ~/datasets/trendy2025/management4.nc

cp /Users/CDKoven/datasets/tools-fates-landusedata/src/LUH2_timeseries.nc ~/datasets/trendy2025/luh2_trendy2025_1.9x2.5_850-2024_23jun2025.nc

../constantlanduse/calculate_luh2_secondary_agedist.py luh2_trendy2025_1.9x2.5_850-2024_23jun2025.nc
mv LUH2_states_transitions_management.timeseries_ne30_hist_steadystate_1700_2025-06-23.nc LUH2_states_transitions_management.timeseries_1.9x2.5_trendy2025_steadystate_1700_2025-06-23.nc 

#! /bin/bash

cd /Users/CDKoven/datasets/tools-fates-landusedata/src

python -m landusedata luh2 ~/datasets/trendy2025_scripts/surfdata_1.9x2.5_simyr1850_c130927.nc ~/datasets/trendy2025_scripts/multiple-static_input4MIPs_landState_CMIP_UofMD-landState-3-1_gn.nc ~/datasets/trendy2025_scripts/states4.nc ~/datasets/trendy2025_scripts/transitions4.nc ~/datasets/trendy2025_scripts/management4.nc

cp /Users/CDKoven/datasets/tools-fates-landusedata/src/LUH2_timeseries.nc ~/datasets/trendy2025_scripts/luh2_trendy2025_1.9x2.5_850-2024_23jun2025.nc

../constantlanduse/calculate_luh2_secondary_agedist.py luh2_trendy2025_1.9x2.5_850-2024_23jun2025.nc
mv LUH2_states_transitions_management.timeseries_ne30_hist_steadystate_1700_2025-06-23.nc LUH2_states_transitions_management.timeseries_1.9x2.5_trendy2025_steadystate_1700_2025-06-23.nc 

python -m landusedata lupft /Users/CDKoven/datasets/trendy2025_scripts/surfdata_1.9x2.5_simyr1850_c130927.nc /Users/CDKoven/datasets/trendy2025_scripts/multiple-static_input4MIPs_landState_CMIP_UofMD-landState-3-1_gn.nc /Users/CDKoven/datasets/luh2/needed_data_for_files/CLM5_current_luhforest_deg025.nc /Users/CDKoven/datasets/luh2/needed_data_for_files/CLM5_current_luhpasture_deg025.nc /Users/CDKoven/datasets/luh2/needed_data_for_files/CLM5_current_luhother_deg025.nc /Users/CDKoven/datasets/luh2/needed_data_for_files/CLM5_current_surf_deg025.nc

cp fates_landuse_pft_map_to_surfdata_1_250627.nc ~/datasets/trendy2025_scripts/fates_landuse_pft_map_to_surfdata_1.9x2.5_250627.nc

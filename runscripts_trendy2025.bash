#!/usr/bin/env bash

SRCDIR=$HOME/E3SM/components/elm/src/
cd ${SRCDIR}
GITHASH1=`git log -n 1 --format=%h`
cd external_models/fates
GITHASH2=`git log -n 1 --format=%h`

#STAGE=AD_SPINUP
#STAGE=POSTAD_SPINUP
#STAGE=S0   #constant climate, CO2, land use
#STAGE=S1   #CO2 only (time-invariant “pre-industrial” climate and land use mask)
STAGE=S2   #CO2 and climate only (time-invariant “pre-industrial” land use mask), branch from S1 in year 1901
#STAGE=S3a  #CO2 and land use (repeat climate until year 1901)
#STAGE=S3b  #CO2, climate and land use (all forcing time-varying after year 1901)

if [ "$STAGE" = "AD_SPINUP" ]; then
    SETUP_CASE=f19_0005_adspinup_const1700LUH_swdif_2pftspasturerangeland
    COMPSET=I1850TRENDY2025
elif [ "$STAGE" = "POSTAD_SPINUP" ]; then
    SETUP_CASE=f19_0006_postadspinup_const1700LUH
    COMPSET=I1850TRENDY2025
elif [ "$STAGE" = "S0" ]; then
    SETUP_CASE=f19_0007_trendyS0
    COMPSET=I1850TRENDY2025
elif [ "$STAGE" = "S1" ]; then
    SETUP_CASE=f19_0008_trendyS1
    COMPSET=I20TRTRENDY2025
elif [ "$STAGE" = "S2" ]; then
    SETUP_CASE=f19_0010_trendyS2
    COMPSET=I20TRTRENDY2025
elif [ "$STAGE" = "S3a" ]; then
    SETUP_CASE=f19_0009_trendyS3_parta
    COMPSET=I20TRTRENDY2025
elif [ "$STAGE" = "S3b" ]; then
    SETUP_CASE=f19_0011_trendyS3_partb
    COMPSET=I20TRTRENDY2025
fi
    
CASE_NAME=${SETUP_CASE}_${GITHASH1}_${GITHASH2}
basedir=$HOME/E3SM/cime/scripts

cd $basedir
export RES=f19_g16
project=m2467

./create_newcase -case ${CASE_NAME} -res ${RES} -compset ${COMPSET} -mach pm-cpu -project $project


cd $CASE_NAME

ncgen -o fates_params_default_${GITHASH2}.nc ${SRCDIR}/external_models/fates/parameter_files/fates_params_default.cdl

# Add additional 2 patches and pfts each for the pasture and rangeland
/global/homes/c/cdkoven/E3SM/components/elm/src/external_models/fates/tools/modify_fates_paramfile.py --fin=fates_params_default_${GITHASH2}.nc --fout=fates_params_default_${GITHASH2}.nc --O --var=fates_max_nocomp_pfts_by_landuse --val=4,4,2,2,1
/global/homes/c/cdkoven/E3SM/components/elm/src/external_models/fates/tools/modify_fates_paramfile.py --fin=fates_params_default_${GITHASH2}.nc --fout=fates_params_default_${GITHASH2}.nc --O --var=fates_maxpatches_by_landuse --val=9,5,2,2,1

# add more age bins to history output
/global/homes/c/cdkoven/E3SM/components/elm/src/external_models/fates/tools/modify_fates_paramfile.py --fin=fates_params_default_${GITHASH2}.nc --fout=fates_params_default_${GITHASH2}.nc --O --var=fates_history_ageclass_bin_edges --val=0,1,2,5,10,20,50,100,200 --changeshape

# log daily
/global/homes/c/cdkoven/E3SM/components/elm/src/external_models/fates/tools/modify_fates_paramfile.py --fin=fates_params_default_${GITHASH2}.nc --fout=fates_params_default_${GITHASH2}.nc --O --var=fates_landuse_logging_event_code --val=3

### changes for all cases.
./xmlchange DIN_LOC_ROOT_CLMFORC=/dvs_ro/cfs/cdirs/e3sm/inputdata/atm/datm7/TRENDY2025/three_stream
./xmlchange DIN_LOC_ROOT=/dvs_ro/cfs/cdirs/e3sm/inputdata
./xmlchange JOB_QUEUE=debug
./xmlchange JOB_WALLCLOCK_TIME=00:15:00
./xmlchange NTASKS=-8
./xmlchange STOP_N=50
./xmlchange REST_N=10
./xmlchange STOP_OPTION=nyears
./xmlchange RESUBMIT=3

### make base file for user_nl_elm that will be used for all spinup and all experiments
cat > user_nl_elm <<EOF
fsurdat = '/dvs_ro/cfs/cdirs/e3sm/inputdata/lnd/clm2/surfdata_map/surfdata_1.9x2.5_simyr1850_c180306.nc'
flandusepftdat = '/global/homes/c/cdkoven/scratch/inputdata/fates_landuse_pft_map_to_surfdata_1.9x2.5_250627.nc'
use_fates_luh = .true.
use_fates_nocomp = .true.
use_fates_fixed_biogeog = .true.
fates_paramfile = '${basedir}/${CASE_NAME}/fates_params_default_${GITHASH2}.nc'
use_fates_sp = .false.
fates_spitfire_mode = 1
fates_harvest_mode = 'luhdata_area'
use_fates_potentialveg = .false.
use_century_decomp = .true.
suplphos = 'ALL'
suplnitro = 'ALL'
fates_parteh_mode = 2
nu_com = 'RD'
hist_fincl1 = 'FATES_SECONDARY_AREA_ANTHRO_AP','FATES_SECONDARY_AREA_AP','FATES_PRIMARY_AREA_AP','FATES_NPP_LU','FATES_GPP_LU','PROD10C','PROD100C','PRODUCT_CLOSS','FATES_SEEDS_IN_PF','FATES_SEEDS_IN_LOCAL_PF','FATES_NPLANT_CANOPY_SZPF','FATES_NPLANT_USTORY_SZPF','FATES_MORTALITY_USTORY_SZPF','FATES_MORTALITY_CANOPY_SZPF','FATES_CWD_ABOVEGROUND_DC','FATES_CWD_BELOWGROUND_DC','FATES_LEAF_ALLOC_SZPF','FATES_SEED_ALLOC_SZPF','FATES_FROOT_ALLOC_SZPF','FATES_BGSAPWOOD_ALLOC_SZPF','FATES_BGSTRUCT_ALLOC_SZPF','FATES_AGSAPWOOD_ALLOC_SZPF','FATES_AGSTRUCT_ALLOC_SZPF','FATES_STORE_ALLOC_SZPF','FATES_DDBH_CANOPY_SZPF','FATES_DDBH_USTORY_SZPF','FATES_NPLANT_ACPF','FATES_LAI_USTORY_SZPF','FATES_LAI_CANOPY_SZPF'
paramfile = '/global/homes/c/cdkoven/scratch/inputdata/clm_params_c211124_mod_ddefold.nc'
fates_radiation_model = 'twostream'
fates_leafresp_model = 'ryan1991'
EOF

if [ "$STAGE" = "AD_SPINUP"  ]; then

    ./xmlchange RUN_STARTDATE=0001-01-01
    ./xmlchange ELM_ACCELERATED_SPINUP=on
    ./xmlchange -id ELM_BLDNML_OPTS -val "-bgc fates -no-megan -no-drydep -bgc_spinup on"
    ./xmlchange CCSM_CO2_PPMV=277.57
    ./xmlchange DATM_CLMNCEP_YR_START=1901
    ./xmlchange DATM_CLMNCEP_YR_END=1920
    ./xmlchange DATM_PRESAERO=clim_1850

    cat >> user_nl_elm <<EOF
fluh_timeseries = '/global/homes/c/cdkoven/scratch/inputdata/LUH2_states_transitions_management.timeseries_1.9x2.5_trendy2025_steadystate_1700_2025-06-23.nc'
spinup_state = 1
EOF

elif [ "$STAGE" = "POSTAD_SPINUP" ]; then

    ./xmlchange RUN_STARTDATE=0001-01-01
    ./xmlchange ELM_ACCELERATED_SPINUP=off
    ./xmlchange -id ELM_BLDNML_OPTS -val "-bgc fates -no-megan -no-drydep"
    ./xmlchange CCSM_CO2_PPMV=277.57
    ./xmlchange DATM_CLMNCEP_YR_START=1901
    ./xmlchange DATM_CLMNCEP_YR_END=1920
    ./xmlchange DATM_PRESAERO=clim_1850

    cat >> user_nl_elm <<EOF
finidat='/global/homes/c/cdkoven/scratch/restfiles/f19_0005_adspinup_const1700LUH_swdif_2pftspasturerangeland_39e91e09b5_7b982905.elm.r.0351-01-01-00000.nc'
fluh_timeseries = '/global/homes/c/cdkoven/scratch/inputdata/LUH2_states_transitions_management.timeseries_1.9x2.5_trendy2025_steadystate_1700_2025-06-23.nc'
spinup_state = 0
EOF

elif [ "$STAGE" = "S0" ]; then

    ./xmlchange RUN_STARTDATE=1701-01-01
    ./xmlchange ELM_ACCELERATED_SPINUP=off
    ./xmlchange -id ELM_BLDNML_OPTS -val "-bgc fates -no-megan -no-drydep"
    ./xmlchange CCSM_CO2_PPMV=277.57
    ./xmlchange DATM_CLMNCEP_YR_START=1901
    ./xmlchange DATM_CLMNCEP_YR_END=1920
    ./xmlchange DATM_PRESAERO=clim_1850

    cat >> user_nl_elm <<EOF
finidat='/global/homes/c/cdkoven/scratch/restfiles/f19_0006_postadspinup_const1700LUH_39e91e09b5_7b982905.elm.r.0381-01-01-00000.nc'
fluh_timeseries = '/global/homes/c/cdkoven/scratch/inputdata/LUH2_states_transitions_management.timeseries_1.9x2.5_trendy2025_steadystate_1700_2025-06-23.nc'
spinup_state = 0
EOF


elif [ "$STAGE" = "S1" ]; then

    ./xmlchange RUN_STARTDATE=1701-01-01
    ./xmlchange -file env_run.xml -id CCSM_BGC -val CO2A
    ./xmlchange -file env_run.xml -id CLM_CO2_TYPE -val diagnostic
    ./xmlchange -id ELM_BLDNML_OPTS -val "-bgc fates -no-megan -no-drydep"
    ./xmlchange DATM_CLMNCEP_YR_START=1901
    ./xmlchange DATM_CLMNCEP_YR_END=1920
    ./xmlchange DATM_PRESAERO=clim_1850
    
    cat >> user_nl_elm <<EOF
finidat='/global/homes/c/cdkoven/scratch/restfiles/f19_0006_postadspinup_const1700LUH_39e91e09b5_7b982905.elm.r.0381-01-01-00000.nc'
fluh_timeseries = '/global/homes/c/cdkoven/scratch/inputdata/LUH2_states_transitions_management.timeseries_1.9x2.5_trendy2025_steadystate_1700_2025-06-23.nc'
EOF

elif [ "$STAGE" = "S2" ]; then

    ./xmlchange -file env_run.xml -id CCSM_BGC -val CO2A
    ./xmlchange -file env_run.xml -id CLM_CO2_TYPE -val diagnostic
    ./xmlchange -id ELM_BLDNML_OPTS -val "-bgc fates -no-megan -no-drydep"
    ./xmlchange DATM_CLMNCEP_YR_ALIGN=1901
    ./xmlchange DATM_CLMNCEP_YR_START=1901
    ./xmlchange DATM_CLMNCEP_YR_END=2024
    ./xmlchange DATM_PRESAERO=clim_1850

    ./xmlchange RESUBMIT=0
    PRIOR_CASE='f19_0008_trendyS1'
    ./xmlchange RUN_REFCASE=${PRIOR_CASE}_${GITHASH1}_${GITHASH2}
    ./xmlchange RUN_REFDIR=/global/homes/c/cdkoven/scratch/e3sm_scratch/pm-cpu/${PRIOR_CASE}_${GITHASH1}_${GITHASH2}/run/
    ./xmlchange RUN_REFDATE=1901-01-01
    ./xmlchange GET_REFCASE=TRUE
    ./xmlchange RUN_TYPE=branch
    
    cat >> user_nl_elm <<EOF
fluh_timeseries = '/global/homes/c/cdkoven/scratch/inputdata/LUH2_states_transitions_management.timeseries_1.9x2.5_trendy2025_steadystate_1700_2025-06-23.nc'
EOF


elif [ "$STAGE" = "S3a" ]; then

    ./xmlchange RUN_STARTDATE=1701-01-01
    ./xmlchange -file env_run.xml -id CCSM_BGC -val CO2A
    ./xmlchange -file env_run.xml -id CLM_CO2_TYPE -val diagnostic
    ./xmlchange -id ELM_BLDNML_OPTS -val "-bgc fates -no-megan -no-drydep"
    ./xmlchange DATM_CLMNCEP_YR_START=1901
    ./xmlchange DATM_CLMNCEP_YR_END=1920
    ./xmlchange DATM_PRESAERO=clim_1850
    
    cat >> user_nl_elm <<EOF
finidat='/global/homes/c/cdkoven/scratch/restfiles/f19_0006_postadspinup_const1700LUH_39e91e09b5_7b982905.elm.r.0381-01-01-00000.nc'
fluh_timeseries = '/global/homes/c/cdkoven/scratch/inputdata/luh2_trendy2025_1.9x2.5_850-2024_23jun2025.nc'
EOF



fi


./case.setup
./preview_namelists

## amend co2 fields to use the TRENDY-provided ones
if [ "$COMPSET" = "I20TRTRENDY2025"  ]; then
    cp CaseDocs/datm.streams.txt.co2tseries.20tr user_datm.streams.txt.co2tseries.20tr
    cp CaseDocs/datm_in user_nl_datm
    perl -w -i -p -e "s@/dvs_ro/cfs/cdirs/e3sm/inputdata/atm/datm7/CO2@/dvs_ro/cfs/cdirs/e3sm/inputdata/atm/datm7/TRENDY2025/CO2field@" user_datm.streams.txt.co2tseries.20tr
    perl -w -i -p -e "s@fco2_datm_1765-2007_c100614.nc@fco2_datm_global_simyr_1700-2024_TRENDY_c250625.nc@" user_datm.streams.txt.co2tseries.20tr
    perl -w -i -p -e "s@datm.streams.txt.co2tseries.20tr 1850 1850 2007@datm.streams.txt.co2tseries.20tr 1700 1700 2024@" user_nl_datm
fi

#./case.build
#./case.submit

#####
./xmlchange JOB_QUEUE=regular
./xmlchange JOB_WALLCLOCK_TIME=17:00:00
./case.submit

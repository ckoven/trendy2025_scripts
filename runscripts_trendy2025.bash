#!/usr/bin/env bash

SRCDIR=$HOME/E3SM/components/elm/src/
cd ${SRCDIR}
GITHASH1=`git log -n 1 --format=%h`
cd external_models/fates
GITHASH2=`git log -n 1 --format=%h`

#STAGE=AD_SPINUP
STAGE=POSTAD_SPINUP
#STAGE=TRANSIENT_LU_CONSTANT_CO2_CLIMATE
#STAGE=TRANSIENT_LU_TRANSIENT_CO2_CLIMATE

if [ "$STAGE" = "AD_SPINUP" ]; then
    SETUP_CASE=f19_0005_adspinup_const1700LUH_swdif_2pftspasturerangeland
elif [ "$STAGE" = "POSTAD_SPINUP" ]; then
    SETUP_CASE=f19_0006_postadspinup_const1700LUH
elif [ "$STAGE" = "TRANSIENT_LU_CONSTANT_CO2_CLIMATE" ]; then
    SETUP_CASE=f19_0018_translanduse_fromconst1850lu
fi
    
CASE_NAME=${SETUP_CASE}_${GITHASH1}_${GITHASH2}
basedir=$HOME/E3SM/cime/scripts

cd $basedir
export RES=f19_g16
project=m2467

./create_newcase -case ${CASE_NAME} -res ${RES} -compset I1850TRENDY2025 -mach pm-cpu -project $project


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
./xmlchange JOB_QUEUE=debug
./xmlchange JOB_WALLCLOCK_TIME=00:30:00

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
hist_fincl1 = 'FATES_SECONDARY_AREA_ANTHRO_AP','FATES_SECONDARY_AREA_AP','FATES_PRIMARY_AREA_AP','FATES_NPP_LU','FATES_GPP_LU','PROD10C','PROD100C','PRODUCT_CLOSS','FATES_SEEDS_IN_PF','FATES_SEEDS_IN_LOCAL_PF'
paramfile = '/global/homes/c/cdkoven/scratch/inputdata/clm_params_c211124_mod_ddefold.nc'
fates_radiation_model = 'twostream'
fates_leafresp_model = 'ryan1991'
EOF

if [ "$STAGE" = "AD_SPINUP"  ]; then

    ./xmlchange RUN_STARTDATE=0001-01-01
    ./xmlchange RESUBMIT=3
    ./xmlchange ELM_ACCELERATED_SPINUP=on
    ./xmlchange -id ELM_BLDNML_OPTS -val "-bgc fates -no-megan -no-drydep -bgc_spinup on"
    ./xmlchange NTASKS=-8
    ./xmlchange STOP_N=50
    ./xmlchange REST_N=5
    ./xmlchange STOP_OPTION=nyears

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
    ./xmlchange RESUBMIT=0
    ./xmlchange ELM_ACCELERATED_SPINUP=off
    ./xmlchange NTASKS=-8
    ./xmlchange STOP_N=1
    ./xmlchange REST_N=1
    ./xmlchange STOP_OPTION=nyears
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

elif [ "$STAGE" = "TRANSIENT_LU_CONSTANT_CO2_CLIMATE" ]; then

    ./xmlchange RUN_STARTDATE=1851-01-01
    ./xmlchange RESUBMIT=5
    ./xmlchange ELM_ACCELERATED_SPINUP=off
    ./xmlchange NTASKS=-5
    ./xmlchange STOP_N=30
    ./xmlchange REST_N=5
    ./xmlchange STOP_OPTION=nyears
    ./xmlchange JOB_QUEUE=debug
    ./xmlchange CCSM_CO2_PPMV=287.
    ./xmlchange JOB_WALLCLOCK_TIME=00:30:00

    ./xmlchange -id ELM_BLDNML_OPTS -val "-bgc fates -no-megan -no-drydep"

    #./xmlchange DATM_MODE=CLMCRUNCEP
    ./xmlchange DATM_CLMNCEP_YR_START=1901
    ./xmlchange DATM_CLMNCEP_YR_END=1920
    ./xmlchange DATM_PRESAERO=clim_1850

    ./xmlchange DIN_LOC_ROOT=/dvs_ro/cfs/cdirs/e3sm/inputdata
    
    cat > user_nl_elm <<EOF
fsurdat = '/global/cfs/cdirs/e3sm/inputdata/lnd/clm2/surfdata_map/surfdata_4x5_simyr2000_c130927.nc'
flandusepftdat = '/global/homes/c/cdkoven/scratch/inputdata/fates_landuse_pft_map_4x5_20240206.nc'
use_fates_luh = .true.
use_fates_nocomp = .true.
use_fates_fixed_biogeog = .true.
fates_paramfile = '${basedir}/${CASE_NAME}/fates_params_default_${GITHASH2}.nc'
use_fates_sp = .false.
fates_spitfire_mode = 1
fates_harvest_mode = 'luhdata_area'
use_fates_potentialveg = .false.
fluh_timeseries = '/global/homes/c/cdkoven/scratch/inputdata/LUH2_states_transitions_management.timeseries_4x5_hist_simyr1650-2015_c240216.nc'
use_century_decomp = .true.
spinup_state = 0
suplphos = 'ALL'
suplnitro = 'ALL'
finidat = '/global/homes/c/cdkoven/scratch/restfiles/f45_0014_postadspinup_const1850LU_gswp3_d3b202343c_ae17acb2.elm.r.0031-01-01-00000.nc'
fates_parteh_mode = 2
nu_com = 'RD'
hist_fincl1 = 'FATES_SECONDARY_AREA_ANTHRO_AP','FATES_SECONDARY_AREA_AP','FATES_PRIMARY_AREA_AP','FATES_NPP_LU','FATES_GPP_LU','PROD10C','PROD100C','PRODUCT_CLOSS'
paramfile = '/global/homes/c/cdkoven/scratch/inputdata/clm_params_c211124_mod_ddefold.nc'
fates_radiation_model = 'twostream'
fates_leafresp_model = 'ryan1991'
EOF

fi


./case.setup
#./preview_namelists
./case.build
./case.submit

#!/bin/bash

# define the exit codes
SUCCESS=0
ERR_PUBLISH=55
ERR_DATA=56
ERR_GDAL_TRANSLATE=57
ERR_SEN2COR=58

# source the ciop functions (e.g. ciop-log, ciop-getparam)
source ${ciop_job_include}

###############################################################################
# Trap function to exit gracefully
# Globals:
#   SUCCESS
#   ERR_PUBLISH
#   ERR_DATA
#   ERR_GDAL_TRANSLATE
# Arguments:
#   None
# Returns:
#   None
###############################################################################
function cleanExit ()
{
  local retval=$?
  local msg=""
  case "${retval}" in
    ${SUCCESS}) msg="Processing successfully concluded";;
    ${ERR_PUBLISH}) msg="Failed to publish the results";;
    ${ERR_DATA}) msg="Failed to get data";;
    ${ERR_GDAL_TRANSLATE}) msg="Failed performing gdal_translate";;
    ${ERR_SEN2COR}) msg="Failed performing sen2cor";;
    *) msg="Unknown error";;
  esac

  [ "${retval}" != "0" ] && ciop-log "ERROR" "Error ${retval} - ${msg}, processing aborted" || ciop-log "INFO" "${msg}"
  exit ${retval}
}


###############################################################################
# Log an input string to the log file
# Globals:
#   None
# Arguments:
#   input reference to log
# Returns:
#   None
###############################################################################
function log_input()
{
  local input=${1}
  ciop-log "INFO" "processing input: ${input}"
}

###############################################################################
# Publish data as result of the process, storing it on HDFS
# Globals:
#   None
# Arguments:
#   input reference to pass
# Returns:
#   0 on success
#   ERR_PUBLISH if something goes wrong 
###############################################################################
function publish_data()
{
  local output=${1}
  ciop-publish -m ${output} || return ${ERR_PUBLISH}
}

###############################################################################
# Get data from an opensearch url
# Globals:
#   None
# Arguments:
#   input reference to pass
# Returns:
#   0 on success
#   ERR_DATA if something goes wrong
###############################################################################
function get_data() {
 
  local reference=${1}
  local target=${2}
  local local_file
  local enclosure
  local res

  enclosure=$( opensearch-client "${reference}&do=$HOSTNAME" enclosure )
  res=$?
  [ ${res} -ne 0 ] && ${ERR_GETDATA}

  ciop-log "INFO" "[get_data function] Data enclosure url: ${enclosure}"
    
  local_file="$( echo ${enclosure} | ciop-copy -U -f -O ${target} - 2> /dev/null )"
  res=$?
  [ ${res} -ne 0 ] && return ${ERR_GETDATA}
 
  unzip -qq -o ${local_file} -d ${target} 1>&2 
  
  echo "${local_file}.SAFE"
}

###############################################################################
# SEN2COR is a prototype processor for Sentinel-2 Level 2A product formatting 
# and processing. The processor performs the tasks of atmospheric, terrain and
# cirrus correction and a scene classification of Level 1C input data.
# Globals:
#   None
# Arguments:
#   product folder
# Returns:
#   0 on success
#   ERR_DATA if something goes wrong
###############################################################################
function sen2cor() {

  local reference=${1}
  local product=${2}
  
  local resolution="$( ciop-getparam resolution)"
  local identifier=$( opensearch-client -m EOP ${reference} identifier)
  
  # Setting sen2cor environment
  export PATH=/opt/anaconda/bin/:${PATH}
  export SEN2COR_BIN=/opt/anaconda/lib/python2.7/site-packages/sen2cor
  export SEN2COR_HOME=${TMPDIR}/sen2cor/
  export GDAL_DATA=/opt/anaconda/share/gdal
  mkdir -p ${TMPDIR}/sen2cor/cfg
  
  cp ${SEN2COR_BIN}/cfg/L2A_GIPP.xml ${SEN2COR_HOME}/cfg
  cp ${SEN2COR_BIN}/cfg/L2A_CAL_AC_GIPP.xml $SEN2COR_HOME/cfg/
  cp ${SEN2COR_BIN}/cfg/L2A_CAL_SC_GIPP.xml $SEN2COR_HOME/cfg/
  
  ciop-log "INFO" "[sen2cor function] Invoke SEN2COR L2A_Process"
  
  L2A_Process --resolution ${resolution} ${product} 1>&2
  
  level_2a="$( echo ${identifier} | sed 's/OPER/USER/' | sed 's/MSIL1C/MSIL2A/' )" || level_2a="${identifier}"
  
  cd ${TMPDIR}/${level_2a}.SAFE
  metadata="$( find . -maxdepth 1 -name "S2A*.xml" )"
  
  subset=$( gdalinfo ${metadata} 2> /dev/null | grep -E  "SUBDATASET_._NAME" \
       | grep "${resolution}m" | cut -d "=" -f 2 )
  
  ciop-log "INFO" "Process ${subset}"
  
  gdal_translate \
         ${subset} \
         ${TMPDIR}/${level_2a}_${resolution}.TIF 1>&2 || return ${ERR_GDAL_TRANSLATE}

  echo ${TMPDIR}/${level_2a}_${resolution}.TIF   
}

###############################################################################
# Main function to process an input reference
# Globals:
#   None
# Arguments:
#   input reference to process
# Returns:
#   0 on success
#   ERR_PUBLISH if something goes wrong
###############################################################################
function main()
{
  local reference=${1}
  
  ciop-log "INFO" "**** Sentinel-2 Atmospheric Correction ****"
  ciop-log "INFO" "------------------------------------------------------------"
  ciop-log "INFO" "Input S-2 L1C product reference: ${reference}" 
  ciop-log "INFO" "------------------------------------------------------------"

  ciop-log "INFO" "STEP 1: Getting input product" 
  local_product=$( get_data "${reference}" "${TMPDIR}" ) || return ${ERR_GET_DATA}
  ciop-log "INFO" "------------------------------------------------------------"
  
  ciop-log "INFO" "STEP 2: SEN2COR tool"
  output=$( sen2cor "${reference}" "${local_product}" ) || return ${ERR_GET_DATA}
  ciop-log "INFO" "------------------------------------------------------------"
  
  ciop-log "INFO" "STEP 3: Publishing results"
  publish_data "${output}" || return ${ERR_PUBLISH}
  ciop-log "INFO" "------------------------------------------------------------"
}

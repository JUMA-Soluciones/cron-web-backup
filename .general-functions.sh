#/bin/bash

# Bash script to easily backup folders and database from local or remote 
# FTP or SFTP locations to a bucket in AWS S3.
#
# Copyright 2021 MarMarAba <mario@marmaraba.com>
#
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

#######################################
# GLOBAL DEFINITIONS
#######################################

trap "exit ${EXIT_STATUS}" TERM
trap ctrl_c INT
export TOP_PID=$$



#######################################
# What to do when traping CTRL+C.
#
# Shows a message and exits the
# application with 255 status
# using the exit_app() function.
#
#######################################

function ctrl_c() {
  echo 
  log_to_warn "${FUNCNAME[0]}(): Received CTRL+C, exiting..."
  exit_app 255 clean
}


#######################################
# Exit the aplication with order.
#
# Delete the temporal folder, if needed
# and logs the exit cause.
#
# PARAMETERS:
#   exit_status {1}
#   clean_tmp_folder {2}
#
#######################################

function exit_app()
{
  log_to_debug "${FUNCNAME[0]}():"
  EXIT_STATUS=0
  
  [[ -n ${1} ]] && { EXIT_STATUS=${1} ; }
  [[ -n ${2} ]] && { delete_temp_folder ; }
  
  
  if [[ ${LOG_PROFILE} == 1 ]] 
  then
    end_time=`date +%s`
    run_time=$((end_time-start_time))
    log_to_info "PROFILING: '${BACKUP_NAME}' backup finished in ${run_time} seconds" force
  fi

  log_to_debug "${FUNCNAME[0]}(): Exiting application with status code ${EXIT_STATUS}"
  
  kill -s TERM $TOP_PID
  
}


#######################################
# Set the defaults for global 
# variables, load the MAIN_CONF_FILE
# variables if the file exists, load
# CONFIG_FILE variables if the option
# is passed in command line arguments,
# parse command line options and 
# update the appropriate global
# variables, and check if the mandatory
# variables are set.
#
# VARIABLES:
#   Almost all...
# RETURN:
#   0 if operations succeeds, non-zero 
#   on error.
#######################################

function load_configuration() {
  # Set defaults
  LOG_LEVEL=info
  SYS_TMP_DIR=/tmp
  MAIN_CONF_FILE="/etc/bjackup/main.conf"
  LOG_PROFILE=0
  MAINTAIN_TMP_DATA=0
  
  TMP_DIR_TEMPLATE="bjackup-job-"
  PURGE_TMP_DIRS=0
  
  # Load main.conf file if exists
  [[ -e "${MAIN_CONF_FILE}" ]] && { source ${MAIN_CONF_FILE} ; }
  
  # Save args
  ARGS=( "$@" )
  
  while [[ $# -gt 0 ]]
  do
    key="$1"
    case $key in
        -h|--help)
        usage
        return 1
        ;;
        -c|--config-file)
        [[ -z "${2}" ]] && return 1
        config_file=${2}
        [[ ! -e ${config_file} ]] && 
          { log_to_error "${FUNCNAME[0]}(): Unable to locate config file at ${config_file}"; return 1; }
        shift 2 
        ;;
        *)    # unknown option
        shift 1
        ;;
    esac
  done
  
  # Load config file options
  [[ -e "${config_file}" ]] && { source ${config_file} ; }
  
  # Restore args
  set -- "${ARGS[@]}"
  
  while [[ $# -gt 0 ]]
  do
    key="$1"

    case $key in
        -h|--help)
          usage
          return 1
        ;;
        -p|--purge-tmp-dirs)
          PURGE_TMP_DIRS=1
          shift 1
        ;;
        -c|--config-file)
          shift 2
        ;;
        -l|--log-level)
          [[ -z "${2}" ]] && return 1
          LOG_LEVEL=${2}
          shift 2 
        ;;
        -m)
          MAINTAIN_TMP_DATA=1
          shift 1
        ;;
        -v)
          LOG_LEVEL=WARN
          shift 1
        ;;
        -vv)
          LOG_LEVEL=INFO
          shift 1
        ;;
        -vvv)
          LOG_LEVEL=DEBUG
          shift 1
        ;;
        -t|--time)
          LOG_PROFILE=1
          shift 1
        ;;
        --backup-folders)
          [[ -z "${2}" ]] && return 1
          IFS=',' read -ra BACKUP_FOLDERS <<< "${2}"
          shift 2
        ;;
        --storage-protocol)
          [[ -z "${2}" ]] && return 1
          STORAGE_PROTOCOL=${2,,}
          shift 2
        ;;
        --storage-host)
          [[ -z "${2}" ]] && return 1
          STORAGE_HOST=${2}
          shift 2
        ;;
        --storage-port)
          [[ -z "${2}" ]] && return 1
          STORAGE_PORT=${2}
          shift 2 
        ;;
        --storage-user)
          [[ -z "${2}" ]] && return 1
          STORAGE_USER=${2}
          shift 2 
        ;;
        --storage-pass)
          [[ -z "${2}" ]] && return 1
          STORAGE_PASS=${2}
          shift 2 
        ;;
        --db-protocol)
          [[ -z "${2}" ]] && return 1
          DB_PROTOCOL=${2}
          shift 2 
        ;;
        --db-host)
          [[ -z "${2}" ]] && return 1
          DB_HOST=${2}
          shift 2 
        ;;
        --db-host)
          [[ -z "${2}" ]] && return 1
          DB_HOST=${2}
          shift 2 
        ;;
        --db-port)
          [[ -z "${2}" ]] && return 1
          DB_PORT=${2}
          shift 2 
        ;;
        --db-user)
          [[ -z "${2}" ]] && return 1
          DB_USER=${2}
          shift 2 
        ;;
        --db-pass)
          [[ -z "${2}" ]] && return 1
          DB_PASS=${2}
          shift 2 
        ;;
        --db-name)
          [[ -z "${2}" ]] && return 1
          DB_NAME=${2}
          shift 2 
        ;;
        --sys-tmp-dir)
          [[ -z "${2}" ]] && return 1
          SYS_TMP_DIR=${2}
          shift 2 
        ;;
        *)    # unknown option
        echo
        echo ERROR: ${1}: Opción no reconocida.
        return 1
        ;;
    esac
  done
  
  if  [[ ${LOG_LEVEL,,} != fatal ]] &&
      [[ ${LOG_LEVEL,,} != error ]] &&
      [[ ${LOG_LEVEL,,} != warn ]] &&
      [[ ${LOG_LEVEL,,} != info ]] &&
      [[ ${LOG_LEVEL,,} != debug ]] &&
      [[ -n ${LOG_LEVEL} ]]
  then
    log_to_warn "\"${LOG_LEVEL}\" in not valid log level. Changing to \"debug\""
    LOG_LEVEL=debug
  fi
  
  [[ ${PURGE_TMP_DIRS} == 1 ]] && { purge_temp_folders ; exit_app 0 ; }
  
  {
    { [[ -z "${DB_PROTOCOL}" ]] && log_to_warn "${FUNCNAME[0]}(): The config parameter \${DB_PROTOCOL} is mandatory"; } ||
    { [[ -z "${STORAGE_PROTOCOL}" ]] && log_to_warn "${FUNCNAME[0]}(): The config parameter \${STORAGE_PROTOCOL} is mandatory"; } ||
    { [[ -z "${BACKUP_NAME}" ]] && log_to_warn "${FUNCNAME[0]}(): The config parameter \${BACKUP_NAME} is mandatory"; } ||
    false 
  } &&
  { usage && log_to_error "${FUNCNAME[0]}(): Check your configuration." force && return 1; }
  
  return 0
}


#######################################
# Create a file in TMP_DIR with the 
# backup used config.
#
# VARIABLES:
#   Almost all...
#   TMP_DIR (mandatory)
# RETURN:
#   0
#######################################

save_current_config_to_tmp_dir(){
  log_to_debug "${FUNCNAME[0]}():"
  
  echo "## Configuration file for $0" >> ${TMP_DIR}/used_config.conf ;
  echo "" >> ${TMP_DIR}/used_config.conf ;
  echo "# Created on $(date -Ins)" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${BACKUP_NAME} ]] && echo "BACKUP_NAME=${BACKUP_NAME}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${BACKUP_FOLDERS} ]] && echo "BACKUP_FOLDERS=${BACKUP_FOLDERS}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${STORAGE_PROTOCOL} ]] && echo "STORAGE_PROTOCOL=${STORAGE_PROTOCOL}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${STORAGE_HOST} ]] && echo "STORAGE_HOST=${STORAGE_HOST}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${STORAGE_PORT} ]] && echo "STORAGE_PORT=${STORAGE_PORT}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${STORAGE_USER} ]] && echo "STORAGE_USER=${STORAGE_USER}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${STORAGE_PASS} ]] && echo "STORAGE_PASS=${STORAGE_PASS}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${DB_PROTOCOL} ]] && echo "DB_PROTOCOL=${DB_PROTOCOL}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${DB_CONNECTION} ]] && echo "DB_CONNECTION=${DB_CONNECTION}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${DB_HOST} ]] && echo "DB_HOST=${DB_HOST}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${DB_PORT} ]] && echo "DB_PORT=${DB_PORT}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${DB_USER} ]] && echo "DB_USER=${DB_USER}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${DB_PASS} ]] && echo "DB_PASS=${DB_PASS}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${DB_NAME} ]] && echo "DB_NAME=${DB_NAME}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${SSH_TUNNEL_HOST} ]] && echo "SSH_TUNNEL_HOST=${SSH_TUNNEL_HOST}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${SSH_TUNNEL_PORT} ]] && echo "SSH_TUNNEL_PORT=${SSH_TUNNEL_PORT}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${SSH_TUNNEL_USER} ]] && echo "SSH_TUNNEL_USER=${SSH_TUNNEL_USER}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${SSH_TUNNEL_PASS} ]] && echo "SSH_TUNNEL_PASS=${SSH_TUNNEL_PASS}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${PRE_SCRIPT_CMD} ]] && echo "PRE_SCRIPT_CMD=${PRE_SCRIPT_CMD}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${POST_SCRIPT_CMD} ]] && echo "POST_SCRIPT_CMD=${POST_SCRIPT_CMD}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${AWS_CONNECTION_PROFILE} ]] && echo "AWS_CONNECTION_PROFILE=${AWS_CONNECTION_PROFILE}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${AWS_REGION} ]] && echo "AWS_REGION=${AWS_REGION}" >> ${TMP_DIR}/used_config.conf ;
  [[ -n ${AWS_BUCKET} ]] && echo "AWS_BUCKET=${AWS_BUCKET}" >> ${TMP_DIR}/used_config.conf ;
  
  return 0
}


#######################################
# Print usage and exit.
#
# RETURN:
#   0
#######################################

function usage() {
  echo """
  Creates a backup to AWS based on config file contents:

  $0 --config-file|-c <path>


  OPTIONS:
  -l|--log-level <fatal|error|warn|info|debug>
    Sets the logging level for the application (Default: info)
  -v|-vv|-vvv
    Verbosity level
  -p|--purge-tmp-dirs
    Delete all temporal folders and exit
"""
  
  return 0
}


#######################################
# Execute the needed actions to begin 
# backup.
#
# VARIABLES:
#   BACKUP_NAME (mandatory)
#   DB_PROTOCOL (mandatory)
#   TMP_DIR_TEMPLATE (mandatory)
#   TMP_DIR (out)
#   OUTPUT_TAR (out)
#   STORAGE_HOST (out)
# RETURN:
#   0 if succeded, non-zero on error.
#######################################

initialize_backup() {
  log_to_debug "${FUNCNAME[0]}():"
  
  TMP_DIR=$(mktemp -p ${SYS_TMP_DIR} -d -t ${TMP_DIR_TEMPLATE}XXXXXXXXXX)/${BACKUP_NAME}
  OUTPUT_TAR=${TMP_DIR}_$(date +'%Y%m%d_%H%M%S').tar.gz
  
  [[ ${STORAGE_PROTOCOL} == local ]] && { STORAGE_HOST=$(hostname); }
  
  log_to_info "${FUNCNAME[0]}(): Creating temporal directory \"$(dirname ${TMP_DIR})\""
  mkdir -p ${TMP_DIR}/${STORAGE_HOST}
  
  
  if [[ ${DB_PROTOCOL} == wp-config ]]
  then
    storage_download_wp-config
    [[ $? != 0 ]] && return 1
    
    ddbb_read_wp-config
    [[ $? != 0 ]] && return 2
    
    ddbb_test_connection
    [[ $? != 0 ]] && return 3
  fi
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}


#######################################
# Compress the TMP_DIR contents into
# OUTPUT_TAR file.
#
# VARIABLES:
#   OUTPUT_TAR (mandatory)
#   BACKUP_NAME (mandatory)
#   TMP_DIR (mandatory)
# RETURN:
#   0 if succeded, non-zero on error.
#######################################

pack_backup_contents(){
  log_to_debug "${FUNCNAME[0]}():"
  
  tar cfvz ${OUTPUT_TAR} -C $(dirname ${TMP_DIR}) ${BACKUP_NAME} > /dev/null
  ret_value=$?
  [[ ${ret_value} != 0 ]] && 
    { 
      log_to_error "${FUNCNAME[0]}(): tar command exited with non zero status"
      log_to_error "${FUNCNAME[0]}(): Check ${OUTPUT_TAR} output file"
      return ${ret_value}
    }
    
  log_to_info "${FUNCNAME[0]}(): Created output file: ${OUTPUT_TAR}: OK"
  return 0
}


#######################################
# Delete TMP_DIR contents from the
# system, unless MAINTAIN_TMP_DATA
# is set to 1.
#
# VARIABLES:
#   OUTPUT_TAR (mandatory)
#   BACKUP_NAME (mandatory)
#   TMP_DIR (mandatory)
# RETURN:
#   0 if succeded, non-zero on error.
#######################################

delete_temp_folder(){
  log_to_debug "${FUNCNAME[0]}():"
  
  [[ ${MAINTAIN_TMP_DATA} == 1 ]] && 
    { 
      log_to_warn "${FUNCNAME[0]}(): Not deleting temporal data [$(dirname ${TMP_DIR})]."; 
      log_to_warn "${FUNCNAME[0]}(): Use '${0} --purge-tmp-dirs' to delete it (and all other existing ones)."; 
      return 0; 
    }
  
  [[ -n ${TMP_DIR} ]] && [[ -e $(dirname ${TMP_DIR}) ]] && { rm -rf $(dirname ${TMP_DIR}) ; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}


#######################################
# Delete all temporal directories 
# based on SYS_TMP_DIR and
# TMP_DIR_TEMPLATE variables, unless 
# MAINTAIN_TMP_DATA is not set to 1.
#
# VARIABLES:
#   OUTPUT_TAR (mandatory)
#   BACKUP_NAME (mandatory)
#   TMP_DIR (mandatory)
# RETURN:
#   0 if succeded, non-zero on error.
#######################################

purge_temp_folders(){
  log_to_debug "${FUNCNAME[0]}():"
  
  [[ -e ${SYS_TMP_DIR} ]] && {
    for cur_folder in $(ls -d ${SYS_TMP_DIR}/${TMP_DIR_TEMPLATE}* 2> /dev/null)
    do
      log_to_warn "${FUNCNAME[0]}(): Deleting ${cur_folder}" 
      rm -rf ${cur_folder} 
    done
  }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}

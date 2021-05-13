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
# Dummy debugging function.
# 
# RETURN:
#   Zero.
#######################################

function storage_test_connection_disabled(){
  log_to_debug "${FUNCNAME[0]}():"
  return 0
}



#######################################
# Check if BACKUP_FOLDERS exist in
# remote SFTP server location.
# 
# PARAMETERS:
#   remote_folder {1} (mandatory)
# VARIABLES:
#   STORAGE_HOST (mandatory)
#   STORAGE_PORT (mandatory)
#   STORAGE_USER (mandatory)
#   STORAGE_PASS
#   STORAGE_PROTOCOL
# RETURN:
#   Zero if the contents could be
#   found. Non zero on error.
#######################################

function storage_test_connection_sftp(){
  log_to_debug "${FUNCNAME[0]}():"
  
  [[ -n ${STORAGE_PASS} ]] && { log_to_warn "${FUNCNAME[0]}(): STORAGE_PROTOCOL(SFTP): SFTP only allows public key authentication. STORAGE_PASS wont be used."; }
  
  sftp_command="sftp  -oStrictHostKeyChecking=no -P ${STORAGE_PORT} -b - ${STORAGE_USER}@${STORAGE_HOST}"
  echo "ls ${remote_folder}" | ${sftp_command} > /dev/null  
  [[ $? != 0 ]] && { log_to_error "${FUNCNAME[0]}(): STORAGE_PROTOCOL(SFTP): Could not find backup folder [${remote_folder}]."; return 1; }

  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}



#######################################
# Check if BACKUP_FOLDERS exist in
# remote FTP server location.
# 
# PARAMETERS:
#   remote_folder {1} (mandatory)
# VARIABLES:
#   STORAGE_HOST (mandatory)
#   STORAGE_PORT (mandatory)
#   STORAGE_USER (mandatory)
#   STORAGE_PASS (mandatory)
#   STORAGE_PROTOCOL
# RETURN:
#   Zero if the contents could be
#   found. Non zero on error.
#######################################

function storage_test_connection_ftp(){
  log_to_debug "${FUNCNAME[0]}():"
  remote_folder=${1}
  
  [[ -z ${STORAGE_USER} || -z ${STORAGE_PASS} ]] && 
    { log_to_error "${FUNCNAME[0]}(): STORAGE_PROTOCOL(FTP): FTP protocol requires username and password."; return 1; }
  
  wget --quiet --spider "ftp://${STORAGE_USER}:${STORAGE_PASS}@${STORAGE_HOST}:${STORAGE_PORT}/${remote_folder}/"
  [[ $? != 0 ]] && { log_to_error "${FUNCNAME[0]}(): STORAGE_PROTOCOL(FTP): Could not find backup folder [${remote_folder}]."; return 2; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}



#######################################
# Check if BACKUP_FOLDERS exist in
# directory tree.
# 
# PARAMETERS:
#   remote_folder {1} (mandatory)
# VARIABLES:
#   STORAGE_PROTOCOL
# RETURN:
#   Zero if the contents could be
#   found. Non zero on error.
#######################################

function storage_test_connection_local(){
  log_to_debug "${FUNCNAME[0]}():"
  remote_folder=${1}
  
  ls ${remote_folder} > /dev/null 2>&1
  [[ $? != 0 ]] && { log_to_error "${FUNCNAME[0]}(): STORAGE_PROTOCOL(LOCAL): Could not find backup folder [${remote_folder}].";  return 1; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}



#######################################
# Calls the apropiate test connection 
# function based on STORAGE_PROTOCOL
# variable.
#
# Interface transactional function.
# 
# VARIABLES:
#   STORAGE_PROTOCOL (mandatory)
# RETURN:
#   Returns the value returned by the 
#   underlaying function.
#######################################

function storage_test_connection(){
  log_to_debug "${FUNCNAME[0]}(${STORAGE_PROTOCOL}):"
  
  for cur_folder in "${BACKUP_FOLDERS[@]}"
  do
    storage_test_connection_${STORAGE_PROTOCOL} ${cur_folder}    
    ret_value=$?
    [[ ${ret_value} != 0 ]] && { log_to_error "${FUNCNAME[0]}(): Testing ${STORAGE_PROTOCOL} storage connection"; return ${ret_value}; }
  done
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}


#######################################
# Dummy debugging function.
# 
# RETURN:
#   Zero.
#######################################

function storage_download_content_disabled(){
  log_to_debug "${FUNCNAME[0]}():"
  return 0
}



#######################################
# Copies the contents of the origin
# path received as first argument from
# remote SFTP location, defined as 
# global config, to the 
# OUTPUT_STORAGE_PATH.
# 
# PARAMETERS:
#   origin_path {1} (mandatory)
#   origin_filename {2}
#     Given if origin is a file, instead 
#     of a folder.
# VARIABLES:
#   OUTPUT_STORAGE_PATH (mandatory)
#   STORAGE_HOST (mandatory)
#   STORAGE_PORT (mandatory)
#   STORAGE_USER (mandatory)
#   STORAGE_PROTOCOL
# RETURN:
#   Zero if the contents could be
#   correctly copied. Non zero on
#   error.
#######################################

function storage_download_content_sftp(){
  log_to_debug "${FUNCNAME[0]}('${1}','${2}'):"
  origin_path=${1}
  [[ -n ${2} ]] && { origin_path=${1}/${2}; }
  
  sftp -r -q -P ${STORAGE_PORT} ${STORAGE_USER}@${STORAGE_HOST}:${origin_path} ${OUTPUT_STORAGE_PATH} > /dev/null
  [[ $? != 0 ]] && return 1
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}



#######################################
# Copies the contents of the origin
# path received as first argument from
# remote FTP location, defined as 
# global config, to the 
# OUTPUT_STORAGE_PATH.
# 
# PARAMETERS:
#   origin_path {1} (mandatory)
#   origin_filename {2}
#     Given if origin is a file, instead 
#     of a folder.
# VARIABLES:
#   OUTPUT_STORAGE_PATH (mandatory)
#   STORAGE_HOST (mandatory)
#   STORAGE_PORT (mandatory)
#   STORAGE_USER (mandatory)
#   STORAGE_PASS (mandatory)
#   STORAGE_PROTOCOL
# RETURN:
#   Zero if the contents could be
#   correctly copied. Non zero on
#   error.
#######################################

function storage_download_content_ftp(){
  log_to_debug "${FUNCNAME[0]}('${1}','${2}'):"

  [[ -z ${2} ]] && 
    { wget_cmd="wget --quiet --directory-prefix=${OUTPUT_STORAGE_PATH} --mirror "; origin_path=${1}; } ||
    { wget_cmd="wget --quiet --directory-prefix=${OUTPUT_STORAGE_PATH} "; origin_path=${1}/${2}; } 
  
  ${wget_cmd} "ftp://${STORAGE_USER}:${STORAGE_PASS}@${STORAGE_HOST}:${STORAGE_PORT}/${origin_path}"
  [[ $? != 0 ]] && { log_to_error "${FUNCNAME[0]}(): STORAGE_PROTOCOL(${STORAGE_PROTOCOL}): Could not download FTP contents"; return 1; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}



#######################################
# Copies the contents of the origin
# path received as first argument
# to the OUTPUT_STORAGE_PATH.
# 
# PARAMETERS:
#   origin_path {1} (mandatory)
#   origin_filename {2}
#     Given if origin is a file, instead 
#     of a folder.
# VARIABLES:
#   OUTPUT_STORAGE_PATH (mandatory)
#   STORAGE_PROTOCOL
# RETURN:
#   Zero if the contents could be
#   correctly copied. Non zero on
#   error.
#######################################

function storage_download_content_local('${1}','${2}'){
  log_to_debug "${FUNCNAME[0]}():"
  origin_path=${1}
  
  cp -a ${origin_path} ${OUTPUT_STORAGE_PATH}/
  [[ $? != 0 ]] && { log_to_error "${FUNCNAME[0]}(): STORAGE_PROTOCOL(${STORAGE_PROTOCOL}): Could not get contents"; return 1; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}



#######################################
# Calls the apropiate download content 
# function based on STORAGE_PROTOCOL
# variable.
#
# Interface transactional function.
# 
# PARAMETERS:
#   origin_folder {1} (mandatory)
#   origin_filename {2}
#     Filename located into the 
#     origin_folder.
# VARIABLES:
#   STORAGE_PROTOCOL (mandatory)
# RETURN:
#   Returns the value returned by the 
#   underlaying function.
#######################################

function storage_download_content(){
  log_to_debug "${FUNCNAME[0]}('${1}', '${2}'):"
  
  storage_download_content_${STORAGE_PROTOCOL} "${1}" "${2}"
  [[ $? != 0 ]] && { log_to_error "${FUNCNAME[0]}(): Testing ${STORAGE_PROTOCOL} storage connection"; return 1; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}



#######################################
# Calls the download content function
# for each folder in BACKUP_FOLDERS
# variable.
# 
# VARIABLES:
#   BACKUP_FOLDERS (mandatory)
#   TMP_DIR (mandatory)
#   STORAGE_HOST (mandatory)
#   OUTPUT_STORAGE_PATH (out)
# RETURN:
#   Returns the value returned by the 
#   underlaying function.
#######################################

function storage_download_contents(){
  log_to_debug "${FUNCNAME[0]}():"
  OUTPUT_STORAGE_PATH="${TMP_DIR}/${STORAGE_HOST}"
  
  for cur_folder in "${BACKUP_FOLDERS[@]}"
  do
    storage_download_content "$cur_folder"
  done
  
  log_to_info "${FUNCNAME[0]}(): $(du -sh ${TMP_DIR}/${STORAGE_HOST} | cut -f 1) received: OK"
  return 0
}


#######################################
# Downloads wp-config.php file.
#
# Search in all remote backup folders
# given in BACKUP_FOLDERS variable for 
# the wp-config file.
#
# If is found it is downloaded and 
# the variable WP_CONFIG_PATH is set
# to its local location.
#
# VARIABLES:
#    BACKUP_FOLDERS (mandatory)
#    TMP_DIR (mandatory)
#    WP_CONFIG_PATH (out)
# RETURN:
#   Zero if the file is correctly
#   downloaded. Non zero in other
#   case.
#######################################

function storage_download_wp-config(){
  log_to_debug "${FUNCNAME[0]}():"
  OUTPUT_STORAGE_PATH="${TMP_DIR}"
  
  for cur_folder in "${BACKUP_FOLDERS[@]}"
  do
    storage_download_content "${cur_folder}" "wp-config.php"
    if [[ $? != 0 ]] 
    then
      log_to_warn "${FUNCNAME[0]}(): Unable to locate wp-config.php at ${cur_folder} remote folder"
    else
      WP_CONFIG_PATH="${OUTPUT_STORAGE_PATH}/wp-config.php"
      log_to_info "${FUNCNAME[0]}(): OK"
      return 0
    fi
  done
  
  log_to_error "${FUNCNAME[0]}(): Unable to find wp-config.php"
  return 1
}



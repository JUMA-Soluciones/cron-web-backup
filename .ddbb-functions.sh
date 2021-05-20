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
#
# LOAD SUB-MODULES
#
#######################################

source .ddbb-functions_mysql.sh
source .ddbb-functions_postgres.sh


#######################################
# Dummy debugging function.
#
# RETURN:
#   Zero.
#######################################

ddbb_test_connection_disabled_(){
  log_to_debug "${FUNCNAME[0]}():"
  return 0
}



#######################################
# Dummy debugging function.
#
# RETURN:
#   Zero.
#######################################


ddbb_test_connection_disabled_storage-tunnel(){
  log_to_debug "${FUNCNAME[0]}():"
  return 0
}

#######################################
# Dummy debugging function.
#
# RETURN:
#   Zero.
#######################################

ddbb_test_connection_wp-config(){
  log_to_debug "${FUNCNAME[0]}():"
  return 0
}


#######################################
# Calls the apropiate ddbb test 
# function based on DB_PROTOCOL
# variable.
#
# Interface transactional function.
# 
# VARIABLES:
#   DB_PROTOCOL (mandatory)
# RETURN:
#   Returns the value returned by the 
#   underlaying function.
#######################################

ddbb_test_connection(){
  log_to_debug "${FUNCNAME[0]}(${DB_PROTOCOL}):"

  [[ ${DB_PROTOCOL} == wp-config ]] && return 0
  
  ddbb_test_connection_${DB_PROTOCOL}_${DB_CONNECTION}
  ret_value=$?
  [[ ${ret_value} != 0 ]] && { log_to_error "${FUNCNAME[0]}(): Testing DDBB ${DB_PROTOCOL} protocol over ${DB_CONNECTION} connection"; return ${ret_value}; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}



#######################################
# Dummy debugging function.
#
# RETURN:
#   Zero.
#######################################

ddbb_get_contents_disabled_(){
  log_to_debug "${FUNCNAME[0]}():"
  return 0
}



#######################################
# Dummy debugging function.
#
# RETURN:
#   Zero.
#######################################

ddbb_get_contents_disabled_storage-tunnel(){
  log_to_debug "${FUNCNAME[0]}():"
  return 0
}


#######################################
# Calls the apropiate ddbb get contents 
# function based on DB_PROTOCOL
# variable.
#
# Interface transactional function.
# 
# VARIABLES:
#   DB_PROTOCOL (mandatory)
# RETURN:
#   Returns the value returned by the 
#   underlaying function.
#######################################

ddbb_get_contents() {
  log_to_debug "${FUNCNAME[0]}():"
  
  ddbb_get_contents_${DB_PROTOCOL}_${DB_CONNECTION}
  ret_value=$?
  [[ ${ret_value} != 0 ]] && { log_to_error "${FUNCNAME[0]}(): Getting DDBB contents, ${DB_PROTOCOL} protocol over ${DB_CONNECTION} connection"; return ${ret_value}; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}



#######################################
# Parse the wp-config.php file.
#
# wp-config.php file location must be
# stored in WP_CONFIG_PATH variable.
#
# By default, WordPress uses mysql
# database, so DB_PROTOCOL is changed
# to use this protocol.
# 
# VARIABLES:
#   WP_CONFIG_PATH (mandatory)
#   DB_HOST (out)
#   DB_PORT (out)
#   DB_NAME (out)
#   DB_PASS (out)
#   DB_PROTOCOL (out)
# RETURN:
#   Return zero if the parse succeds,
#   non-zero if it fails.
#######################################

ddbb_read_wp-config(){
  log_to_debug "${FUNCNAME[0]}():"
  
  DB_HOST=$(cat ${WP_CONFIG_PATH} | grep DB_HOST | cut -d \' -f 4 | cut -d : -f 1)
  DB_PORT=$(cat ${WP_CONFIG_PATH} | grep DB_HOST | cut -d \' -f 4 | cut -d : -f 2)
  DB_NAME=$(cat ${WP_CONFIG_PATH} | grep DB_NAME | cut -d \' -f 4)
  DB_USER=$(cat ${WP_CONFIG_PATH} | grep DB_USER | cut -d \' -f 4)
  DB_PASS=$(cat ${WP_CONFIG_PATH} | grep DB_PASSWORD | cut -d \' -f 4)
  
  ( [[ -z ${DB_PORT} ]] || 
    [[ ${DB_PORT} == ${DB_HOST} ]] 
  ) && { log_to_warn "${FUNCNAME[0]}(): Defaulting DB_PORT to 3306."; DB_PORT=3306; }
  
  ( [[ -z ${DB_HOST} ]] ||
    [[ -z ${DB_PORT} ]] ||
    [[ -z ${DB_NAME} ]] ||
    [[ -z ${DB_USER} ]] ||
    [[ -z ${DB_PASS} ]] 
  ) && { log_to_warn "${FUNCNAME[0]}(): Failed wp-config.php file. Please, check it."; return 1; }
    
  DB_PROTOCOL=mysql
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}

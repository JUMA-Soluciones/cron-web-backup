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

ddbb_test_connection_mysql_disabled(){
  log_to_debug "${FUNCNAME[0]}():"
  return 0
}



#######################################
# Test the connection to DB_HOST using
# mysql system client.
# 
# By default uses global variables
# configuration, but can be overriden
# using parameters.
#
# PARAMETERS:
#   m_db_host {1}
#   m_db_port {2}
#   m_db_user {3}
#   m_db_pass {4}
#   m_db_name {5}
# VARIABLES:
#   DB_HOST (mandatory)
#   DB_PORT (mandatory)
#   DB_USER (mandatory)
#   DB_PASS (mandatory)
#   DB_NAME (mandatory)
# RETURN:
#   Returns the value returned by the 
#   underlaying application.
#######################################

ddbb_test_connection_mysql_direct(){
  log_to_debug "${FUNCNAME[0]}(${1} ${2} ${3} ${5}):"
  
  local m_db_host=${DB_HOST}
  local m_db_port=${DB_PORT}
  local m_db_user=${DB_USER}
  local m_db_pass=${DB_PASS}
  local m_db_name=${DB_NAME}
  [[ -n ${1} ]] && { m_db_host=${1}; }
  [[ -n ${2} ]] && { m_db_port=${2}; }
  [[ -n ${3} ]] && { m_db_user=${3}; }
  [[ -n ${4} ]] && { m_db_pass=${4}; }
  [[ -n ${5} ]] && { m_db_name=${5}; }
  
  mysql --user="${m_db_user}" --password="${m_db_pass}" --host="${m_db_host}" --port=${m_db_port} --database="${m_db_name}" --execute="\q" 2> /dev/null
  local ret_value=$?
  [[ ${ret_value} != 0 ]] && { log_to_error "${FUNCNAME[0]}(): Could not connect to mysql ${m_db_host}:${m_db_port} ${m_db_user} ${m_db_name}" ; return ${ret_value}; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}



#######################################
# Test the connection to STORAGE_HOST
# connection configuration using
# ssh-tunnel test connection function.
#
# VARIABLES:
#   STORAGE_HOST (mandatory)
#   STORAGE_PORT (mandatory)
#   STORAGE_USER (mandatory)
# RETURN:
#   Returns the value returned by the 
#   underlaying function.
#######################################

ddbb_test_connection_mysql_storage-tunnel(){
  log_to_debug "${FUNCNAME[0]}():"
  
  ddbb_test_connection_mysql_ssh-tunnel "${STORAGE_HOST}" "${STORAGE_PORT}" "${STORAGE_USER}"
  local ret_value=$?
  [[ ${ret_value} != 0 ]] && { log_to_error "${FUNCNAME[0]}(): Unable to test DDBB mysql connection"; return ${ret_value}; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}



#######################################
# Test the connection to 
# SSH_TUNNEL_HOST connection 
# configuration using direct test
# connection function.
# 
# By default uses global variables
# configuration, but can be overriden
# using parameters.
#
# PARAMETERS:
#   m_ssh_tunnel_host {1}
#   m_ssh_tunnel_port {2}
#   m_ssh_tunnel_user {3}
# VARIABLES:
#   SSH_TUNNEL_HOST (mandatory)
#   SSH_TUNNEL_PORT (mandatory)
#   SSH_TUNNEL_USER (mandatory)
#   DB_USER (mandatory)
#   DB_PASS (mandatory)
#   DB_NAME (mandatory)
# RETURN:
#   Returns the value returned by the 
#   underlaying function.
#######################################

ddbb_test_connection_mysql_ssh-tunnel(){
  log_to_debug "${FUNCNAME[0]}():"
  
  local m_ssh_tunnel_host=${SSH_TUNNEL_HOST}
  local m_ssh_tunnel_port=${SSH_TUNNEL_PORT}
  local m_ssh_tunnel_user=${SSH_TUNNEL_USER}
  
  [[ -n ${1} ]] && { m_ssh_tunnel_host=${1}; }
  [[ -n ${2} ]] && { m_ssh_tunnel_port=${2}; }
  [[ -n ${3} ]] && { m_ssh_tunnel_user=${3}; }
  
  local local_port=$(get_free_port)
  local redir_config="${m_ssh_tunnel_host} ${m_ssh_tunnel_port} ${m_ssh_tunnel_user} ${local_port} ${DB_HOST} ${DB_PORT}"
  
  open_port_redirection ${redir_config}
  [[ $? != 0 ]] && { log_to_error "${FUNCNAME[0]}(): Could not create port redirection to SSH host"; return 1; }
  
  ddbb_test_connection_mysql_direct "127.0.0.1" ${local_port} ${DB_USER} ${DB_PASS} ${DB_NAME}
  local ret_value=$?
  
  close_port_redirection $redir_config
  
  [[ ${ret_value} != 0 ]] && { log_to_error "${FUNCNAME[0]}(): Unable to test DDBB mysql connection"; return ${ret_value}; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}


#######################################
# Dummy debugging function.
# 
# RETURN:
#   1.
#######################################

ddbb_test_connection_mysql_wp-config(){
  log_to_debug "${FUNCNAME[0]}():"
  log_to_error "${FUNCNAME[0]}(): I should not be here"
  return 1
}



#######################################
# Get the contents from DB_HOST using
# mysql system client.
# 
# By default uses global variables
# configuration, but can be overriden
# using parameters.
#
# PARAMETERS:
#   m_db_host {1}
#   m_db_port {2}
#   m_db_user {3}
#   m_db_pass {4}
#   m_db_name {5}
# VARIABLES:
#   DB_HOST (mandatory)
#   DB_PORT (mandatory)
#   DB_USER (mandatory)
#   DB_PASS (mandatory)
#   DB_NAME (mandatory)
# RETURN:
#   Returns the value returned by the 
#   underlaying application.
#######################################

ddbb_get_contents_mysql_direct(){
  log_to_debug "${FUNCNAME[0]}('${1}', '${2}', '${3}', '${5}'):"
  
  local m_db_host=${DB_HOST}
  local m_db_port=${DB_PORT}
  local m_db_user=${DB_USER}
  local m_db_pass=${DB_PASS}
  local m_db_name=${DB_NAME}
  [[ -n ${1} ]] && { m_db_host=${1}; }
  [[ -n ${2} ]] && { m_db_port=${2}; }
  [[ -n ${3} ]] && { m_db_user=${3}; }
  [[ -n ${4} ]] && { m_db_pass=${4}; }
  [[ -n ${5} ]] && { m_db_name=${5}; }
  
  ddbb_output_file="${TMP_DIR}/${m_db_host}_${m_db_name}.sql"
  mysqldump --user="${m_db_user}" --password="${m_db_pass}" --host="${m_db_host}" --port=${m_db_port} \
    --triggers --routines --events --column-statistics=0 --databases "${m_db_name}" \
    > "${ddbb_output_file}" 2> /dev/null
  local ret_value=$?
  [[ ${ret_value} != 0 ]] && 
    { log_to_error "${FUNCNAME[0]}(): Could not get data from host ${1}:${2} ${3} ${5}"; return ${ret_value}; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}



#######################################
# Get the contents from DB_HOST 
# oppening a local port redirection
# to the remote host database port and
# using it as if it was a direct mysql
# connection.
# 
# By default uses global variables
# configuration, but can be overriden
# using parameters.
#
# PARAMETERS:
#   m_ssh_tunnel_host {1}
#   m_ssh_tunnel_port {2}
#   m_ssh_tunnel_user {3}
# VARIABLES:
#   SSH_TUNNEL_HOST (mandatory)
#   SSH_TUNNEL_PORT (mandatory)
#   SSH_TUNNEL_USER (mandatory)
#   DB_USER (mandatory)
#   DB_PASS (mandatory)
#   DB_NAME (mandatory)
# RETURN:
#   Returns the value returned by the 
#   underlaying function.
#######################################

ddbb_get_contents_mysql_ssh-tunnel(){
  log_to_debug "${FUNCNAME[0]}():"
  
  local m_ssh_tunnel_host=${SSH_TUNNEL_HOST}
  local m_ssh_tunnel_port=${SSH_TUNNEL_PORT}
  local m_ssh_tunnel_user=${SSH_TUNNEL_USER}
  
  [[ -n ${1} ]] && { m_ssh_tunnel_host=${1}; }
  [[ -n ${2} ]] && { m_ssh_tunnel_port=${2}; }
  [[ -n ${3} ]] && { m_ssh_tunnel_user=${3}; }
  
  local local_port=$(get_free_port)
  local redir_config="${m_ssh_tunnel_host} ${m_ssh_tunnel_port} ${m_ssh_tunnel_user} ${local_port} ${DB_HOST} ${DB_PORT}"
  
  open_port_redirection ${redir_config}
  [[ $? != 0 ]] && { log_to_error "${FUNCNAME[0]}(): Could not create port redirection to SSH host"; return 1; }
  
  ddbb_get_contents_mysql_direct "127.0.0.1" "${local_port}" "${DB_USER}" "${DB_PASS}" "${DB_NAME}"
  local ret_value=$?
  
  close_port_redirection $redir_config
  
  [[ "${ret_value}" != "0" ]] && { log_to_error "${FUNCNAME[0]}(): Unable to get DDBB mysql connection"; return ${ret_value}; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0

}



#######################################
# Get the contents from DB_HOST 
# using ssh-tunnel connection
# function.
#
# VARIABLES:
#   STORAGE_HOST (mandatory)
#   STORAGE_PORT (mandatory)
#   STORAGE_USER (mandatory)
# RETURN:
#   Returns the value returned by the 
#   underlaying function.
#######################################

ddbb_get_contents_mysql_storage-tunnel(){
  log_to_debug "${FUNCNAME[0]}():"
  
  ddbb_get_contents_mysql_ssh-tunnel "${STORAGE_HOST}" "${STORAGE_PORT}" "${STORAGE_USER}"
  local ret_value=$?
  [[ ${ret_value} != 0 ]] && { log_to_error "${FUNCNAME[0]}(): Unable to get DDBB contents over mysql connection"; return ${ret_value}; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}


#######################################
# Dummy debugging function.
# 
# RETURN:
#   1.
#######################################

ddbb_get_contents_mysql_wp-config(){
  log_to_debug "${FUNCNAME[0]}():"
  log_to_warn "${FUNCNAME[0]}(): I should not be here"
  return 1
}
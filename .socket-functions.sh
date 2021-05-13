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
# echo a new socket name based on received parameters
#
# VARIABLES:
#   SYS_TMP_DIR (mandatory)
# PARAMETERS:
#   ssh_host {1}
#   ssh_port {2}
#   ssh_user {3}
#   local_port {4}
#   remote_host {5}
#   remote_port {6}
# RETURN:
#   N/A
#######################################

get_control_socket(){
  SOCKET=${SYS_TMP_DIR}/ssh.socket.${1:0:9}_${2}_${3}_${4}_${5:0:9}_${6}
  echo ${SOCKET:0:100}
}


#######################################
# Stablish a port redirection from 
# the local_port to the 
# remote_host:remote_port.
#
# VARIABLES:
#   SYS_TMP_DIR (mandatory)
# PARAMETERS:
#   ssh_host {1}
#   ssh_port {2}
#   ssh_user {3}
#   local_port {4}
#   remote_host {5}
#   remote_port {6}
# RETURN:
#   0 if succeded, non-zero on error.
#######################################

open_port_redirection() {
  log_to_debug "${FUNCNAME[0]}('${1}', '${2}', '${3}', '${4}', '${5}', '${6}'):"
  
  control_socket="$(get_control_socket ${1} ${2} ${3} ${4} ${5} ${6})"
  log_to_debug "${FUNCNAME[0]}('${control_socket}'):"
  
  [[ -e ${control_socket} ]] && 
    { log_to_error "${FUNCNAME[0]}(): The file ${control_socket} already exists."; return 1; }
  
  ssh -f -M -S ${control_socket} -N -L ${4}:${5}:${6} -p ${2} ${3}@${1}
  ret_value=$?
  [[ ${ret_value} != 0 ]] && { log_to_error "${FUNCNAME[0]}(): Could not connect open a socket with: ${1} ${2} ${3} ${4} ${5} ${6}"; return 1; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}


#######################################
# Closes an already opened redirection
# defined in control_socket.
#
# VARIABLES:
#   SYS_TMP_DIR (mandatory)
# PARAMETERS:
#   ssh_host {1}
#   ssh_port {2}
#   ssh_user {3}
#   local_port {4}
#   remote_host {5}
#   remote_port {6}
# RETURN:
#   0 if succeded, non-zero on error.
#######################################

close_port_redirection() {
  log_to_debug "${FUNCNAME[0]}('${1}', '${2}', '${3}', '${4}', '${5}', '${6}'):"
  
  control_socket="$(get_control_socket ${1} ${2} ${3} ${4} ${5} ${6})"
  log_to_debug "${FUNCNAME[0]}('${control_socket}'):"
  
  [[ ! -e ${control_socket} ]] && 
    { log_to_error "${FUNCNAME[0]}(): The file ${control_socket} does not exists."; return 1; }
    
  ssh -O stop -q -S ${control_socket} ${3}@${1}
  ret_value=$?
  [[ ${ret_value} != 0 ]] && { log_to_warn "${FUNCNAME[0]}(): Error closing the control socket."; return ${ret_value}; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}


#######################################
# Get the first free port on system.
#
# VARIABLES:
#   SYS_TMP_DIR (mandatory)
# PARAMETERS:
#   ssh_host {1}
#   ssh_port {2}
#   ssh_user {3}
#   local_port {4}
#   remote_host {5}
#   remote_port {6}
# RETURN:
#   0 if succeded, non-zero on error.
#######################################

get_free_port() {
  read lower_port upper_port < /proc/sys/net/ipv4/ip_local_port_range
  increment=1

  cur_port=${lower_port}
  ip_port_free=$(netstat -tapln 2> /dev/null | grep ":$cur_port" )

  while [[ -n "$ip_port_free" ]]; do
    cur_port=$((cur_port+increment))
    ip_port_free=$(netstat -tapln 2> /dev/null | grep ":$cur_port")
  done

  echo "$cur_port"
  return 0
}
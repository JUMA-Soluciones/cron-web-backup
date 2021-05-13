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
# GLOBAL VARIABLES
#######################################

#######################################
# Parse command line options and 
# update the appropriate global
# variables.
#
# GLOBALS:
# ARGUMENTS:
#   Command line
# OUTPUTS:
#   Assign needed global variables
# RETURN:
#   0 if print succeeds, non-zero 
#   on error.
#######################################


declare -A m_log_levels

m_log_levels['fatal']=1
m_log_levels['error']=2
m_log_levels['warn']=3
m_log_levels['info']=4
m_log_levels['debug']=5


[[ -z ${LOG_LEVEL} ]] && export LOG_LEVEL=debug

function __current_log_level(){
  m_OUTPUT=$(__num_log_level_for ${LOG_LEVEL})
  echo ${m_OUTPUT}
}

function __num_log_level_for(){
  [[ -z ${1} ]] && { echo 0 && return; }
  m_OUTPUT=${m_log_levels["${1,,}"]}
  [[ -z ${m_OUTPUT} ]] && { LOG_LEVEL=debug; m_OUTPUT=5 ; }
  echo ${m_OUTPUT}
}

function __to_log() {
  m_CONFIGURED_NUM_LOG_LEVEL=$(__current_log_level)
  m_GOT_NUM_LOG_LEVEL=$(__num_log_level_for ${1})
  
  m_LEVEL=${1^^}
  
  RED='\033[0;31m'
  L_RED='\033[1;31m'
  ORANGE='\033[0;33m'
  GREEN='\033[0;32m'
  CYAN='\033[0;36m'
  NC='\033[0m'

  if 
    [[ ${m_CONFIGURED_NUM_LOG_LEVEL} -ge ${m_GOT_NUM_LOG_LEVEL} ]] ||
    [[ "${3,,}" == "force" ]]
  then
    [[ ${m_LEVEL} == FATAL ]] && m_LEVEL="${RED}${m_LEVEL}${NC}"
    [[ ${m_LEVEL} == ERROR ]] && m_LEVEL="${L_RED}${m_LEVEL}${NC}"
    [[ ${m_LEVEL} == WARN ]] && m_LEVEL="${ORANGE}${m_LEVEL}${NC}"
    [[ ${m_LEVEL} == INFO ]] && m_LEVEL="${GREEN}${m_LEVEL}${NC}"
    [[ ${m_LEVEL} == DEBUG ]] && m_LEVEL="${CYAN}${m_LEVEL}${NC}"
    printf "${m_LEVEL}: ${2}\n"
  fi
}

function log_to_fatal(){
  __to_log 'fatal' "${1}" "${2}";
}
function log_to_error(){
  __to_log 'error' "${1}" "${2}";
}
function log_to_warn(){
  __to_log 'warn' "${1}" "${2}";
}
function log_to_info(){
  __to_log 'info' "${1}" "${2}";
}
function log_to_debug(){
  __to_log 'debug' "${1}" "${2}";
}

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
# LOAD MODULES
#
#######################################

cd "$(dirname "$0")"

start_time=`date +%s`

source .log-functions.sh
source .general-functions.sh
source .socket-functions.sh
source .shell-functions.sh
source .storage-functions.sh
source .ddbb-functions.sh
source .aws-functions.sh

#######################################
#
# MAIN ALGORYTHM
#
#######################################

load_configuration $@ || exit_app 1
  
[[ ${LOG_PROFILE} == 1 ]] && { log_to_info "PROFILING: Starting backup for '${BACKUP_NAME}'" force ; }

# TEST ENVIRONMENT

storage_test_connection || exit_app 21
ddbb_test_connection || exit_app 22
shell_test_operations || exit_app 23
aws_test_connection || exit_app 24

# INITIALIZATION

initialize_backup || exit_app 31 clean

# BACKUP DATA

shell_exec_pre_script || exit_app 41 clean
storage_download_contents || exit_app 51 clean
ddbb_get_contents || exit_app 52 clean
shell_exec_post_script || exit_app 61 clean
save_current_config_to_tmp_dir || exit_app 71 clean

# PACK AND UPLOAD

pack_backup_contents || exit_app 81 clean
aws_upload_backup_file || exit_app 91 clean

# FINISH APP

delete_temp_folder
exit_app
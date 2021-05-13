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
# Test if a connection to AWS can be
# reached with the given options.
#
# It uses aws-cli v2 to check if
# the given AWS_BUCKET exists.
# 
# VARIABLES:
#   AWS_BUCKET (mandatory)
#   AWS_CONNECTION_PROFILE
#   AWS_REGION
# RETURN:
#   0 if connection succeeds.
#   Non-zero on error or if the buccket
#     does not exist.
#######################################


function aws_test_connection() {
  log_to_debug "${FUNCNAME[0]}():"
  [[ -z ${AWS_BUCKET} ]] && { log_to_error "${FUNCNAME[0]}(): \$AWS_BUCKET is needed"  && return 1 ; }
  
  AWS_S3_TEST_CMD="aws s3api list-buckets"
  if [[ -n  ${AWS_CONNECTION_PROFILE} ]]
  then
    log_to_debug "${FUNCNAME[0]}(): Enabling \"${AWS_CONNECTION_PROFILE}\" profile"
    AWS_S3_TEST_CMD="${AWS_S3_TEST_CMD} --profile ${AWS_CONNECTION_PROFILE}"
  fi
  
  if [[ -n ${AWS_REGION} ]]
  then
    log_to_debug "${FUNCNAME[0]}(): Working on \"${AWS_REGION}\" region"
    AWS_S3_TEST_CMD="${AWS_S3_TEST_CMD} --region ${AWS_REGION}"
  fi
  
  log_to_debug "${FUNCNAME[0]}(): Checking aws-cli"
  ${AWS_S3_TEST_CMD} > /dev/null
  [[ $? -ne 0 ]] && { log_to_error "${FUNCNAME[0]}(): Error al ejecutar '${AWS_S3_TEST_CMD}'" && return 2 ; }
  
  log_to_debug "${FUNCNAME[0]}(): Checking if '${AWS_BUCKET}' bucket exists"
  m_OUTPUT=$(${AWS_S3_TEST_CMD}  --query "Buckets[?Name=='${AWS_BUCKET}']" | wc -l )
  [[ ${m_OUTPUT} -le 1 ]] && { log_to_error "${FUNCNAME[0]}(): '${AWS_BUCKET}' does not exist" && return 3 ; }
  
  log_to_info "${FUNCNAME[0]}(): OK"
  return 0
}



#######################################
# Uploads the TAR backupfile to a AWS 
# bucket.
#
# It uses aws-cli v2 to make the
# operation.
# 
# VARIABLES:
#   AWS_BUCKET (mandatory)
#   BACKUP_NAME (mandatory)
#   LOG_PROFILE (mandatory)
#   AWS_CONNECTION_PROFILE
#   AWS_REGION
#   OUTPUT_TAR
# RETURN:
#   0 if upload succeeds.
#   Non-zero on error or if the buccket
#     does not exist.
#######################################

function aws_upload_backup_file() {
  log_to_debug "${FUNCNAME[0]}():"
  
  AWS_S3_PUT_CMD="aws s3api put-object --bucket ${AWS_BUCKET}"
  if [[ -n  ${AWS_CONNECTION_PROFILE} ]]
  then
    log_to_debug "${FUNCNAME[0]}(): Enabling \"${AWS_CONNECTION_PROFILE}\" profile"
    AWS_S3_PUT_CMD="${AWS_S3_PUT_CMD} --profile ${AWS_CONNECTION_PROFILE}"
  fi
  
  if [[ -n ${AWS_REGION} ]]
  then
    log_to_debug "${FUNCNAME[0]}(): Working on \"${AWS_REGION}\" region"
    AWS_S3_PUT_CMD="${AWS_S3_PUT_CMD} --region ${AWS_REGION}"
  fi
  
  REMOTE_PATH=${BACKUP_NAME}/$(basename ${OUTPUT_TAR})
  log_to_debug "${FUNCNAME[0]}(): Uploading ${OUTPUT_TAR} to ${AWS_BUCKET}/${REMOTE_PATH}"
  
  ${AWS_S3_PUT_CMD} --key ${REMOTE_PATH} --body ${OUTPUT_TAR} > /dev/null 2>&1
  [[ $? -ne 0 ]] && { log_to_error "${FUNCNAME[0]}(): Error when uploading file to AWS" && return 2 ; }
  
  m_MESSAGE="${FUNCNAME[0]}(): Uploaded $(basename ${OUTPUT_TAR}) [$(du -sh ${OUTPUT_TAR} | cut -f 1)] to s3://${AWS_BUCKET}/${BACKUP_NAME}: OK"
  [[ ${LOG_PROFILE} == 1 ]] && { log_to_info "${m_MESSAGE}" force ; } || { log_to_info "${m_MESSAGE}" ; }
  return 0
}





#!/bin/bash

# set -o pipefail
# set -o errexit
# set -o errtrace
# set -o nounset
# set -o xtrace

BACKUP_DIR=${BACKUP_DIR:-/tmp/scstemp}
BOTO_CONFIG_PATH=${BOTO_CONFIG_PATH:-/root/.boto}
GCS_BUCKET=${GCS_BUCKET:-}
GCS_KEY_FILE_PATH=${GCS_KEY_FILE_PATH:-}
MYSQL_HOST=${MYSQL_HOST:-0.0.0.0}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_DB=${MYSQL_DB:-tobackup}
MYSQL_USER=${MYSQL_USER:-root}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-root}
MONGODB_OPLOG=${MONGODB_OPLOG:-true}

backup() {
  # mkdir -p $BACKUP_DIR
  date=$(date "+%Y-%m-%dT%H:%M:%SZ")
  archive_name="backup-$date.tar.gz"

#   cmd_auth_part=""
#   if [[ ! -z $MONGODB_USER ]] && [[ ! -z $MONGODB_PASSWORD ]]
#   then
#     cmd_auth_part="--username=\"$MONGODB_USER\" --password=\"$MONGODB_PASSWORD\""
#   fi

#   cmd_db_part=""
#   if [[ ! -z $MONGODB_DB ]]
#   then
#     cmd_db_part="--db=\"$MONGODB_DB\""
#   fi

#   cmd_oplog_part=""
#   if [[ $MONGODB_OPLOG = "true" ]]
#   then
#     cmd_oplog_part="--oplog"
#   fi

  #cmd="mysql -h\"$MYSQL_HOST\" -P\"$MYSQL_PORT\" $cmd_auth_part $cmd_db_part $cmd_oplog_part --gzip --archive=$BACKUP_DIR/$archive_name"
  #cmd="mysql -h\"$MYSQL_HOST\" -P\"$MYSQL_PORT\" $cmd_auth_part $cmd_db_part $cmd_oplog_part --gzip --archive=$BACKUP_DIR/$archive_name"
  cmd="docker exec some-mysql mysqldump -h${MYSQL_HOST} \
   -P${MYSQL_PORT} \
   -u${MYSQL_USER} \
   -p${MYSQL_PASSWORD} \
   ${MYSQL_DB} | gzip > ${archive_name}"

  echo "$cmd"
  echo "starting to backup MYSQL database host=$MYSQL_HOST port=$MYSQL_PORT"
  eval "$cmd"
}

# upload_to_gcs() {
#   if [[ $GCS_KEY_FILE_PATH != "" ]]
#   then
# cat <<EOF > $BOTO_CONFIG_PATH
# [Credentials]
# gs_service_key_file = $GCS_KEY_FILE_PATH
# [Boto]
# https_validate_certificates = True
# [GoogleCompute]
# [GSUtil]
# content_language = en
# default_api_version = 2
# [OAuth2]
# EOF
#   fi
#   echo "uploading backup archive to GCS bucket=$GCS_BUCKET"
#   gsutil cp $BACKUP_DIR/$archive_name $GCS_BUCKET
# }

err() {
  err_msg="something went wrong on line $(caller)"
  echo $err_msg >&2
}

cleanup() {
  rm $BACKUP_DIR/$archive_name
}

trap err ERR
backup
#upload_to_gcs
#cleanup
echo "backup done!"
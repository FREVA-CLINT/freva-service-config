#!/bin/bash
###############################################
# CREATE a daily backup of the freva database
mkdir -p ${BACKUP_DIR}
backup_f=${BACKUP_DIR}/backup-$(date +%Y%m%d_%H%M%S).sql.gz
n_to_keep=$(echo $NUM_BACKUPS|awk '{print $1-1}')
files_to_keep=$(ls -t ${BACKUP_DIR}/backup-*.sql.gz |head -n ${n_to_keep} 2> /dev/null)
for file in $(ls ${BACKUP_DIR}/backup-*.sql.gz);do
    is_new_file=$(echo ${files_to_keep} |grep $file)
    if [ "x${is_new_file}" = "x" ];then
        rm $file
    fi
done
mysqldump -u root -h localhost -p"${MYSQL_ROOT_PASSWORD}" --all-databases| gzip -c -9 -q > $backup_f

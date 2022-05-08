#!/bin/bash

database=blog
container=db_container
main_backup_dir=./backup/
backup_dir=./backup/json/${database}/$(date +'%d.%m.%Y')
dump_dir=./backup/dump/${database}/$(date +'%d.%m.%Y')
restore_dir=./backup/dump/${database}/05.06.2022
mkdir -p "${backup_dir}"
mkdir -p "${dump_dir}"

#docker exec ${container} mongoexport -d ${database} -c products --out /backup/products.json
#docker cp ${container}:backup/products.json "${backup_dir}"/products.json

# Backup #
docker exec db_container mongodump --db ${database} --out "${dump_dir}"
docker exec db_container mkdir -p ${main_backup_dir}
docker cp ${container}:"${main_backup_dir}" .
#
# # Restore #
# docker cp backup db_container:backup
# docker exec ${container} mongo --quiet ${database} --eval "db.dropDatabase()"
# docker exec db_container mongorestore --db ${database} "${restore_dir}"/${database}

# Backup Seperated json files v1 #
#docker exec ${container} mongo --quiet ${database} --eval "db.getCollectionNames().join('\n')" |
#  while read -r collection; do
#    ##    docker exec ${container} mongoexport -d ${database} -c "$collection" --out "${backup_dir}"/"$collection".json
#    ##    docker cp ${container}:"${backup_dir}"/"$collection".json "${backup_dir}"/"$collection".json
#    echo '[' >"${backup_dir}"/"$collection".json
#    docker exec db_container mongo --quiet blog --eval "db.$collection.find()" | tr '\n' ',' >>"${backup_dir}"/"$collection".json
#    echo ']' >>"${backup_dir}"/"$collection".json
#    ##    sed -i 's/[,{/[{/g' "${backup_dir}"/"$collection".json
#    sed -i 's/},]/}]/g' "${backup_dir}"/"$collection".json
#  done

# Backup Seperated json files  v2#

docker exec ${container} mongo --quiet ${database} --eval "db.getCollectionNames().join('\n')" |
  while read -r collection; do
    echo 'db.'"$collection"'.insertMany(' >"${backup_dir}"/"$collection".json
    docker exec db_container mongosh --quiet blog --eval "db.$collection.find()" >>"${backup_dir}"/"$collection".json
    echo ')' >>"${backup_dir}"/"$collection".json
  done

rm -f backup/json/*/*/.json

#!/bin/bash

export PASSWORD=${1}
export EXPORT_DIR=${2:-~/working/cqrs}
export ACME_HOME=~/.acme.sh
export LOG_FILE=${EXPORT_DIR}/certs.log

URLs=(\*.apim.bjdazure.tech \*.bjdazure.tech api.bjdazure.tech api.ingress.bjdazure.tech)

for url in "${URLs[@]}"; 
do 
    echo "[`date`] - Requesting Certificate for ${url} from Let's Encrypt" | tee -a ${LOG_FILE}
    ${ACME_HOME}/acme.sh --renew -d ${url} --force

    echo "[`date`] - Exporting Certificate ${url} to pfx format" | tee -a ${LOG_FILE}
    ${ACME_HOME}/acme.sh --toPkcs -d ${url} --password ${PASSWORD}

    if [ ! -d ${EXPORT_DIR}/${url} ]
    then
        mkdir -p ${EXPORT_DIR}/${url}
    fi

    expiration_date=`${ACME_HOME}/acme.sh --list -d ${url} | grep -i Le_NextRenewTimeStr | awk -F= '{print $2}'`
    echo "[`date`] - Expiration date for ${url} - ${expiration_date}" | tee -a ${LOG_FILE}

    echo "[`date`] - Coping files to ${url}" | tee -a ${LOG_FILE}
    cp ${ACME_HOME}/${url}_ecc/fullchain.cer ${EXPORT_DIR}/${url}/${url}.cer
    cp ${ACME_HOME}/${url}_ecc/${url}.key ${EXPORT_DIR}/${url}/${url}.key
    cp ${ACME_HOME}/${url}_ecc/${url}.pfx ${EXPORT_DIR}/${url}/${url}.pfx
done

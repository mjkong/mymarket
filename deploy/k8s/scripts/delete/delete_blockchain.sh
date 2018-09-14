#!/bin/sh


if [ "${PWD##*/}" = "create" ];then
    KUBECONFIG_FOLDER=${PWD}/../../kube-config
elif [ "${PWD##*/}" = "scripts" ];then
    KUBECONFIG_FOLDER=${PWD}/../kube-config
else
    echo "Please run the script from 'scripts' or 'scripts/create' folder"
fi

echo $KUBECONFIG_FOLDER

kubectl delete -f ${KUBECONFIG_FOLDER}/chaincode_instantiate.yaml
kubectl delete -f ${KUBECONFIG_FOLDER}/chaincode_install.yaml
kubectl delete -f ${KUBECONFIG_FOLDER}/join_channel.yaml
kubectl delete -f ${KUBECONFIG_FOLDER}/create_channel.yaml
kubectl delete -f ${KUBECONFIG_FOLDER}/peersDeployment.yaml
kubectl delete -f ${KUBECONFIG_FOLDER}/blockchain-services.yaml
kubectl delete -f ${KUBECONFIG_FOLDER}/generateArtifactsJob.yaml
kubectl delete -f ${KUBECONFIG_FOLDER}/createArtifactsJob.yaml
kubectl delete -f ${KUBECONFIG_FOLDER}/createVolume.yaml

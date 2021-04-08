#!/bin/bash

gcloud config set compute/zone europe-west2-c

gcloud compute instances create cks-worker cks-master \
--machine-type=e2-medium \
--image=ubuntu-1804-bionic-v20201014 \
--image-project=ubuntu-os-cloud \
--preemptible \
--resource-policies=shutdown \
--boot-disk-size=50GB

set -e

echo sleeping 60s
sleep 60

# until gcloud compute ssh cks-master --zone=europe-west2-c --command="echo" >/dev/null 2>&1; do echo -n "."; done
# until gcloud compute ssh cks-worker --zone=europe-west2-c --command="echo" >/dev/null 2>&1; do echo -n "."; done

# @TODO: a better way to do this would be to run the scripts with the metadata thing in gcloud and then poll for when that finishes before grabbing the join token and sending it to the worker

curl -s https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/cluster-setup/latest/install_worker.sh | gcloud compute ssh cks-worker -- sudo bash

curl -s https://raw.githubusercontent.com/killer-sh/cks-course-environment/master/cluster-setup/latest/install_master.sh | gcloud compute ssh cks-master -- sudo bash

TOKEN=$(gcloud compute ssh cks-master --command="sudo kubeadm token create --print-join-command --ttl 0")

echo $TOKEN | gcloud compute ssh cks-worker -- sudo bash

gcloud compute ssh cks-master --command="sudo kubectl get nodes"

gcloud compute ssh cks-master --zone=europe-west2-c --command="wget https://github.com/ahmetb/kubectx/releases/download/v0.9.3/kubens; chmod +x kubens; sudo mv kubens /usr/local/bin"
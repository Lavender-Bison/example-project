#!/usr/bin/env bash

# Simple script to set up a short-lived os-login key for the postbuild Ansible step.

# Create an SSH key for the Github Workflow service account we're currently running as.
ssh-keygen -P ""
gcloud compute os-login ssh-keys add --key-file=/home/$USER/.ssh/id_rsa.pub --ttl 10m

# Figure out our service account id.
current=$(gcloud config get-value account)
id=$(gcloud iam service-accounts describe $current --format='value(uniqueId)')
echo "sa_${id}"

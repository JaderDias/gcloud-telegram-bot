#!/bin/sh

./set-project.sh

PROJECT_ID=$(gcloud config get-value project)

gcloud services enable \
    appengine.googleapis.com \
    cloudbuild.googleapis.com \
    cloudfunctions.googleapis.com \
    cloudscheduler.googleapis.com \
    firestore.googleapis.com \
    pubsub.googleapis.com \
    secretmanager.googleapis.com \
    storage.googleapis.com

cd terraform

terraform init

TOKEN=`gcloud secrets versions access latest --secret="telegram-bot-token"`

if [ -z "$TOKEN" ]
then
    printf "paste the telegram bot token: "
    read TOKEN
fi

terraform apply --var "project=$PROJECT_ID" --var "token=$TOKEN"

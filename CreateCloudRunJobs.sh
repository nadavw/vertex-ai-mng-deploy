#!/bin/bash -xv

#A number that will be used for the id of the model deployment
DEPLOY_MODEL_ID=2000

# Create the content for ./model_config_file.sh in the cloned directory : vertex-ai-mng-deploy
MODEL_CONFIG_FILE="./vertex-ai-mng-deploy/model_config_file_$DEPLOY_MODEL_ID.sh"
echo 'MODEL_NAME="stable_diffusion_1_5-unique"' > $MODEL_CONFIG_FILE
echo 'MACHINE_TYPE="n1-standard-8"' >> $MODEL_CONFIG_FILE
echo 'ACCELERATOR_TYPE="nvidia-tesla-p100"' >> $MODEL_CONFIG_FILE

PROJECT=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT" --format="value(projectNumber)")
REGION=us-central1
TIME_ZONE='UTC'
ENDPOINT_NAME="stable-diffusion-endpoint"
DEPLOY_JOB_NAME=deploy-model-$DEPLOY_MODEL_ID
DEPLOY_SCHEDULE="0 7 * * *"
UNDEPLOY_JOB_NAME=undeploy-model-$DEPLOY_MODEL_ID
UN_DEPLOY_SCHEDULE="0 19 * * *"

#create a job for model deploy
gcloud run jobs deploy $DEPLOY_JOB_NAME --region=$REGION --source vertex-ai-mng-deploy \
      --task-timeout=1800 --command "./VxAIMngDelpoy.sh" \
       --args DEPLOY,$ENDPOINT_NAME,$DEPLOY_MODEL_ID --set-env-vars RUN_DEBUG=true,REGION=$REGION

#describe the job created
gcloud run jobs --region=$REGION describe $DEPLOY_JOB_NAME

#create a job for model undeploy
gcloud run jobs deploy $UNDEPLOY_JOB_NAME --region=$REGION --source vertex-ai-mng-deploy \
      --task-timeout=180 --command "./VxAIMngDelpoy.sh" \
      --args UNDEPLOY,$ENDPOINT_NAME,$DEPLOY_MODEL_ID --set-env-vars RUN_DEBUG=true,REGION=$REGION

#describe the job created
gcloud run jobs --region=$REGION describe $UNDEPLOY_JOB_NAME

#create a schedule for deploy
gcloud scheduler jobs create http scheduler-$DEPLOY_JOB_NAME \
  --location $REGION \
  --schedule="$DEPLOY_SCHEDULE" --time-zone=$TIME_ZONE \
  --uri="https://$REGION-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/$PROJECT/jobs/$DEPLOY_JOB_NAME:run" \
  --http-method POST \
  --oauth-service-account-email "$PROJECT_NUMBER"-compute@developer.gserviceaccount.com

#create a schedule for undeploy
gcloud scheduler jobs create http scheduler-$DEPLOY_JOB_NAME \
  --location $REGION \
  --schedule="$UN_DEPLOY_SCHEDULE" --time-zone=$TIME_ZONE \
  --uri="https://$REGION-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/$PROJECT/jobs/$DEPLOY_JOB_NAME:run" \
  --http-method POST \
  --oauth-service-account-email "$PROJECT_NUMBER"-compute@developer.gserviceaccount.com




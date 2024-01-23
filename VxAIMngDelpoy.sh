#!/bin/bash

echo RUN_DEBUG:"${RUN_DEBUG}"

if [ "${RUN_DEBUG}" = "true" ]; then
    # Enable the following options if RUN_DEBUG is true
    set -euxo pipefail
else
   set -euo pipefail
    # Handle the case when RUN_DEBUG is not set or set to a value other than "true"
    echo "Debugging is not enabled. Continuing without additional options."
fi


CLOUD_RUN_TASK_INDEX=${CLOUD_RUN_TASK_INDEX:=0}
CLOUD_RUN_TASK_ATTEMPT=${CLOUD_RUN_TASK_ATTEMPT:=0}

echo "Starting Task #${CLOUD_RUN_TASK_INDEX}, Attempt #${CLOUD_RUN_TASK_ATTEMPT}..."


echo "Number of parameters: $#"
echo "Script name: $0"
echo "$@"


ACTION=$1
if [ "$ACTION" != "DEPLOY" ] && [ "$ACTION" != "UNDEPLOY" ] ; then
    echo "No valid action specified. Exiting script."
    exit 1
fi

# Define variables
REGION=us-central1
ENDPOINT_ID=100
ENDPOINT_NAME="stable-diffusion-endpoint"
DEPLOY_MODEL_ID=1234
MODEL_NAME="stable_diffusion_1_5-unique"
MACHINE_TYPE="n1-standard-8"
ACCELERATOR_TYPE="nvidia-tesla-p100"

# Get the model ID
MODEL_ID=$(gcloud ai models list --region=$REGION --filter="DISPLAY_NAME:$MODEL_NAME" --format="value(MODEL_ID)")

# Check if the model ID is empty
if [ -z "$MODEL_ID" ]; then
  echo "Error: Model ID not found. Exiting script."
  exit 1
fi

if [ "$ACTION" == "DEPLOY" ]; then
  # Endpoint creation
  echo "Creating endpoint..."
  gcloud ai endpoints create --region=$REGION --endpoint-id=$ENDPOINT_ID --display-name=$ENDPOINT_NAME
  if [ $? -ne 0 ]; then
    echo "Error: Endpoint creation failed. Exiting script."
    exit 1
  fi

  # Model deploy (takes time)
  echo "Deploying model..."
  gcloud ai endpoints deploy-model $ENDPOINT_ID --region=$REGION --model=$MODEL_ID --display-name=$MODEL_NAME --machine-type=$MACHINE_TYPE --accelerator=count=1,type=$ACCELERATOR_TYPE --deployed-model-id=$DEPLOY_MODEL_ID
  if [ $? -ne 0 ]; then
    echo "Error: Model deployment failed. Exiting script."
    exit 1
  fi
fi

if [ "$ACTION" == "UNDEPLOY" ]; then
  # Model undeploy
  echo "Undeploying model..."
  gcloud ai endpoints undeploy-model $ENDPOINT_ID --region=$REGION --deployed-model-id=$DEPLOY_MODEL_ID
  if [ $? -ne 0 ]; then
    echo "Error: Model undeployment failed. Exiting script."
    exit 1
  fi

  # Endpoint deletion
  echo "Deleting endpoint..."
  gcloud ai endpoints delete $ENDPOINT_ID --region=$REGION --project=nadav-playground
  if [ $? -ne 0 ]; then
    echo "Error: Endpoint deletion failed. Exiting script."
    exit 1
  fi
fi


echo "Script completed successfully."
exit 0

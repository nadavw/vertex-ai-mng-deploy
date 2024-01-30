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

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 ACTION(DEPLOY/UNDEPLOY) ENDPOINT_NAME, MODEL_NAME"
    exit 1
fi

ACTION=$1
if [ "$ACTION" != "DEPLOY" ] && [ "$ACTION" != "UNDEPLOY" ] ; then
    echo "No valid action (DEPLOY/UNDEPLOY) specified in \$1. Exiting script."
    exit 1
fi

ENDPOINT_NAME=$2
# Get the endpoint ID
#ENDPOINT_ID=$(gcloud ai endpoints list --region=$REGION --format="value(ENDPOINT_ID)")
ENDPOINT_ID=$(gcloud ai endpoints list --region="$REGION" --filter="DISPLAY_NAME:$ENDPOINT_NAME" --format="value(ENDPOINT_ID)")
# Check if the $ENDPOINT_ID is empty
if [ -z "$ENDPOINT_ID" ]; then
  echo "Error: ENDPOINT ID not found for ENDPOINT_NAME $ENDPOINT_NAME . Exiting script."
  exit 1
fi

MODEL_NAME=$3
if [ -z "$MODEL_NAME" ]; then
    echo "The ARG MODEL_NAME is empty."
    exit 1
fi

#PROJECT=$(gcloud config get-value project)
if [ -n "$REGION" ]; then
    echo "REGION is set to: $REGION"
else
    REGION="us-central1"
    echo "REGION was not set. Setting it to default: $REGION"
fi

if [ "$ACTION" == "DEPLOY" ]; then
  # Model deploy (takes time)
  MACHINE_TYPE=$4
  ACCELERATOR_TYPE=$5
  # Get the model ID
  MODEL_ID=$(gcloud ai models list --region=$REGION --filter="DISPLAY_NAME:$MODEL_NAME" --format="value(MODEL_ID)")

  echo "Deploying model..."
  gcloud ai endpoints deploy-model "$ENDPOINT_ID" --region=$REGION --model="$MODEL_ID" --display-name="$MODEL_NAME"\
   --machine-type="$MACHINE_TYPE" --accelerator=count=1,type="$ACCELERATOR_TYPE"
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    echo "Error: Model deployment failed. Exiting script."
    exit 1
  fi
fi

if [ "$ACTION" == "UNDEPLOY" ]; then
  # Model undeploy
  echo "Un-deploying model..."
  DEPLOY_MODEL_ID=$(gcloud ai endpoints describe "$ENDPOINT_ID" --region=$REGION \
   --format=json | jq --arg ml_name "$MODEL_NAME" -r '.deployedModels[] | select(.displayName == $ml_name).id')

    gcloud ai endpoints undeploy-model "$ENDPOINT_ID" --region=$REGION --deployed-model-id="$DEPLOY_MODEL_ID"
fi

gcloud ai endpoints describe "$ENDPOINT_ID" --region=$REGION

echo "Script completed successfully."
exit 0

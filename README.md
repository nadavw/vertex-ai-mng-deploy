# MngModelDeploy.sh

This script automates the deployment and un-deployment of a machine learning model on Google Cloud AI Platform (Vertex AI). It takes care of deploying and un-deploying a specified model to a designated endpoint, utilizing Google Cloud services. The script is designed to be used in a Cloud Run job, scheduled using Google Cloud Scheduler.

## Usage

```bash
./MngModelDeploy.sh ACTION ENDPOINT_NAME MODEL_NAME [MACHINE_TYPE] [ACCELERATOR_TYPE]
```

- `ACTION`: Specify the action to perform, either "DEPLOY" or "UNDEPLOY".
- `ENDPOINT_NAME`: The name of the AI Platform (Vertex AI) endpoint.
- `MODEL_NAME`: The name of the model to deploy or undeploy.
- `MACHINE_TYPE` (optional): The machine type to use for model deployment. Required only for the "DEPLOY" action.
- `ACCELERATOR_TYPE` (optional): The accelerator type to use for model deployment. Required only for the "DEPLOY" action.

## Prerequisites

- Google Cloud SDK is required for authentication and interacting with Google Cloud services. Make sure it's installed and configured.

## Environment Variables

- `RUN_DEBUG`: Set to "true" to enable debugging options in the script.
- `REGION`: Specify the Google Cloud region. If not set, it defaults to "us-central1".

## Examples

### Deploy Model

```bash
./MngModelDeploy.sh DEPLOY my_endpoint my_model_name g2-standard-8 nvidia-l4
```

### Undeploy Model

```bash
./MngModelDeploy.sh UNDEPLOY my_endpoint my_model_name
```

## Cloud Run Job Deployment

This script is intended to be used as part of a Cloud Run job for automated deployment and un-deployment. The job is scheduled using Google Cloud Scheduler.

### Job Deployment

```bash
gcloud run jobs deploy deploy-model-my_model_name --region=us-central1 --source vertex-ai-mng-deploy \
    --task-timeout=1800 --command "./MngModelDeploy.sh" \
    --args DEPLOY,my_endpoint,my_model_name,g2-standard-8,nvidia-l4 \
    --set-env-vars RUN_DEBUG=true,REGION=us-central1
```

### Job Un-deployment

```bash
gcloud run jobs deploy undeploy-model-my_model_name --region=us-central1 --source vertex-ai-mng-deploy \
    --task-timeout=180 --command "./MngModelDeploy.sh" \
    --args UNDEPLOY,my_endpoint,my_model_name --set-env-vars RUN_DEBUG=true,REGION=us-central1
```

### Schedule Deployment

```bash
gcloud scheduler jobs create http scheduler-deploy-model-my_model_name \
    --location us-central1 --schedule="0 7 * * *" --time-zone=UTC \
    --uri="https://us-central1-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/YOUR_PROJECT_ID/jobs/deploy-model-my_model_name:run" \
    --http-method POST \
    --oauth-service-account-email YOUR_PROJECT_NUMBER-compute@developer.gserviceaccount.com
```

### Schedule Un-deployment

```bash
gcloud scheduler jobs create http scheduler-undeploy-model-my_model_name \
    --location us-central1 --schedule="0 19 * * *" --time-zone=UTC \
    --uri="https://us-central1-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/YOUR_PROJECT_ID/jobs/undeploy-model-my_model_name:run" \
    --http-method POST \
    --oauth-service-account-email YOUR_PROJECT_NUMBER-compute@developer.gserviceaccount.com
```

## Dockerfile

The accompanying Dockerfile sets up the necessary environment for running the script in a Docker container. It installs the required tools and sets up the working directory.

### Build Docker Image

```bash
docker build -t mng-model-deploy:latest .
```

### Run Docker Container

```bash
docker run -it --rm mng-model-deploy:latest
```

## License

This script is licensed under the [MIT License](LICENSE). Feel free to modify and distribute it according to your needs.

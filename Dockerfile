
# Use the official Ubuntu image from Docker Hub as
# a base image
FROM alpine:latest
FROM google/cloud-sdk:latest

# Install jq
RUN apt-get update && \
    apt-get install -y jq && \
    rm -rf /var/lib/apt/lists/* \

# Execute next commands in the directory /workspace
WORKDIR /workspace

# Copy over the script to the /workspace directory
COPY MngModelDeploy.sh .
# Just in case the script doesn't have the executable bit set
RUN chmod +x ./MngModelDeploy.sh

# Run the script when starting the container
CMD [ "./MngModelDeploy.sh" ]

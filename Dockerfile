
# Use the official Ubuntu image from Docker Hub as
# a base image
FROM alpine:latest
FROM google/cloud-sdk:latest


# Execute next commands in the directory /workspace
WORKDIR /workspace

# Copy over the script to the /workspace directory
COPY VxAIMngDelpoy.sh .
COPY model_config_file_*.sh .
# Just in case the script doesn't have the executable bit set
RUN chmod +x ./VxAIMngDelpoy.sh

# Run the script when starting the container
CMD [ "./VxAIMngDelpoy.sh" ]

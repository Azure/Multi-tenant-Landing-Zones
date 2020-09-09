FROM mcr.microsoft.com/powershell:latest

LABEL "com.github.actions.name"="arm-ttk"
LABEL "com.github.actions.description"="Checks template with the arm-ttk toolkit"

LABEL version="1.0.0"
LABEL maintainer="Harald S. Fianbakken"

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y git


RUN git clone https://github.com/Azure/arm-ttk.git

COPY entrypoint.ps1 /entrypoint.ps1

# When used from Github - mounts workspace into :
# /github/workspace
# Build and run locally using
#
# docker image build -t armttk:1.0 .
# Run with mount
# docker run --rm -it armttk:1.0 --mount source=../../,target=/github/workspace -e TemplatesFolder=./src/platform-automation/artifacts/templates

# Start using the Entrypoint file.
ENTRYPOINT [ "pwsh", "/entrypoint.ps1" ]
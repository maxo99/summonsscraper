FROM --platform=linux/amd64 amazon/aws-lambda-python:3.11

# Build arguments for versioning
ARG VERSION=unknown
LABEL version=${VERSION}
LABEL service="webscraper"

# Update package manager and install chrome dependencies
RUN yum update -y && yum install -y \
    atk cups-libs gtk3 libXcomposite alsa-lib \
    libXcursor libXdamage libXext libXi libXrandr libXScrnSaver \
    libXtst pango at-spi2-atk libXt xorg-x11-server-Xvfb \
    xorg-x11-xauth dbus-glib dbus-glib-devel nss mesa-libgbm jq unzip

# Copy source code and chrome installer
COPY ./src/webscraper ${LAMBDA_TASK_ROOT}/src/webscraper
COPY ./src/core ${LAMBDA_TASK_ROOT}/src/core

# Set working directory and install Chrome
WORKDIR ${LAMBDA_TASK_ROOT}
RUN chmod +x ./src/webscraper/chrome-installer.sh && \
    ./src/webscraper/chrome-installer.sh && \
    rm ./src/webscraper/chrome-installer.sh

# Install Python dependencies
COPY pyproject.toml ${LAMBDA_TASK_ROOT}/
RUN pip install --upgrade pip && \
    pip install selenium boto3 requests beautifulsoup4

# Command to run the Lambda function
CMD [ "src.webscraper.handler.lambda_handler" ]

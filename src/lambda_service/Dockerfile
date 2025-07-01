FROM amazon/aws-lambda-python:3.11

# Update package manager and install chrome dependencies
RUN yum update -y && yum install -y \
    atk cups-libs gtk3 libXcomposite alsa-lib \
    libXcursor libXdamage libXext libXi libXrandr libXScrnSaver \
    libXtst pango at-spi2-atk libXt xorg-x11-server-Xvfb \
    xorg-x11-xauth dbus-glib dbus-glib-devel nss mesa-libgbm jq unzip

# Copy and run the chrome installer script
COPY ./src/lambda_service ./src/lambda_service
COPY ./src/summonsscraper ./src/summonsscraper
RUN chmod +x ./src/lambda_service/chrome-installer.sh
RUN ./src/lambda_service/chrome-installer.sh
RUN rm ./src/lambda_service/chrome-installer.sh

# Install dependencies using uv
COPY pyproject.toml ./
RUN pip install uv && \
    uv pip install --system ".[lambda]"



# Command to run the Lambda function
CMD [ "src.lambda_service.handler.lambda_handler" ]
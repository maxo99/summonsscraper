FROM amazon/aws-lambda-python:3.11-2024.01.30.10

# Update package manager and install chrome dependencies
RUN yum update -y && yum install -y \
    atk cups-libs gtk3 libXcomposite alsa-lib \
    libXcursor libXdamage libXext libXi libXrandr libXScrnSaver \
    libXtst pango at-spi2-atk libXt xorg-x11-server-Xvfb \
    xorg-x11-xauth dbus-glib dbus-glib-devel nss mesa-libgbm jq unzip

# Copy and run the chrome installer script
COPY ./src/webscraper ./src/webscraper
COPY ./src/core ./src/core
RUN chmod +x ./src/webscraper/chrome-installer.sh
RUN ./src/webscraper/chrome-installer.sh
RUN rm ./src/webscraper/chrome-installer.sh

# Install dependencies using uv
COPY pyproject.toml ./
RUN pip install uv && \
    uv pip install --system ".[webscraper]"

# Command to run the Lambda function
CMD [ "src.webscraper.handler.lambda_handler" ]

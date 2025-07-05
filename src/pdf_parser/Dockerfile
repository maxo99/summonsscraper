FROM amazon/aws-lambda-python:3.11

# Build arguments for versioning
ARG VERSION=unknown
LABEL version=${VERSION}
LABEL service="pdf_parser"

# Install system dependencies for Pillow and other packages
RUN yum update -y && yum install -y \
    zlib-devel \
    libjpeg-devel \
    freetype-devel \
    lcms2-devel \
    openjpeg2-devel \
    libtiff-devel \
    libwebp-devel \
    gcc \
    gcc-c++ \
    && yum clean all

# Copy source code
COPY ./src/pdf_parser ${LAMBDA_TASK_ROOT}/src/pdf_parser
COPY ./src/core ${LAMBDA_TASK_ROOT}/src/core

# Install dependencies
COPY pyproject.toml ${LAMBDA_TASK_ROOT}/
WORKDIR ${LAMBDA_TASK_ROOT}

# Install Python dependencies directly with pip to avoid uv compatibility issues
RUN pip install --upgrade pip && \
    pip install boto3>=1.39.0 PyPDF2>=3.0.0 pdfplumber>=0.10.0 pydantic>=2.11.7

# Command to run the Lambda function
CMD [ "src.pdf_parser.handler.lambda_handler" ]

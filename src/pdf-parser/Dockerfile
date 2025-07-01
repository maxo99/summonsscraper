FROM amazon/aws-lambda-python:3.11-2024.01.30.10

# Copy source code
COPY ./src/pdf-parser ./src/pdf-parser
COPY ./src/core ./src/core

# Install dependencies using uv
COPY pyproject.toml ./
RUN pip install uv && \
    uv pip install --system ".[pdf-parser]"

# Command to run the Lambda function
CMD [ "src.pdf-parser.handler.lambda_handler" ]

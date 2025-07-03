# Lambda function for auto-shutdown/startup
resource "aws_lambda_function" "ec2_scheduler" {
  count = var.auto_shutdown_enabled ? 1 : 0

  filename      = "ec2_scheduler.zip"
  function_name = "${var.project_name}-ec2-scheduler-${var.environment}"
  role          = aws_iam_role.scheduler_lambda_role[0].arn
  handler       = "index.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60

  source_code_hash = data.archive_file.scheduler_lambda_zip[0].output_base64sha256

  environment {
    variables = {
      INSTANCE_ID = aws_instance.streamlit.id
    }
  }

  depends_on = [aws_iam_role_policy_attachment.scheduler_lambda_policy[0]]

  tags = {
    Name = "${var.project_name}-ec2-scheduler-${var.environment}"
  }
}

# Lambda code for EC2 scheduler
data "archive_file" "scheduler_lambda_zip" {
  count = var.auto_shutdown_enabled ? 1 : 0

  type        = "zip"
  output_path = "ec2_scheduler.zip"
  source {
    content = <<EOF
import boto3
import os
import json

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    instance_id = os.environ['INSTANCE_ID']
    
    action = event.get('action', 'stop')
    
    try:
        if action == 'stop':
            response = ec2.stop_instances(InstanceIds=[instance_id])
            print(f"Stopping instance {instance_id}")
        elif action == 'start':
            response = ec2.start_instances(InstanceIds=[instance_id])
            print(f"Starting instance {instance_id}")
        
        return {
            'statusCode': 200,
            'body': json.dumps(f"Successfully {action}ped instance {instance_id}")
        }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error {action}ping instance: {str(e)}")
        }
EOF
    filename = "index.py"
  }
}

# IAM role for scheduler Lambda
resource "aws_iam_role" "scheduler_lambda_role" {
  count = var.auto_shutdown_enabled ? 1 : 0

  name = "${var.project_name}-scheduler-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for scheduler Lambda
resource "aws_iam_role_policy_attachment" "scheduler_lambda_policy" {
  count = var.auto_shutdown_enabled ? 1 : 0

  role       = aws_iam_role.scheduler_lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "scheduler_lambda_ec2_policy" {
  count = var.auto_shutdown_enabled ? 1 : 0

  name = "${var.project_name}-scheduler-lambda-ec2-policy-${var.environment}"
  role = aws_iam_role.scheduler_lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# EventBridge rule for shutdown
resource "aws_cloudwatch_event_rule" "ec2_shutdown" {
  count = var.auto_shutdown_enabled ? 1 : 0

  name                = "${var.project_name}-ec2-shutdown-${var.environment}"
  description         = "Trigger EC2 shutdown"
  schedule_expression = "cron(${var.shutdown_schedule})"

  tags = {
    Name = "${var.project_name}-ec2-shutdown-${var.environment}"
  }
}

# EventBridge rule for startup
resource "aws_cloudwatch_event_rule" "ec2_startup" {
  count = var.auto_shutdown_enabled ? 1 : 0

  name                = "${var.project_name}-ec2-startup-${var.environment}"
  description         = "Trigger EC2 startup"
  schedule_expression = "cron(${var.startup_schedule})"

  tags = {
    Name = "${var.project_name}-ec2-startup-${var.environment}"
  }
}

# EventBridge targets
resource "aws_cloudwatch_event_target" "lambda_shutdown" {
  count = var.auto_shutdown_enabled ? 1 : 0

  rule      = aws_cloudwatch_event_rule.ec2_shutdown[0].name
  target_id = "TriggerLambdaShutdown"
  arn       = aws_lambda_function.ec2_scheduler[0].arn

  input = jsonencode({
    action = "stop"
  })
}

resource "aws_cloudwatch_event_target" "lambda_startup" {
  count = var.auto_shutdown_enabled ? 1 : 0

  rule      = aws_cloudwatch_event_rule.ec2_startup[0].name
  target_id = "TriggerLambdaStartup"
  arn       = aws_lambda_function.ec2_scheduler[0].arn

  input = jsonencode({
    action = "start"
  })
}

# Lambda permissions for EventBridge
resource "aws_lambda_permission" "allow_eventbridge_shutdown" {
  count = var.auto_shutdown_enabled ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridgeShutdown"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_scheduler[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_shutdown[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge_startup" {
  count = var.auto_shutdown_enabled ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridgeStartup"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_scheduler[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_startup[0].arn
}

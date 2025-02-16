
module "lambda_authorizer" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = "${local.name_prefix}-authorizer"
  description   = "API Lambda Authorizer"
  handler       = "main.lambda_handler"
  runtime       = "python3.11"
  publish       = true
  timeout       = 900

 kms_key_arn = aws_kms_key.this.arn
  source_path = "${path.module}/lambdasource"

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.lambda_authorizer.json

  allowed_triggers = {
    APIGatewayAny = {
      service    = "apigateway"
      source_arn = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
    }
  }

  vpc_subnet_ids         = module.network.application_subnet_ids
  vpc_security_group_ids = [module.api_gateway_security_group.security_group_id]
  attach_network_policy  = true
  environment_variables = {
    ENVIRONMENT      = var.environment
    GOOGLE_CLIENT_ID = var.google_client_id
  }

  tags = var.tags
}

data "aws_iam_policy_document" "lambda_authorizer" {

  statement {
    actions = [
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "logs:StartQuery",
      "logs:DescribeQueries",
      "logs:GetQueryResults",
      "logs:GetLogRecord"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:logs:eu-central-1:${data.aws_caller_identity.current.account_id}:*"
    ]
  }
}

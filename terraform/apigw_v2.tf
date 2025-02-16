resource "aws_apigatewayv2_vpc_link" "this" {
  name               = "${local.name_prefix}-api-vpc-link"
  security_group_ids = [module.api_gateway_security_group.security_group_id]
  subnet_ids         = module.network.application_subnet_ids

  tags = local.tags
}

# HTTP API
resource "aws_apigatewayv2_api" "this" {
  name          = "${local.name_prefix}-apigw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_authorizer" "this" {
  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = "REQUEST"
  authorizer_uri   = module.lambda_authorizer.lambda_function_invoke_arn
  identity_sources = ["$request.header.Authorization"]
  name            = "google-oauth"
  
  authorizer_payload_format_version = "2.0"
  enable_simple_responses          = true
}

resource "aws_apigatewayv2_integration" "this" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = aws_lb_listener.alb_http_listener.arn
  
  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.this.id
  
  request_parameters = {
    "overwrite:path" = "$request.path"
  }
}

# API Route
resource "aws_apigatewayv2_route" "this" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /{proxy+}"
  
  target = "integrations/${aws_apigatewayv2_integration.this.id}"
  
  authorization_type = "CUSTOM"
  authorizer_id     = aws_apigatewayv2_authorizer.this.id
}

# Stage
resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip            = "$context.identity.sourceIp"
      requestTime   = "$context.requestTime"
      httpMethod    = "$context.httpMethod"
      routeKey      = "$context.routeKey"
      status        = "$context.status"
      protocol      = "$context.protocol"
      responseLength = "$context.responseLength"
      path          = "$context.path"
      authorizer    = "$context.authorizer.error"
      error         = "$context.error.message"
    })
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${local.name_prefix}-apigw"
  retention_in_days = 90
}
output "apigateway_invoke_uri" {
  value = aws_apigatewayv2_stage.this.invoke_url
}
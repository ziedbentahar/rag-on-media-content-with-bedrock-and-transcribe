resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.application}-${var.environment}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_sample.arn
    format = jsonencode({
      "requestId" : "$context.requestId", "ip" : "$context.identity.sourceIp", "requestTime" : "$context.requestTime",
      "httpMethod" : "$context.httpMethod", "routeKey" : "$context.routeKey", "status" : "$context.status",
      "protocol" : "$context.protocol", "responseLength" : "$context.responseLength"
    })
  }
}

resource "aws_cloudwatch_log_group" "api_gateway_sample" {
  name              = "/aws/apigateway/${var.application}-${var.environment}"
  retention_in_days = 7
}




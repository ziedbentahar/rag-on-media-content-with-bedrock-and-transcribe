resource "aws_apigatewayv2_integration" "query_knowledge_base" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.query_knowledge_base.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}


resource "aws_apigatewayv2_route" "query_knowledge_base" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /query"
  target    = "integrations/${aws_apigatewayv2_integration.query_knowledge_base.id}"
}

resource "aws_lambda_permission" "query_knowledge_base" {
  statement_id  = "AllowAPIGatewaySample"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.query_knowledge_base.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
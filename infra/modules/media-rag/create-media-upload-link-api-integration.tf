resource "aws_apigatewayv2_integration" "create_media_upload_link" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.create_media_upload_link.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_media_upload_link" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /media"
  target    = "integrations/${aws_apigatewayv2_integration.create_media_upload_link.id}"
}

resource "aws_lambda_permission" "create_media_upload_link" {
  statement_id  = "AllowAPIGatewaySample"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_media_upload_link.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

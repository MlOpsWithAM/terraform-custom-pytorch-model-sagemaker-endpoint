
data "aws_iam_policy_document" "sagemaker_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sagemaker_access_iam_role" {
  name               = "sagemaker_access_iam_role"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "sagemaker_access_policy_attachment" {
  role       = aws_iam_role.sagemaker_access_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

variable container_image {}


resource "aws_sagemaker_model" "mnist-model" {
  name               = "mnist-model"
  execution_role_arn = aws_iam_role.sagemaker_access_iam_role.arn

  primary_container {
    image = var.container_image
  }
}

resource "aws_sagemaker_endpoint_configuration" "mnist-configuration" {
  name = "my-endpoint-config"

  production_variants {
    variant_name           = "mnist-variant"
    model_name             = aws_sagemaker_model.mnist-model.name
    initial_instance_count = 1
    instance_type          = "ml.g4dn.xlarge"
  }

  tags = {
    Name = "mnist-config"
  }
}

resource "aws_sagemaker_endpoint" "mnist_endpoint_2" {
  name                 = "mnist-endpoint-2"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.mnist-configuration.name

  tags = {
    Name = "mnist-endpoint"
  }
}

output "sagemaker_endpoint_name" {
  value       = aws_sagemaker_endpoint.mnist_endpoint_2.name
  description = "SageMaker Endpoint Name"
}

output "sagemaker_endpoint_arn" {
  value       = aws_sagemaker_endpoint.mnist_endpoint_2.arn
  description = "SageMaker Endpoint ARN"
}

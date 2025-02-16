# IAM Role for Fluent Bit
resource "aws_iam_role" "fluentbit_role" {
  name = "fluent-bit-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                # "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/<OIDC_PROVIDER>"
                "Federated": "${module.eks_managed_node.oidc_provider_arn}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${replace(module.eks_managed_node.cluster_oidc_issuer_url, "https://", "")}:sub": "system:serviceaccount:kube-system:fluent-bit",
                    "${replace(module.eks_managed_node.cluster_oidc_issuer_url, "https://", "")}:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
EOF
}




# IAM Policy for Fluent Bit to write to CloudWatch
resource "aws_iam_policy" "fluentbit_policy" {
  name        = "FluentBitCloudWatchPolicy"
  description = "Policy to allow Fluent Bit to write logs to CloudWatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:CreateLogGroup"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "fluentbit_role_attach" {
  role       = aws_iam_role.fluentbit_role.name
  policy_arn = aws_iam_policy.fluentbit_policy.arn
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "fluentbit_instance_profile" {
  name = "FluentBitInstanceProfile"
  role = aws_iam_role.fluentbit_role.name
}

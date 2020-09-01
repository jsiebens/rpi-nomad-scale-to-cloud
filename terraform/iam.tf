resource "aws_iam_user" "nomad-autoscaler" {
  name = "nomad-autoscaler"
  path = "/"
}

resource "aws_iam_access_key" "nomad-autoscaler" {
  user = aws_iam_user.nomad-autoscaler.name
}

resource "aws_iam_user_policy" "nomad-autoscaler" {
  name = "nomad-autoscaler"
  user = aws_iam_user.nomad-autoscaler.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "ec2:TerminateInstances",
        "ec2:DescribeInstanceStatus",
        "autoscaling:UpdateAutoScalingGroup",
        "autoscaling:DetachInstances",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:CreateOrUpdateTags"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

output "nomad-autoscaler_user" { value = aws_iam_access_key.nomad-autoscaler.user }

output "nomad-autoscaler_id" { value = aws_iam_access_key.nomad-autoscaler.id }

output "nomad-autoscaler_secret" { value = aws_iam_access_key.nomad-autoscaler.secret }
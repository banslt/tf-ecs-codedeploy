provider "aws"{
    region = var.aws_region
}

resource "aws_codedeploy_app" "codedeploy" {
  compute_platform = "ECS"
  name             = "ba-cd-ecs-rollingupdate"
}

resource "aws_codedeploy_deployment_group" "codedeploy" {
  app_name               = aws_codedeploy_app.codedeploy.name
  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"
  deployment_group_name  = "ba-ecs-CodeDeploy"
  service_role_arn       = aws_iam_role.codedeploy.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"] # rollbacks on deployment failure 
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT" # CONTINUE_DEPLOYMENT or STOP_DEPLOYMENT
      wait_time_in_minutes = var.wait_time_in_minutes # Duration to wait before the status of a 
                                                           # blue/green deployment changed to Stopped. 
                                                           # ONLY IF action_on_timeout = STOP_DEPLOYMENT 
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.cluster_name
    service_name = var.service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route { #The PROD route
        listener_arns = [var.lb_listener_arn]
      }

      test_traffic_route { #The TEST route
        listener_arns = [var.test_traffic_route_listener_arn]
      }

      target_group { # Former Group Blue
        name = var.lb_tg_blue_name
      }

      target_group { #New Group Green
        name = var.lb_tg_green_name
      }

    }
  }
}

resource "aws_iam_role" "codedeploy" {
  name               = "ba_cd_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  description        = "Code Deploy role for ECS stressapp rolling update"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "default" {
  name        = "ba-ecs-codedeploy"
  policy      = data.aws_iam_policy_document.policy.json
  description = ""
}

data "aws_iam_policy_document" "policy" {
  
  statement {
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecs:DescribeServices",
      "ecs:CreateTaskSet",
      "ecs:UpdateServicePrimaryTaskSet",
      "ecs:DeleteTaskSet",
      "cloudwatch:DescribeAlarms",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    resources = ["arn:aws:sns:*:*:CodeDeployTopic_*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:ModifyRule",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = ["arn:aws:lambda:*:*:function:CodeDeployHook_*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:ExistingObjectTag/UseWithCodeDeploy"
      values   = ["true"]
    }

    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = aws_iam_policy.default.arn
}


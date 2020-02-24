provider "aws"{
    region = "${var.aws_region}"
}

resource "aws_codedeploy_app" "codedeploy" {
  compute_platform = "ECS"
  name             = "ba-cd-ecs-rollingupdate"
}

resource "aws_codedeploy_deployment_group" "codedeploy" {
  app_name               = "${aws_codedeploy_app.codedeploy.name}"
  deployment_config_name = "ba-ecs-CodeDeploy.test"
  deployment_group_name  = "ba-ecs-CodeDeploy"
  service_role_arn       = "${aws_iam_role.codedeploy.arn}"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
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
    cluster_name = "${var.cluster_name}"
    service_name = "${var.service_name}"
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = ["${var.lb_listener_arn}"]
      }

      target_group { # Former Group Blue
        name = "${var.lb_tg_blue_name}"
      }

      target_group { #New Group Green
        name = "${var.lb_tg_green_name}"
      }
    }
  }
}

resource "aws_iam_role" "codedeploy" {
  name               = "ba_cd_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
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

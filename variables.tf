variable "aws_region" {
  description = "Region"
}

variable "cluster_name" {
  description = "Name of the cluster"
}

variable "service_name" {
  description = "Name of the service"
}

variable "lb_listener_arn" {
    description = "Load Balancer Listener arn"
}

variable "lb_tg_blue_name" {
    description = "Blue Load Balancer target group"
}

variable "lb_tg_green_name" {
    description = "Blue Load Balancer target group"
}
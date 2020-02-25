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
    description = "Prod Load Balancer Listener arn"
}

variable "lb_tg_blue_name" {
    description = "Blue Load Balancer target group"
}

variable "lb_tg_green_name" {
    description = "Blue Load Balancer target group"
}
variable "wait_time_in_minutes" {
    description = "Duration to wait before the status of a blue/green deployment changed to Stopped"
}

variable "test_traffic_route_listener_arns" {
    description = "array of Test Load Balancer Listener arns"
}



resource "aws_lb" "alb_internal" {
  name               = "${local.name_prefix}-interal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [module.api_gateway_security_group.security_group_id]
  subnets            = module.network.application_subnet_ids

  enable_deletion_protection = false

  #   access_logs {
  #     bucket  = aws_s3_bucket.lb_logs.id
  #     prefix  = "test-lb"
  #     enabled = true
  #   }

  tags = local.tags
}

resource "aws_lb_target_group" "alb_internal" {
  name     = "internal-tg1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id
}

resource "aws_lb_listener" "alb_http_listener" {
  load_balancer_arn = aws_lb.alb_internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_internal.arn
  }
}
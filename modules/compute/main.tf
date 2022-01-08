data "aws_ami" "ubuntu" {
  most_recent = true

  // http://cloud-images.ubuntu.com/locator/ec2/
  // https://www.kisphp.com/terraform/terraform-find-ubuntu-and-amazon-linux-2-amis
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["self", "amazon", "099720109477"]
}

resource "aws_iam_role" "bastion" {
  name = "${var.env}-${var.project}-iam-role-bastion"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    tag-key = "${var.env}-${var.project}-bastion"
  }
}

resource "aws_iam_role_policy" "bastion" {
  name = "${var.env}-${var.project}-iam-role-pl-bastion-secretmanager"
  role = aws_iam_role.bastion.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Action": "secretsmanager:GetSecretValue",
        "Resource": "arn:aws:secretsmanager:us-east-1:122657302772:secret:${var.project}.com/aws/${var.env}-${var.project}-key-private-*"
    }]
}
EOF
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.env}-${var.project}-iam-profile-bastion"
  role = aws_iam_role.bastion.name
}

resource "aws_launch_template" "project_bastion_lt" {
  name                   = "${var.env}-${var.project}-bastion"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_bastion
  vpc_security_group_ids = [var.sg_bastion]
  key_name               = var.key_id_bastion
  update_default_version = true
  user_data              = base64encode(templatefile("scripts/ubuntu_keyfile.sh", {
    KEY_PRIVATE = "${var.project}.com/aws/${var.env}-${var.project}-key-private"
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.bastion.name
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.env}-${var.project}-bastion"
    }
  }

  tags = {
    Name = "${var.env}-${var.project}-bastion-lt"
  }
}

resource "aws_autoscaling_group" "bastion" {
  name                = "${var.env}-${var.project}-asg-bastion"
  vpc_zone_identifier = tolist(var.subnet_public)
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.project_bastion_lt.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "frontend" {
  name                   = "${var.env}-${var.project}-frontend"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_frontend
  vpc_security_group_ids = [var.sg_private]
  key_name               = var.key_id_project
  update_default_version = true
  user_data              = base64encode(templatefile("scripts/ubuntu_apache.sh", {
    ENV = "${var.env}-frontend"
  }))

  monitoring {
    enabled = true
  }

  block_device_mappings {
    # device_name = "/dev/xvda" // Root: Amazon Linux 2 AMI (HVM)
    device_name = "/dev/sda1" // Root: Ubuntu Server 20.04 LTS (HVM)
    ebs {
      volume_size = 8
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = {
      Name = "${var.env}-${var.project}-frontend"
    }
  }

  tags = {
    Name = "${var.env}-${var.project}-lt-frontend"
  }
}

resource "aws_launch_template" "backend" {
  name                   = "${var.env}-${var.project}-backend"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_backend
  vpc_security_group_ids = [var.sg_private]
  key_name               = var.key_id_project
  update_default_version = true
  user_data              = base64encode(templatefile("scripts/ubuntu_apache.sh", {
    ENV = "${var.env}-backend"
  }))

  monitoring {
    enabled = true
  }

  block_device_mappings {
    # device_name = "/dev/xvda" // Root: Amazon Linux 2 AMI (HVM)
    device_name = "/dev/sda1" // Root: Ubuntu Server 20.04 LTS (HVM)
    ebs {
      volume_size = 20
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = {
      Name = "${var.env}-${var.project}-backend"
    }
  }

  tags = {
    Name = "${var.env}-${var.project}-lt-backend"
  }
}

resource "aws_launch_template" "database" {
  name                   = "${var.env}-${var.project}-database"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_database
  vpc_security_group_ids = [var.sg_private]
  key_name               = var.key_id_project
  update_default_version = true
  user_data              = base64encode(templatefile("scripts/ubuntu_apache.sh", {
    ENV = "${var.env}-database"
  }))

  monitoring {
    enabled = true
  }

  block_device_mappings {
    # device_name = "/dev/xvda" // Root: Amazon Linux 2 AMI (HVM)
    device_name = "/dev/sda1" // Root: Ubuntu Server 20.04 LTS (HVM)
    ebs {
      volume_size = 20
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = {
      Name = "${var.env}-${var.project}-database"
    }
  }

  tags = {
    Name = "${var.env}-${var.project}-lt-database"
  }
}

###########
## Frontend
###########
resource "aws_autoscaling_group" "frontend" {
  name                 = "${var.env}-${var.project}-asg-frontend"
  vpc_zone_identifier  = tolist(var.subnet_frontend)
  min_size             = 2
  max_size             = 5
  desired_capacity     = 2
  health_check_type    = "ELB"
  termination_policies = ["OldestInstance"]
  enabled_metrics      = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
  metrics_granularity  = "1Minute"
  target_group_arns    = [var.lb_tg_arn_frontend]
  lifecycle {
    create_before_destroy = true
  }

  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }
}

# Predictive
resource "aws_autoscaling_policy" "predictive_frontend" {
  name                   = "${var.env}-${var.project}-asg-pl-predictive-frontend"
  policy_type            = "PredictiveScaling"
  autoscaling_group_name = aws_autoscaling_group.frontend.name
  predictive_scaling_configuration {
    metric_specification {
      target_value = 32
      predefined_scaling_metric_specification {
        predefined_metric_type = "ASGAverageCPUUtilization"
        resource_label         = "scaling_metric_label"
      }
      predefined_load_metric_specification {
        predefined_metric_type = "ASGTotalCPUUtilization"
        resource_label         = "load_metric_label"
      }
    }
    mode                         = "ForecastAndScale"
    scheduling_buffer_time       = 10
    max_capacity_breach_behavior = "IncreaseMaxCapacity"
    max_capacity_buffer          = 10
  }
}

# Scale up alarm
resource "aws_autoscaling_policy" "cpu_up_frontend" {
  name                   = "${var.env}-${var.project}-asg-pl-cpu-up-frontend"
  autoscaling_group_name = aws_autoscaling_group.frontend.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}
resource "aws_cloudwatch_metric_alarm" "cpu_up_frontend" {
  alarm_name          = "${var.env}-${var.project}-alarm-cpu-up-frontend"
  alarm_description   = "Alarm when CPU >= 30"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.frontend.name
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.cpu_up_frontend.arn]
}

# Scale down alarm
resource "aws_autoscaling_policy" "cpu_down_frontend" {
  name                   = "${var.env}-${var.project}-asg-pl-cpu-down-frontend"
  autoscaling_group_name = aws_autoscaling_group.frontend.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}
resource "aws_cloudwatch_metric_alarm" "cpu_down_frontend" {
  alarm_name          = "${var.env}-${var.project}-alarm-cpu-down-frontend"
  alarm_description   = "Alarm when CPU <= 5"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "5"

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.frontend.name
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.cpu_down_frontend.arn]
}

###########
## Backend
###########
resource "aws_autoscaling_group" "backend" {
  name                 = "${var.env}-${var.project}-asg-backend"
  vpc_zone_identifier  = tolist(var.subnet_backend)
  min_size             = 2
  max_size             = 5
  desired_capacity     = 2
  health_check_type    = "ELB"
  termination_policies = ["OldestInstance"]
  enabled_metrics      = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
  metrics_granularity  = "1Minute"
  target_group_arns    = [var.lb_tg_arn_backend]
  lifecycle {
    create_before_destroy = true
  }

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }
}

# Predictive
resource "aws_autoscaling_policy" "predictive_backend" {
  name                   = "${var.env}-${var.project}-asg-pl-predictive-backend"
  policy_type            = "PredictiveScaling"
  autoscaling_group_name = aws_autoscaling_group.backend.name
  predictive_scaling_configuration {
    metric_specification {
      target_value = 32
      predefined_scaling_metric_specification {
        predefined_metric_type = "ASGAverageCPUUtilization"
        resource_label         = "scaling_metric_label"
      }
      predefined_load_metric_specification {
        predefined_metric_type = "ASGTotalCPUUtilization"
        resource_label         = "load_metric_label"
      }
    }
    mode                         = "ForecastAndScale"
    scheduling_buffer_time       = 10
    max_capacity_breach_behavior = "IncreaseMaxCapacity"
    max_capacity_buffer          = 10
  }
}

# Scale up alarm
resource "aws_autoscaling_policy" "cpu_up_backend" {
  name                   = "${var.env}-${var.project}-asg-pl-cpu-up-backend"
  autoscaling_group_name = aws_autoscaling_group.backend.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}
resource "aws_cloudwatch_metric_alarm" "cpu_up_backend" {
  alarm_name          = "${var.env}-${var.project}-alarm-cpu-up-backend"
  alarm_description   = "Alarm when CPU >= 30"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.backend.name
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.cpu_up_backend.arn]
}

# Scale down alarm
resource "aws_autoscaling_policy" "cpu_down_backend" {
  name                   = "${var.env}-${var.project}-asg-pl-cpu-down-backend"
  autoscaling_group_name = aws_autoscaling_group.backend.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}
resource "aws_cloudwatch_metric_alarm" "cpu_down_backend" {
  alarm_name          = "${var.env}-${var.project}-alarm-cpu-down-backend"
  alarm_description   = "Alarm when CPU <= 5"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "5"

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.backend.name
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.cpu_down_backend.arn]
}


###########
## Database
###########
resource "aws_autoscaling_group" "database" {
  name                 = "${var.env}-${var.project}-asg-database"
  vpc_zone_identifier  = tolist(var.subnet_database)
  min_size             = 2
  max_size             = 5
  desired_capacity     = 2
  health_check_type    = "ELB"
  termination_policies = ["OldestInstance"]
  enabled_metrics      = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
  metrics_granularity  = "1Minute"
  target_group_arns    = [var.lb_tg_arn_database]
  lifecycle {
    create_before_destroy = true
  }

  launch_template {
    id      = aws_launch_template.database.id
    version = "$Latest"
  }
}

# Predictive
resource "aws_autoscaling_policy" "predictive_database" {
  name                   = "${var.env}-${var.project}-asg-pl-predictive-database"
  policy_type            = "PredictiveScaling"
  autoscaling_group_name = aws_autoscaling_group.database.name
  predictive_scaling_configuration {
    metric_specification {
      target_value = 32
      predefined_scaling_metric_specification {
        predefined_metric_type = "ASGAverageCPUUtilization"
        resource_label         = "scaling_metric_label"
      }
      predefined_load_metric_specification {
        predefined_metric_type = "ASGTotalCPUUtilization"
        resource_label         = "load_metric_label"
      }
    }
    mode                         = "ForecastAndScale"
    scheduling_buffer_time       = 10
    max_capacity_breach_behavior = "IncreaseMaxCapacity"
    max_capacity_buffer          = 10
  }
}

# Scale up alarm
resource "aws_autoscaling_policy" "cpu_up_database" {
  name                   = "${var.env}-${var.project}-asg-pl-cpu-up-database"
  autoscaling_group_name = aws_autoscaling_group.database.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}
resource "aws_cloudwatch_metric_alarm" "cpu_up_database" {
  alarm_name          = "${var.env}-${var.project}-alarm-cpu-up-database"
  alarm_description   = "Alarm when CPU >= 30"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.database.name
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.cpu_up_database.arn]
}

# Scale down alarm
resource "aws_autoscaling_policy" "cpu_down_database" {
  name                   = "${var.env}-${var.project}-asg-pl-cpu-down-database"
  autoscaling_group_name = aws_autoscaling_group.database.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}
resource "aws_cloudwatch_metric_alarm" "cpu_down_database" {
  alarm_name          = "${var.env}-${var.project}-alarm-cpu-down-database"
  alarm_description   = "Alarm when CPU <= 5"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "5"

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.database.name
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.cpu_down_database.arn]
}

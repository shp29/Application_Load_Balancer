output "alb_dns_name" {
  value = "${aws_lb.my-aws-alb.dns_name}"
}

output "alb_target_group_arn" {
  value = "${aws_lb_target_group.my-target-group.arn}"
}

output "subnet1_name" {
  value = "${aws_subnet.mysubnet1.id}"
}

output "subnet2_name" {
  value = "${aws_subnet.mysubnet2.id}"
}

output "security_group" {
  value = "${aws_security_group.my-alb-sg.id}"
}

output "vpc_id" {
  value = "${aws_vpc.myvpc.id}"
}
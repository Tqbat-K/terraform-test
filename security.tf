resource "aws_security_group" "keis_alb" {
  vpc_id = aws_vpc.keis_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "keis_alb_ingress_http" {
	aws_security_group.keis_alb.id
	cidr_ipv4 = "0.0.0.0/0"
	ip_protocol = "tcp"
	from_port = 80
	to_port = 80
}

resource "aws_vpc_security_group_ingress_rule" "keis_alb_ingress_https" {
        aws_security_group.keis_alb.id
        cidr_ipv4 = "0.0.0.0/0"
        ip_protocol = "tcp"
        from_port = 443
        to_port = 443
}

resource "aws_vpc_security_group_egress_rule" "keis_alb_egress" {
	security_group_id = aws_security_group.keis_alb.id
	cidr_ipv4         = "0.0.0.0/0"
	ip_protocol       = "-1" # all ports
}
# ロードバランサ用
# ↓EC2用

resource "aws_security_group" "keis_ec2" {
  vpc_id = aws_vpc.keis_vpc.id
}

resource "aws_security_group_ingress_rule" "keis_ec2_http" {
	security_group_id = aws_security_group.keis_ec2.id
	ip_protocol = "tcp"
	from_port = 80
	to_port = 80
	referenced_security_group_id = aws_security_group.keis_alb.id
}

resource "aws_security_group_ingress_rule" "keis_ec2_https" {
        security_group_id = aws_security_group.keis_ec2.id
        ip_protocol = "tcp"
        from_port = 443
        to_port = 443
        referenced_security_group_id = aws_security_group.keis_alb.id
}

resource "aws_vpc_security_group_egress_rule" "keis_ec2_egress" {
 	 security_group_id = aws_security_group.keis_ec2.id
	  cidr_ipv4         = "0.0.0.0/0"
 	 ip_protocol       = "-1" # all ports
}


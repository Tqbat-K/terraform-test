resource "aws_instance" "keis_1" {
	ami = "ami-05284d16d6b516ace"
	instance_type = "t3.micro"
	tags ={
		Name = "keis_software_test"
	} 
}

# AMIはAmazon Linux2

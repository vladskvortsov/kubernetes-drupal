data "aws_availability_zones" "azs" {
    state = "available"
}



module "eks" {
    source  = "terraform-aws-modules/eks/aws"
    version = "~> 19.0"
    cluster_name = "drupal-eks-cluster"
    cluster_version = "1.24"

    cluster_endpoint_public_access  = true

    vpc_id = module.drupal-vpc.vpc_id
    subnet_ids = module.drupal-vpc.private_subnets

    tags = {
        environment = "development"
        application = "drupal"
    }

    eks_managed_node_groups = {
        dev = {
            min_size = 1
            max_size = 3
            desired_size = 2
            additional_security_group_ids = [aws_security_group.drupal-sg.id]

            instance_types = ["t2.small"]
        }
    }
}


resource "aws_efs_file_system" "efs" {
   creation_token = "efs"
   performance_mode = "generalPurpose"
   throughput_mode = "bursting"
   encrypted = "true"
 tags = {
     Name = "EFS"
   }
 }


resource "aws_efs_mount_target" "efs-mt" {
   for_each = module.drupal-vpc.private_subnets
   count = length(data.aws_availability_zones.azs.names)
   file_system_id  = aws_efs_file_system.efs.id
   subnet_id = each.value.id
   security_groups = [aws_security_group.drupal-sg.id]
 }




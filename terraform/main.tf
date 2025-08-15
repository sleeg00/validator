terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider 1: 기본 프로바이더 (서울)
provider "aws" {
  region = "ap-northeast-2"
}

# Provider 2: 'ohio' 별칭 프로바이더
provider "aws" {
  alias  = "ohio"
  region = "us-east-2"
}

variable "my_ip_address" {
  description = "My public IP address for SSH access"
  type        = string
  sensitive   = true
}

# ------------------------------------------------------------------
# [서울] 밸리데이터 모듈 호출
# ------------------------------------------------------------------
module "seoul_validator" {
  source = "./modules/validator"

  availability_zone = "ap-northeast-2a"
  ami_id            = "ami-08943a1f4e113a2" 
  key_name          = "seoul"
  my_ip_address     = var.my_ip_address # 하드코딩된 IP 대신 변수를 사용
}

# ------------------------------------------------------------------
# [오하이오] 밸리데이터 모듈 호출
# ------------------------------------------------------------------
module "ohio_validator" {
  source    = "./modules/validator"
  providers = { aws = aws.ohio }

  availability_zone = "us-east-2a"
  ami_id            = "ami-0b05d988257befbbe"
  key_name          = "ohio"
  my_ip_address     = var.my_ip_address # 하드코딩된 IP 대신 변수를 사용
}
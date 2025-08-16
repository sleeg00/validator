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
  my_ip_address     = var.my_ip_address
  instance_name_tag = "ValidatorNode-Seoul-Active"
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
  my_ip_address     = var.my_ip_address
  instance_name_tag = "ValidatorNode-Ohio-Active"
}

# ------------------------------------------------------------------
# [서울] 생성된 스팟 인스턴스 정보 조회
# ------------------------------------------------------------------
data "aws_instance" "seoul_validator_instance" {
  depends_on = [module.seoul_validator] # 모듈이 실행된 후에 이 조회를 시작하도록 보장

  # 아래 조건을 만족하는 인스턴스를 '찾는다'.
  filter {
    name   = "tag:Name"
    values = ["ValidatorNode-Seoul-Active"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running", "pending"]
  }
}

# ------------------------------------------------------------------
# [오하이오] 생성된 스팟 인스턴스 정보 조회
# ------------------------------------------------------------------
data "aws_instance" "ohio_validator_instance" {
  provider   = aws.ohio # ★★★ 이 조회를 'ohio' 프로바이더로 실행하도록 지정
  depends_on = [module.ohio_validator]

  filter {
    name   = "tag:Name"
    values = ["ValidatorNode-Ohio-Passive"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running", "pending"]
  }
}

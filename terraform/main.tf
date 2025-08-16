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
  ami_id            = "ami-08943a151bd468f4e"
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
# [서울] 생성된 스팟 인스턴스 정보 조회 (ID 기반)
# ------------------------------------------------------------------
data "aws_instance" "seoul_validator_instance" {
  # module의 output을 직접 참조하여 암시적 의존성을 만듭니다.
  instance_id = module.seoul_validator.spot_instance_id
}

# ------------------------------------------------------------------
# [오하이오] 생성된 스팟 인스턴스 정보 조회 (ID 기반)
# ------------------------------------------------------------------
data "aws_instance" "ohio_validator_instance" {
  provider    = aws.ohio # ★★★ 이 조회를 'ohio' 프로바이더로 실행하도록 지정
  instance_id = module.ohio_validator.spot_instance_id
}
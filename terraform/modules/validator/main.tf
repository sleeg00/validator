# 이 모듈 내의 모든 리소스는 호출될 때 전달받은 provider 설정을 따릅니다.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_security_group" "validator_sg" {
  name        = "validator-sg"
  description = "Security group for Ethereum validator node"

  # ------------------- Ingress (수신) 규칙 -------------------

  # Rule 1: SSH - 내 IP에서만 원격 접속 허용
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }

  # Rule 2: 모니터링 (Grafana & Prometheus)
  ingress {
    description = "Grafana from my IP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }
  ingress {
    description = "Prometheus from my IP"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }

  # Rule 3: Execution Layer P2P (Geth, Nethermind 등)
  ingress {
    description = "EL P2P TCP"
    from_port   = 30303
    to_port     = 30303
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "EL P2P UDP"
    from_port   = 30303
    to_port     = 30303
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Rule 4: Consensus Layer P2P (Prysm, Lighthouse 등)
  ingress {
    description = "CL P2P TCP"
    from_port   = 13000
    to_port     = 13000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "CL P2P UDP"
    from_port   = 12000
    to_port     = 12000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Rule 5: JSON-RPC API - 내 IP에서만 데이터 조회 허용
  ingress {
    description = "EL JSON-RPC from my IP"
    from_port   = 8545
    to_port     = 8545
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }

  # Rule 6: Metrics - 내 IP에서만 모니터링 데이터 수집 허용
  ingress {
    description = "CL Metrics for Prometheus from my IP"
    from_port   = 5054
    to_port     = 5054
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }

  # ------------------- Egress (송신) 규칙 -------------------
  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- EBS 볼륨, 스팟 인스턴스, 볼륨 연결 리소스 (이전과 동일) ---

resource "aws_ebs_volume" "validator_data" {
  availability_zone = var.availability_zone
  size              = 500
  type              = "io2"
  iops              = 10000
  tags              = { Name = "ValidatorDataVolume" }
}

resource "aws_spot_instance_request" "validator_node" {
  ami                    = var.ami_id
  instance_type          = "t3.xlarge"
  wait_for_fulfillment   = true
  vpc_security_group_ids = [aws_security_group.validator_sg.id]
  key_name               = var.key_name
  availability_zone      = var.availability_zone
  tags                   = { Name = "ValidatorNode-Spot" }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.validator_data.id
  instance_id = aws_spot_instance_request.validator_node.spot_instance_id
}

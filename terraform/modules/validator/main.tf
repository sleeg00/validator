# 이 모듈 내의 모든 리소스는 호출될 때 전달받은 provider 설정을 따릅니다.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_security_groups" "existing_sg" {
  filter {
    name   = "group-name"
    values = [var.security_group_name]
  }
}

resource "aws_security_group" "validator_sg" {
  count = length(data.aws_security_groups.existing_sg.ids) == 0 ? 1 : 0

  name        = var.security_group_name
  description = "Security group for Ethereum validator node"

  # ------------------- Ingress (수신) 규칙 -------------------

  # --- 관리 및 모니터링 UI (내 IP에서만 허용) ---
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }
  ingress {
    description = "Grafana Web UI from my IP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }
  ingress {
    description = "Prometheus Web UI from my IP"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }

  # --- P2P 네트워크 (전체 허용) ---
  ingress {
    description = "EL P2P (Geth)"
    from_port   = 30303
    to_port     = 30303
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "EL P2P (Geth) Discovery"
    from_port   = 30303
    to_port     = 30303
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "CL P2P (Lighthouse)"
    from_port   = 13000
    to_port     = 13000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "CL P2P (Lighthouse) Discovery"
    from_port   = 12000
    to_port     = 12000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # --- API 및 메트릭 (내 IP에서만 허용) ---
  ingress {
    description = "EL JSON-RPC API from my IP"
    from_port   = 8545
    to_port     = 8545
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }
  ingress {
    description = "CL Beacon API from my IP"
    from_port   = 5052
    to_port     = 5052
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }
  ingress {
    description = "EL Metrics (Geth) for Prometheus from my IP"
    from_port   = 6060
    to_port     = 6060
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }
  ingress {
    description = "CL Metrics (Lighthouse) for Prometheus from my IP"
    from_port   = 5054
    to_port     = 5054
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }

  # ------------------------------------------------------------------
  # Egress (송신) 규칙: 서버에서 외부로 나가는 트래픽 허용
  # ------------------------------------------------------------------
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
  type              = "gp3"
  tags              = { Name = "ValidatorDataVolume" }
}

resource "aws_spot_instance_request" "validator_node" {
  ami                  = var.ami_id
  instance_type        = "t3.xlarge"
  wait_for_fulfillment = true
  vpc_security_group_ids = [
    length(data.aws_security_groups.existing_sg.ids) > 0 ?
    data.aws_security_groups.existing_sg.ids[0] :
    aws_security_group.validator_sg[0].id
  ]
  key_name          = var.key_name
  availability_zone = var.availability_zone
  tags              = { Name = var.instance_name_tag }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.validator_data.id
  instance_id = aws_spot_instance_request.validator_node.spot_instance_id
}

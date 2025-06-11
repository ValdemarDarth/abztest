# ============================
#  AWS Provider
# ============================
# Використовується регіон eu-west-1 (Ірландія) — стабільний і Free Tier-дружній
provider "aws" {
  region = "eu-west-1"
}

# ============================
#  Мережа: VPC і підмережі
# ============================

# Основна приватна мережа VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "main-vpc" }
}

# Публічна підмережа — для EC2 (WordPress), має вихід у Інтернет
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true
  tags = { Name = "public-subnet" }
}

# Приватна підмережа для RDS
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1a"
  tags = { Name = "private-subnet" }
}

# Друга приватна підмережа для покриття другої AZ (вимагається для RDS і Redis)
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-1b"
  tags = { Name = "private-subnet-b" }
}

# Internet Gateway — забезпечує вихід в Інтернет для EC2 у публічній мережі
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "main-igw" }
}

# Маршрутна таблиця для публічної мережі з виходом у Інтернет
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

# Прив’язка маршрутної таблиці до публічної підмережі
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ============================
#  Групи безпеки
# ============================

# Дозволяє HTTP (80) і SSH (22) з будь-яких IP (тільки для EC2)
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Група безпеки для RDS і Redis — доступ дозволено лише з EC2 (SG ID)
resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Allow DB access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ============================
#  RDS MySQL
# ============================

# Група підмереж для RDS (2 AZ вимагається AWS)
resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_b.id]
}

# RDS MySQL інстанс для WordPress
resource "aws_db_instance" "wordpress" {
  identifier             = "wordpress-db"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"  # Free Tier
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_user
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false  # закрито ззовні
}

# ============================
#  Redis (ElastiCache)
# ============================

# Група підмереж для Redis
resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_b.id]
}

# Redis кластер для збереження сесій
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "wordpress-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"  # Free Tier-compatible
  num_cache_nodes      = 1
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.db_sg.id]
  parameter_group_name = "default.redis7"
}

# ============================
#  Template для деплою WordPress
# ============================

# Передає змінні в bash-шаблон (deploy.sh.tpl)
data "template_file" "deploy_script" {
  template = file("../scripts/deploy.sh.tpl")
  vars = {
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
    db_host     = aws_db_instance.wordpress.address
    redis_host  = aws_elasticache_cluster.redis.cache_nodes[0].address
  }
}

# ============================
#  EC2 інстанс з WordPress
# ============================

resource "aws_instance" "wordpress" {
  ami                         = "ami-0df368112825f8d8f"  # Ubuntu 24.04 (Free Tier)
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  key_name                    = "abzkey"  # попередньо створений SSH ключ
  user_data                   = data.template_file.deploy_script.rendered

  tags = {
    Name = "wordpress-instance"
  }
}


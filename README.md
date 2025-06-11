
# ABZ Test Assignment: AWS WordPress Infrastructure

---

## 🧱 Структура проєкту
```
├── terraform/           # Terraform конфігурації
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── scripts/
│   └── deploy.sh.tpl       # Скрипт для автоматичного розгортання WordPress
├── wordpress/
│   └── wp-config.php    # WordPress конфігурація через змінні середовища
└── README.md            # Цей файл
```

## 🚀 Деплой

### 1. Підготовка
Встановити:
- [Terraform](https://www.terraform.io/downloads)
- AWS CLI (та налаштувати профіль)
- в фалі variables.tf прописуємо свої значення для MYSQL RDS, також там є перемінна "key_name" її можна ввести в самому фалі або ж при ініціалізації запитає ім'я ssh ключа по якому будемо підключатись, який спочатку потрібно додати в панелі AWC EC2, а потім виконувати скрипт terraform.

### 2. Ініціалізація Terraform
```bash
cd terraform
terraform init
terraform apply
```

### 3. Вихідні значення
Після деплою ви отримаєте:
- `ec2_public_ip`
- `rds_endpoint`
- `redis_endpoint`

Використайте їх як змінні середовища у WordPress(потрібні змінні за допомогою скрипта deploy.sh.tpl передаються в файл wp-config.php).

---

## 🌐 Змінні середовища для WordPress
У `wp-config.php` використовуються такі змінні:
- `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`
- `REDIS_HOST`

---

## ❗ Проблеми та вирішення
- **RDS не доступний:** перевірити Security Group EC2 і RDS. Потрібно створити 2 приватні підмережі так як на 1-ій не вийшло запустити (вимагається для RDS і Redis)
- **Redis не працює:** перевірити, чи endpoint Redis не заблокований вхідним трафіком.
- **Nginx не стартує:** запустити `nginx -t` для перевірки конфігурації.

	

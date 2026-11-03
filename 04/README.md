# Домашнее задание «Продвинутые методы работы с Terraform»

Ветка: terraform-04. Код лежит в трёх папках рядом с этим файлом: src (задания 1-6*), vault (задание 7*) и task8 (задание 8*, два отдельных корневых модуля). Личные данные (cloud_id, folder_id, зона) вынесены в personal.auto.tfvars, он в .gitignore и в репозиторий не попал. Ключ сервисного аккаунта лежит вне репозитория (~/.authorized_key.json). Полный код всех файлов приложен в самом конце.

Версия Terraform у меня 1.16.x, поэтому ограничение "~>1.12.0" (разрешает только 1.12.x) мне не подходит. Во всех providers.tf я поставил ">= 1.12.0". Все ВМ прерываемые (preemptible = true), платформа standard-v3 с долей ядра 20%, все значения вынесены в переменные.

## Подготовка

- Создал новый сервисный аккаунт terraform-sa (старый я удалял вместе с ресурсами прошлого задания), выдал ему роль editor на каталог и выпустил ключ в ~/.authorized_key.json.
- В исходном проекте провайдер настроен на OAuth-токен. Я перевёл его на ключ сервисного аккаунта (service_account_key_file) и убрал переменную token.
- Создал ветку terraform-04 и скопировал исходники из 04/src в свой репозиторий.
- Зону поставил ru-central1-d в личном файле. В ней в этот раз всё создавалось без проблем.

![сервисный аккаунт](screenshots/task0/01_service_account.png)

![роль editor](screenshots/task0/02_role_editor.png)

![ключ](screenshots/task0/03_key.png)

## Задание 1

Взял код из демонстрации к лекции и сделал два вызова remote-модуля (git::https://github.com/udjin10/yandex_compute_instance.git): marketing_vm и analytics_vm. Принадлежность к проекту указана через labels (owner и project). Перед написанием кода я открыл файлы модуля, чтобы понять, какие параметры он принимает. Параметр preemptible там есть и по умолчанию true, но я всё равно передаю его явно через переменную, чтобы это было видно в коде. Платформу по умолчанию модуль ставит standard-v1, я передал standard-v3 с долей ядра 20.

![переменные модуля, часть 1](screenshots/task1/01_module_variables_1.png)

![переменные модуля, часть 2](screenshots/task1/02_module_variables_2.png)

![main.tf модуля, часть 1](screenshots/task1/03_module_main_1.png)

![main.tf модуля, часть 2](screenshots/task1/04_module_main_2.png)

**cloud-init.yml.** Вместо хардкода ключа в файле стоят переменные шаблона, а значения передаются в функцию template_file в блоке vars. Ключ в ssh_authorized_keys это элемент списка (а не строка), поэтому он записан как отдельная строка списка. Установка nginx добавлена через packages и запуск через runcmd:

```yaml
#cloud-config
users:
  - name: ${vm_user}
    groups: sudo
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ${ssh_public_key}
package_update: true
package_upgrade: false
packages:
  - nginx
runcmd:
  - systemctl enable --now nginx
```

```hcl
data "template_file" "cloudinit" {
  template = file("${path.module}/cloud-init.yml")
  vars = {
    vm_user        = var.vm_user
    ssh_public_key = file(var.vm_ssh_public_key_path)
  }
}
```

План и создание двух ВМ (вместе с сетью и подсетью, 4 ресурса):

![plan](screenshots/task1/05_plan.png)

![apply](screenshots/task1/06_apply.png)

![список ВМ](screenshots/task1/07_vm_list.png)

Подключился по ssh к ВМ marketing и выполнил sudo nginx -t:

![ssh](screenshots/task1/08_ssh.png)

![nginx -t](screenshots/task1/09_nginx_t.png)

Метки в консоли Yandex Cloud (owner и project: marketing / analytics, вторая метка спрятана за "+1", поэтому показал обе ВМ):

![метки analytics](screenshots/task1/14_yc_labels_analytics.png)

![метки marketing](screenshots/task1/15_yc_labels_marketing.png)

Содержимое модуля в terraform console (команда module.marketing_vm), видно labels, user-data с ключом и nginx, preemptible = true:

![console 1](screenshots/task1/10_console_module_1.png)

![console 2](screenshots/task1/11_console_module_2.png)

![console 3](screenshots/task1/12_console_module_3.png)

![console 4](screenshots/task1/13_console_module_4.png)

## Задание 2

Написал локальный модуль vpc (папка vpc). Он принимает env_name (имя сети), zone и cidr (v4_cidr_blocks), создаёт одну сеть и одну подсеть и отдаёт в корневой модуль output subnet с информацией о подсети. Версия модуля на момент этого задания:

```hcl
# vpc/variables.tf
variable "env_name" { type = string }
variable "zone"     { type = string }
variable "cidr"     { type = list(string) }

# vpc/main.tf
resource "yandex_vpc_network" "this" {
  name = var.env_name
}

resource "yandex_vpc_subnet" "this" {
  name           = "${var.env_name}-${var.zone}"
  zone           = var.zone
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = var.cidr
}

# vpc/outputs.tf
output "subnet" {
  value = yandex_vpc_subnet.this
}
```

Вызов из корневого модуля и передача параметров сети в модули ВМ:

```hcl
module "vpc_dev" {
  source   = "./vpc"
  env_name = var.vpc_name
  zone     = var.default_zone
  cidr     = var.default_cidr
}

# в модулях ВМ
network_id = module.vpc_dev.subnet.network_id
subnet_ids = [module.vpc_dev.subnet.id]
```

Тут я чуть не наступил на грабли. Когда я заменил ресурсы сети на модуль, первый план показал, что старые сеть и подсеть будут уничтожены, а новые созданы (и обе ВМ обновлены):

![plan с пересозданием 1](screenshots/task2/01_plan_recreate_1.png)

![plan с пересозданием 2](screenshots/task2/02_plan_recreate_2.png)

![plan с пересозданием 3](screenshots/task2/03_plan_recreate_3.png)

Старая и новая сеть называются одинаково (develop), а имена сетей в каталоге уникальны, поэтому создание новой при живой старой, скорее всего, упало бы, да и пересоздавать ничего не нужно. Я не стал применять этот план, а перенёс существующие ресурсы на новые адреса в состоянии командой terraform state mv:

```
terraform state mv yandex_vpc_network.develop module.vpc_dev.yandex_vpc_network.this
terraform state mv yandex_vpc_subnet.develop module.vpc_dev.yandex_vpc_subnet.this
```

![state mv](screenshots/task2/04_state_mv.png)

После этого план показал только переименование подсети (develop в develop-ru-central1-d), остальное не тронуто. Применил:

![plan после state mv](screenshots/task2/05_plan_after_mv.png)

![apply](screenshots/task2/06_apply.png)

Информация о модуле в terraform console (команда module.vpc_dev):

![console module.vpc_dev](screenshots/task2/07_console_module_vpc_dev.png)

**terraform-docs.** Сначала команда не нашлась, поставил через snap (sudo snap install terraform-docs) и сгенерировал документацию в vpc/README.md командой terraform-docs markdown table vpc.

![terraform-docs не найден](screenshots/task2/08_terraform_docs_not_found.png)

![terraform-docs установлен](screenshots/task2/09_terraform_docs_installed.png)

![сгенерированный README модуля](screenshots/task2/10_terraform_docs_readme.png)

## Задание 3

Работа со state. Выполненные команды:

```
terraform state list
terraform state rm module.vpc_dev
terraform state rm module.marketing_vm module.analytics_vm
terraform import module.vpc_dev.yandex_vpc_network.this enpheevdn25em86cfkrb
terraform import module.vpc_dev.yandex_vpc_subnet.this fl8lcjds33eg90kguis2
terraform import 'module.marketing_vm.yandex_compute_instance.vm[0]' fv4j4o1ehhi8reape0hp
terraform import 'module.analytics_vm.yandex_compute_instance.vm[0]' fv45j7jm51r7gahjkkpj
terraform plan
```

Модуль vm у меня представлен двумя вызовами (marketing_vm и analytics_vm), поэтому из состояния удалил оба. Команда state rm ничего не удаляет в облаке, Terraform просто перестаёт знать об этих ресурсах. ID для импорта взял из прошлых выводов (id сети и подсети из apply, id ВМ из yc compute instance list).

![state list](screenshots/task3/01_state_list.png)

![state rm module.vpc_dev](screenshots/task3/02_state_rm_vpc.png)

![state rm модулей ВМ](screenshots/task3/03_state_rm_vms.png)

![import сети и подсети](screenshots/task3/04_import_vpc.png)

![import ВМ](screenshots/task3/05_import_vms.png)

После импорта план показал только добавление allow_stopping_for_update = true у обеих ВМ. Это настройка, которая хранится только в конфигурации, и при импорте из облака она не подтягивается, так что это не значимое изменение: ничего не создаётся и не удаляется. Я применил его (меняется только состояние), и следующий план стал чистым.

![plan после импорта](screenshots/task3/06_plan_after_import.png)

![apply и чистый plan](screenshots/task3/07_apply_and_plan_clean.png)

## Задание 4*

Изменил модуль vpc: теперь он принимает список subnets (list(object) с полями zone и cidr) и создаёт подсеть в каждой переданной зоне через for_each. Отдаёт output network_id и subnets (словарь, ключ это зона).

```hcl
variable "subnets" {
  type = list(object({
    zone = string
    cidr = string
  }))
}

resource "yandex_vpc_subnet" "this" {
  for_each = { for s in var.subnets : s.zone => s }

  name           = "${var.env_name}-${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [each.value.cidr]
}
```

Вызовы: vpc_dev с одной подсетью (зона и cidr из переменных) и vpc_prod с тремя. Зоны a, b, c из примера в задании мне не подошли: зоны c в облаке уже нет, поэтому взял a, b и d. Ссылки в модулях ВМ поменял на module.vpc_dev.network_id и module.vpc_dev.subnets[var.default_zone].id.

Подсеть dev теперь создаётся через for_each и меняет адрес в состоянии, поэтому снова сделал state mv, чтобы не пересоздавать её. Первый раз команда упала: Terraform потребовал сначала terraform init для нового вызова модуля (vpc_prod). Сделал init и повторил:

```
terraform state mv 'module.vpc_dev.yandex_vpc_subnet.this' 'module.vpc_dev.yandex_vpc_subnet.this["ru-central1-d"]'
```

![ошибка Module not installed](screenshots/task4/01_state_mv_error.png)

![init и state mv](screenshots/task4/02_init_and_state_mv.png)

План (создаётся сеть production и три подсети, dev не тронут) и применение:

![plan 1](screenshots/task4/03_plan_1.png)

![plan 2](screenshots/task4/04_plan_2.png)

![apply](screenshots/task4/05_apply.png)

Результат в консоли Yandex Cloud: две сети и три подсети production в зонах a, b, d:

![сети](screenshots/task4/06_yc_networks.png)

![подсети production](screenshots/task4/07_yc_subnets.png)

Документацию модуля перегенерировал под новую версию:

![terraform-docs](screenshots/task4/08_terraform_docs.png)

## Задание 5*

Написал два модуля.

**mysql_cluster** создаёт кластер yandex_mdb_mysql_cluster. Принимает имя кластера, id сети, подсеть и зону. Переменная HA (bool) выбирает количество хостов: при false один хост, при true их ha_hosts_count (по умолчанию 2). Хосты задаются блоком dynamic host с for_each = range(...). Остальное (версия, класс хоста, диск) вынесено в переменные с значениями по умолчанию.

**mysql_db** создаёт базу (yandex_mdb_mysql_database) и пользователя (yandex_mdb_mysql_user) в существующем кластере. Принимает id кластера, имя базы, имя пользователя и пароль. Пароль не хранится в коде: он генерируется random_password и передаётся в модуль как sensitive-переменная.

Минимальная конфигурация. Список классов хостов смотрел командой yc managed-mysql resource-preset list. Самый дешёвый из доступных в зоне d это b2.medium (2 vCPU, 4 ГБ, burstable), диск 10 ГБ network-hdd.

![список классов хостов](screenshots/task5/01_presets_1.png)

Вызов в корневом модуле:

```hcl
module "mysql_cluster" {
  source       = "./mysql_cluster"
  cluster_name = var.mysql_cluster_name
  network_id   = module.vpc_dev.network_id
  subnet_id    = module.vpc_dev.subnets[var.default_zone].id
  zone         = var.default_zone
  HA           = var.mysql_ha
}

module "mysql_db" {
  source        = "./mysql_db"
  cluster_id    = module.mysql_cluster.cluster_id
  db_name       = var.mysql_db_name
  user_name     = var.mysql_user_name
  user_password = random_password.mysql_user.result
}
```

Сначала кластер example из одного хоста (mysql_ha = false), база test, пользователь app. План (4 ресурса) и создание (кластер создавался около 10 минут):

![plan 1](screenshots/task5/02_plan_1.png)

![plan 2](screenshots/task5/03_plan_2.png)

![plan 3](screenshots/task5/04_plan_3.png)

![apply, идёт создание](screenshots/task5/05_apply_progress.png)

![apply завершён](screenshots/task5/06_apply_done.png)

Результат в консоли: один хост (роль MASTER), база test, пользователь app:

![хост](screenshots/task5/07_yc_host.png)

![пользователь](screenshots/task5/08_yc_user.png)

![база](screenshots/task5/09_yc_database.png)

Потом поменял переменную mysql_ha на true. План показал только добавление второго хоста (update in place), остальное не менялось. Применение заняло около 11 минут. В консоли два хоста: MASTER и REPLICA.

![plan с HA](screenshots/task5/10_plan_ha.png)

![apply с HA](screenshots/task5/11_apply_ha.png)

![два хоста](screenshots/task5/12_yc_two_hosts.png)

Сразу после проверки удалил MySQL (terraform destroy с -target на оба модуля и random_password, 4 ресурса), потому что кластер платный. Чтобы последующие apply случайно не создали его заново, закомментировал вызовы в mysql.tf (сам файл с кодом остался в репозитории). План после этого чистый.

![destroy](screenshots/task5/13_destroy.png)

![plan без изменений](screenshots/task5/14_plan_no_changes.png)

## Задание 6*

Использовал готовый модуль terraform-yc-modules/terraform-yc-s3. Сначала склонировал репозиторий и посмотрел пример simple-bucket и переменные модуля. Для размера нужна переменная max_size (в байтах), поэтому поставил 1073741824 (ровно 1 ГБ). Имя бакета собирается из префикса и случайного суффикса (random_string), чтобы быть уникальным.

```hcl
module "s3" {
  source = "git::https://github.com/terraform-yc-modules/terraform-yc-s3.git"

  bucket_name = "${var.s3_bucket_prefix}-${random_string.bucket_suffix.result}"
  folder_id   = var.folder_id
  max_size    = var.s3_max_size
}
```

![клон примера](screenshots/task6/01_clone_example.png)

![переменные модуля](screenshots/task6/02_module_variables.png)

![переменные модуля, ещё](screenshots/task6/03_module_variables_2.png)

![init](screenshots/task6/04_init.png)

Тут была ошибка. План упал с Invalid provider configuration для провайдера aws и No valid credential sources found. Оказалось, что модуль использует провайдер aws (для S3 API), хотя реально в AWS не ходит: он нужен только для формирования JSON политики доступа (data aws_iam_policy_document). Terraform всё равно требует его настроить и пытается найти учётные данные в metadata-сервисе AWS, откуда и таймаут.

![ошибка плана 1](screenshots/task6/05_plan_aws_error_1.png)

![ошибка плана 2](screenshots/task6/06_plan_aws_error_2.png)

![versions.tf модуля](screenshots/task6/07_module_versions.png)

Исправил: настроил провайдер aws в providers.tf с фиктивными ключами и отключёнными проверками, которым нужен настоящий AWS. Реальный доступ к Yandex Object Storage от этого не зависит:

```hcl
provider "aws" {
  region                      = var.aws_region
  access_key                  = "not-used"
  secret_key                  = "not-used"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
}
```

После этого план прошёл (3 ресурса: два random_string и сам бакет с max_size = 1073741824) и apply создал бакет netology-bucket-j4ezwh0a:

![plan 1](screenshots/task6/08_plan_ok_1.png)

![plan 2](screenshots/task6/09_plan_ok_2.png)

![plan 3](screenshots/task6/10_plan_ok_3.png)

![apply](screenshots/task6/11_apply.png)

В консоли виден бакет и лимит 1 ГБ (0 Б / 1 ГБ):

![бакет в консоли](screenshots/task6/12_yc_bucket.png)

Бакет я не удаляю (он пригодится в следующем ДЗ). Чтобы terraform destroy в конце его не тронул, перед удалением остального убрал его из состояния командой terraform state rm module.s3 random_string.bucket_suffix. Сам бакет остался в облаке.

## Задание 7*

Vault поднял локально из docker-compose.yml демонстрации (образ vault:1.13.3, токен education). Это отдельный мини-проект в папке vault, чтобы провайдер vault не мешал основному коду (ему нужен запущенный Vault даже для plan).

![docker compose up](screenshots/task7/01_compose_up.png)

Секрет создал через веб-интерфейс: путь example, ключ test, значение congrats!

![секрет, значение скрыто](screenshots/task7/02_secret_hidden.png)

![секрет, значение показано](screenshots/task7/03_secret_shown.png)

Чтение секрета через terraform (data vault_generic_secret и output с nonsensitive). Адрес и токен вынесены в переменные. Путь secret/example сработал без изменений:

```hcl
data "vault_generic_secret" "vault_example" {
  path = var.secret_path
}

output "vault_example" {
  value = nonsensitive(data.vault_generic_secret.vault_example.data)
}
```

![apply, чтение секрета](screenshots/task7/04_apply_read.png)

Конкретный ключ через terraform console:

```
echo 'nonsensitive(data.vault_generic_secret.vault_example.data.test)' | terraform console
```

![console, ключ test](screenshots/task7/05_console_key.png)

Новый секрет записал самим Terraform ресурсом vault_generic_secret (путь secret/from_terraform, данные hello = written by terraform), потом проверил в интерфейсе Vault:

```hcl
resource "vault_generic_secret" "from_terraform" {
  path      = var.new_secret_path
  data_json = jsonencode(var.new_secret_data)
}
```

![apply, запись секрета](screenshots/task7/06_apply_write.png)

![список секретов в Vault](screenshots/task7/07_vault_list.png)

![секрет from_terraform](screenshots/task7/08_vault_from_terraform.png)

После проверки остановил контейнер (docker compose down).

## Задание 8*

Разделил корневой модуль на два отдельных (папка task8): vpc создаёт сеть и подсеть (вызывает локальный модуль vpc из src), vms создаёт ВМ. Связь через terraform remote state: vpc публикует outputs network_id и subnet_id, а vms читает их из состояния соседнего модуля. Как в демонстрации, использовал локальный backend с путём к tfstate:

```hcl
data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = var.vpc_state_path
  }
}

# в модуле ВМ
network_id = data.terraform_remote_state.vpc.outputs.network_id
subnet_ids = [data.terraform_remote_state.vpc.outputs.subnet_id]
```

Путь к состоянию (../vpc/terraform.tfstate) вынесен в переменную vpc_state_path. Бакет из задания 6* для хранения состояния я не использовал: для него нужны статические ключи доступа, а модуль бакета их не создавал, так что остановился на локальном backend.

Две проблемы по дороге:
1. Перед запуском я заранее удалил две ВМ из задания 1 (terraform destroy с -target), так как диски у меня впритык к квоте зоны, а они уже были задокументированы выше.
2. Создание сети упало с ResourceExhausted: Quota limit vpc.networks.count exceeded. В облаке лимит на количество сетей, а у меня уже было две (develop и production). Сеть production нужна была только для задания 4* и там зафиксирована скриншотами, поэтому удалил её (terraform destroy с -target=module.vpc_prod, код вызова модуля остался), после чего всё создалось.

![удаление ВМ ради квоты](screenshots/task8/01_destroy_vms_for_quota.png)

![ошибка квоты сетей](screenshots/task8/02_network_quota_error.png)

![удаление сети production](screenshots/task8/03_destroy_prod.png)

Создание VPC-модуля, затем ВМ:

![apply vpc](screenshots/task8/04_vpc_apply.png)

![apply vms](screenshots/task8/05_vms_apply.png)

Доказательство, что ВМ взяла сеть из remote state: outputs соседнего модуля (network_id и subnet_id) совпадают с subnet_id у ВМ:

![remote state](screenshots/task8/06_remote_state_proof.png)

Потом удалил ВМ, а затем VPC:

![destroy vpc](screenshots/task8/07_destroy_vpc.png)

## Удаление ресурсов

В конце удалил всё, что создавал:
- две ВМ из задания 1 (terraform destroy с -target), раньше времени, ради квоты;
- сеть production с тремя подсетями (задание 4*);
- кластер MySQL, базу и пользователя (задание 5*);
- ВМ и VPC из задания 8*;
- сеть и подсеть develop (terraform destroy в src);
- контейнер Vault (docker compose down).

Бакет netology-bucket-j4ezwh0a (1 ГБ, задание 6*) по заданию оставил, перед destroy убрал его из состояния. Потом удалил сервисный аккаунт terraform-sa и ключ. В облаке пусто: нет ВМ, дисков, сетей, подсетей и кластеров, остался только бакет.

![удаление бакета из state](screenshots/cleanup/01_state_rm_bucket.png)

![destroy в src](screenshots/cleanup/02_destroy_src.png)

![в облаке пусто, бакет остался](screenshots/cleanup/03_cloud_empty_bucket_stays.png)

![сервисный аккаунт удалён](screenshots/cleanup/04_service_account_deleted.png)

## Код проекта

### 04/src/main.tf

```hcl

data "template_file" "cloudinit" {
  template = file("${path.module}/cloud-init.yml")
  vars = {
    vm_user        = var.vm_user
    ssh_public_key = file(var.vm_ssh_public_key_path)
  }
}

module "marketing_vm" {
  source                 = "git::https://github.com/udjin10/yandex_compute_instance.git?ref=main"
  env_name               = var.vm_env_name
  network_id             = module.vpc_dev.network_id
  subnet_zones           = [var.default_zone]
  subnet_ids             = [module.vpc_dev.subnets[var.default_zone].id]
  instance_name          = var.projects.marketing
  instance_count         = var.vm_instance_count
  image_family           = var.vm_image_family
  public_ip              = var.vm_public_ip
  platform               = var.vm_platform_id
  instance_core_fraction = var.vm_core_fraction
  preemptible            = var.vm_preemptible

  labels = {
    owner   = var.vm_owner
    project = var.projects.marketing
  }

  metadata = {
    user-data          = data.template_file.cloudinit.rendered
    serial-port-enable = 1
  }
}

module "analytics_vm" {
  source                 = "git::https://github.com/udjin10/yandex_compute_instance.git?ref=main"
  env_name               = var.vm_env_name
  network_id             = module.vpc_dev.network_id
  subnet_zones           = [var.default_zone]
  subnet_ids             = [module.vpc_dev.subnets[var.default_zone].id]
  instance_name          = var.projects.analytics
  instance_count         = var.vm_instance_count
  image_family           = var.vm_image_family
  public_ip              = var.vm_public_ip
  platform               = var.vm_platform_id
  instance_core_fraction = var.vm_core_fraction
  preemptible            = var.vm_preemptible

  labels = {
    owner   = var.vm_owner
    project = var.projects.analytics
  }

  metadata = {
    user-data          = data.template_file.cloudinit.rendered
    serial-port-enable = 1
  }
}
```

### 04/src/mysql.tf

```hcl
# resource "random_password" "mysql_user" {
#   length  = 16
#   special = false
# }
# 
# module "mysql_cluster" {
#   source       = "./mysql_cluster"
#   cluster_name = var.mysql_cluster_name
#   network_id   = module.vpc_dev.network_id
#   subnet_id    = module.vpc_dev.subnets[var.default_zone].id
#   zone         = var.default_zone
#   HA           = var.mysql_ha
# }
# 
# module "mysql_db" {
#   source        = "./mysql_db"
#   cluster_id    = module.mysql_cluster.cluster_id
#   db_name       = var.mysql_db_name
#   user_name     = var.mysql_user_name
#   user_password = random_password.mysql_user.result
# }
```

### 04/src/outputs.tf

```hcl
```

### 04/src/providers.tf

```hcl
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 1.12.0"
}

provider "yandex" {
  service_account_key_file = file("~/.authorized_key.json")
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.default_zone
}

# The s3 module uses the aws provider only to render policy JSON, no calls to AWS are made.
# Keys are dummy values, the checks that need real AWS are switched off.
provider "aws" {
  region                      = var.aws_region
  access_key                  = "not-used"
  secret_key                  = "not-used"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
}
```

### 04/src/s3.tf

```hcl
resource "random_string" "bucket_suffix" {
  length  = 8
  upper   = false
  lower   = true
  numeric = true
  special = false
}

module "s3" {
  source = "git::https://github.com/terraform-yc-modules/terraform-yc-s3.git"

  bucket_name = "${var.s3_bucket_prefix}-${random_string.bucket_suffix.result}"
  folder_id   = var.folder_id
  max_size    = var.s3_max_size
}
```

### 04/src/variables.tf

```hcl
###cloud vars

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}
variable "default_cidr" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}

variable "vpc_name" {
  type        = string
  default     = "develop"
  description = "VPC network&subnet name"
}

###common vars

variable "vms_ssh_root_key" {
  type        = string
  default     = "your_ssh_ed25519_key"
  description = "ssh-keygen -t ed25519"
}

###example vm_web var
variable "vm_web_name" {
  type        = string
  default     = "netology-develop-platform-web"
  description = "example vm_web_ prefix"
}

###example vm_db var
variable "vm_db_name" {
  type        = string
  default     = "netology-develop-platform-db"
  description = "example vm_db_ prefix"
}




###vm vars (task 1)

variable "vm_ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  description = "Path to the public ssh key that goes to cloud-init"
}

variable "vm_user" {
  type        = string
  default     = "ubuntu"
  description = "User created on the VMs by cloud-init"
}

variable "vm_image_family" {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "Image family for the VMs"
}

variable "vm_env_name" {
  type        = string
  default     = "develop"
  description = "Environment name passed to the VM modules"
}

variable "vm_public_ip" {
  type        = bool
  default     = true
  description = "Assign public IP to the VMs"
}

variable "vm_instance_count" {
  type        = number
  default     = 1
  description = "How many VMs each module call creates"
}

variable "projects" {
  type = object({
    marketing = string
    analytics = string
  })
  default = {
    marketing = "marketing"
    analytics = "analytics"
  }
  description = "Project names used in VM names and labels"
}

variable "vm_owner" {
  type        = string
  default     = "daneenal"
  description = "Value of the owner label"
}

variable "vm_platform_id" {
  type        = string
  default     = "standard-v3"
  description = "Platform of the VMs"
}

variable "vm_core_fraction" {
  type        = number
  default     = 20
  description = "Guaranteed CPU share, 20 is the minimum for standard-v3"
}

variable "vm_preemptible" {
  type        = bool
  default     = true
  description = "Preemptible VMs to save money"
}

###vpc module vars (task 4)

variable "vpc_prod_name" {
  type        = string
  default     = "production"
  description = "Name of the production network"
}

variable "prod_subnets" {
  type = list(object({
    zone = string
    cidr = string
  }))
  default = [
    { zone = "ru-central1-a", cidr = "10.10.1.0/24" },
    { zone = "ru-central1-b", cidr = "10.10.2.0/24" },
    { zone = "ru-central1-d", cidr = "10.10.3.0/24" },
  ]
  description = "Subnets of the production network, one per availability zone"
}

###s3 bucket vars (task 6)

variable "s3_bucket_prefix" {
  type        = string
  default     = "netology-bucket"
  description = "Prefix of the bucket name, a random suffix is added to keep it unique"
}

variable "s3_max_size" {
  type        = number
  default     = 1073741824
  description = "Maximum bucket size in bytes (1 GB)"
}

variable "aws_region" {
  type        = string
  default     = "ru-central1"
  description = "Region name for the aws provider, it is only used to build the policy JSON in the s3 module"
}

###mysql vars (task 5)

variable "mysql_cluster_name" {
  type        = string
  default     = "example"
  description = "Name of the MySQL cluster"
}

variable "mysql_ha" {
  type        = bool
  default     = true
  description = "false is a single host cluster, true is a cluster of two hosts"
}

variable "mysql_db_name" {
  type        = string
  default     = "test"
  description = "Name of the database created in the cluster"
}

variable "mysql_user_name" {
  type        = string
  default     = "app"
  description = "Name of the database user"
}
```

### 04/src/vpc.tf

```hcl
module "vpc_dev" {
  source   = "./vpc"
  env_name = var.vpc_name
  subnets = [
    { zone = var.default_zone, cidr = var.default_cidr[0] },
  ]
}

module "vpc_prod" {
  source   = "./vpc"
  env_name = var.vpc_prod_name
  subnets  = var.prod_subnets
}
```

### 04/src/cloud-init.yml

```yaml
#cloud-config
users:
  - name: ${vm_user}
    groups: sudo
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ${ssh_public_key}
package_update: true
package_upgrade: false
packages:
  - nginx
runcmd:
  - systemctl enable --now nginx
```

### 04/src/personal.auto.tfvars_example

```
token  =  ""
cloud_id  = ""
folder_id = ""```

### 04/src/vpc/main.tf

```hcl
resource "yandex_vpc_network" "this" {
  name = var.env_name
}

resource "yandex_vpc_subnet" "this" {
  for_each = { for s in var.subnets : s.zone => s }

  name           = "${var.env_name}-${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [each.value.cidr]
}
```

### 04/src/vpc/outputs.tf

```hcl
output "network_id" {
  description = "Id of the created network"
  value       = yandex_vpc_network.this.id
}

output "subnets" {
  description = "Created yandex_vpc_subnet resources, key is the zone"
  value       = yandex_vpc_subnet.this
}
```

### 04/src/vpc/variables.tf

```hcl
variable "env_name" {
  type        = string
  description = "Name of the network, also used in the subnet names"
}

variable "subnets" {
  type = list(object({
    zone = string
    cidr = string
  }))
  description = "Subnets to create: availability zone and CIDR of each one"
}
```

### 04/src/vpc/versions.tf

```hcl
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}
```

### 04/src/mysql_cluster/main.tf

```hcl
resource "yandex_mdb_mysql_cluster" "this" {
  name                = var.cluster_name
  environment         = var.environment
  network_id          = var.network_id
  version             = var.mysql_version
  deletion_protection = false

  resources {
    resource_preset_id = var.resource_preset_id
    disk_type_id       = var.disk_type_id
    disk_size          = var.disk_size
  }

  dynamic "host" {
    for_each = range(var.HA ? var.ha_hosts_count : 1)
    content {
      zone      = var.zone
      subnet_id = var.subnet_id
    }
  }
}
```

### 04/src/mysql_cluster/outputs.tf

```hcl
output "cluster_id" {
  description = "Id of the MySQL cluster"
  value       = yandex_mdb_mysql_cluster.this.id
}
```

### 04/src/mysql_cluster/variables.tf

```hcl
variable "cluster_name" {
  type        = string
  description = "Name of the MySQL cluster"
}

variable "network_id" {
  type        = string
  description = "Id of the network where the cluster lives"
}

variable "subnet_id" {
  type        = string
  description = "Subnet for the cluster hosts"
}

variable "zone" {
  type        = string
  description = "Availability zone of the cluster hosts, must match the subnet"
}

variable "HA" {
  type        = bool
  default     = false
  description = "true creates ha_hosts_count hosts, false creates a single host"
}

variable "ha_hosts_count" {
  type        = number
  default     = 2
  description = "Number of hosts when HA is true"
}

variable "environment" {
  type        = string
  default     = "PRESTABLE"
  description = "PRESTABLE or PRODUCTION"
}

variable "mysql_version" {
  type        = string
  default     = "8.0"
  description = "MySQL version"
}

variable "resource_preset_id" {
  type        = string
  default     = "b2.medium"
  description = "Host class, b2.medium is the cheapest one available in zone d"
}

variable "disk_type_id" {
  type        = string
  default     = "network-hdd"
  description = "Disk type of the hosts"
}

variable "disk_size" {
  type        = number
  default     = 10
  description = "Disk size of a host in GB"
}
```

### 04/src/mysql_cluster/versions.tf

```hcl
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}
```

### 04/src/mysql_db/main.tf

```hcl
resource "yandex_mdb_mysql_database" "this" {
  cluster_id = var.cluster_id
  name       = var.db_name
}

resource "yandex_mdb_mysql_user" "this" {
  cluster_id = var.cluster_id
  name       = var.user_name
  password   = var.user_password

  permission {
    database_name = yandex_mdb_mysql_database.this.name
    roles         = var.user_roles
  }
}
```

### 04/src/mysql_db/variables.tf

```hcl
variable "cluster_id" {
  type        = string
  description = "Id of the existing MySQL cluster"
}

variable "db_name" {
  type        = string
  description = "Name of the database"
}

variable "user_name" {
  type        = string
  description = "Name of the database user"
}

variable "user_password" {
  type        = string
  sensitive   = true
  description = "Password of the database user"
}

variable "user_roles" {
  type        = list(string)
  default     = ["ALL"]
  description = "Roles of the user on the database"
}
```

### 04/src/mysql_db/versions.tf

```hcl
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}
```

### 04/task8/vpc/main.tf

```hcl
module "vpc" {
  source   = "../../src/vpc"
  env_name = var.vpc_name
  subnets = [
    { zone = var.default_zone, cidr = var.vpc_cidr },
  ]
}
```

### 04/task8/vpc/outputs.tf

```hcl
output "network_id" {
  description = "Network id for the vms root module"
  value       = module.vpc.network_id
}

output "subnet_id" {
  description = "Subnet id for the vms root module"
  value       = module.vpc.subnets[var.default_zone].id
}
```

### 04/task8/vpc/providers.tf

```hcl
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 1.12.0"
}

provider "yandex" {
  service_account_key_file = file("~/.authorized_key.json")
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.default_zone
}
```

### 04/task8/vpc/variables.tf

```hcl
variable "cloud_id" {
  type        = string
  description = "Cloud id"
}

variable "folder_id" {
  type        = string
  description = "Folder id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-d"
  description = "Availability zone"
}

variable "vpc_name" {
  type        = string
  default     = "split"
  description = "Network name"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.20.1.0/24"
  description = "CIDR of the subnet"
}
```

### 04/task8/vms/main.tf

```hcl
data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = var.vpc_state_path
  }
}

data "template_file" "cloudinit" {
  template = file("${path.module}/cloud-init.yml")
  vars = {
    vm_user        = var.vm_user
    ssh_public_key = file(var.vm_ssh_public_key_path)
  }
}

module "vm" {
  source         = "git::https://github.com/udjin10/yandex_compute_instance.git?ref=main"
  env_name       = var.vm_env_name
  network_id     = data.terraform_remote_state.vpc.outputs.network_id
  subnet_zones   = [var.default_zone]
  subnet_ids     = [data.terraform_remote_state.vpc.outputs.subnet_id]
  instance_name  = var.vm_name
  instance_count = 1
  image_family   = var.vm_image_family
  platform       = var.vm_platform_id
  public_ip      = var.vm_public_ip

  instance_core_fraction = var.vm_core_fraction
  preemptible            = var.vm_preemptible

  labels = {
    project = var.vm_name
  }

  metadata = {
    user-data          = data.template_file.cloudinit.rendered
    serial-port-enable = 1
  }
}
```

### 04/task8/vms/providers.tf

```hcl
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 1.12.0"
}

provider "yandex" {
  service_account_key_file = file("~/.authorized_key.json")
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.default_zone
}
```

### 04/task8/vms/variables.tf

```hcl
variable "cloud_id" {
  type        = string
  description = "Cloud id"
}

variable "folder_id" {
  type        = string
  description = "Folder id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-d"
  description = "Availability zone"
}

variable "vm_name" {
  type        = string
  default     = "split"
  description = "Name of the VM"
}

variable "vm_env_name" {
  type        = string
  default     = "develop"
  description = "Environment name passed to the VM module"
}

variable "vm_user" {
  type        = string
  default     = "ubuntu"
  description = "User created on the VM by cloud-init"
}

variable "vm_ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  description = "Path to the public ssh key"
}

variable "vm_image_family" {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "Image family"
}

variable "vm_platform_id" {
  type        = string
  default     = "standard-v3"
  description = "Platform of the VM"
}

variable "vm_core_fraction" {
  type        = number
  default     = 20
  description = "Guaranteed CPU share"
}

variable "vm_preemptible" {
  type        = bool
  default     = true
  description = "Preemptible VM to save money"
}

variable "vm_public_ip" {
  type        = bool
  default     = true
  description = "Assign public IP"
}

variable "vpc_state_path" {
  type        = string
  default     = "../vpc/terraform.tfstate"
  description = "Path to the state file of the vpc root module"
}
```

### 04/task8/vms/cloud-init.yml

```yaml
#cloud-config
users:
  - name: ${vm_user}
    groups: sudo
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ${ssh_public_key}
package_update: true
package_upgrade: false
packages:
  - nginx
runcmd:
  - systemctl enable --now nginx
```

### 04/vault/main.tf

```hcl
data "vault_generic_secret" "vault_example" {
  path = var.secret_path
}

output "vault_example" {
  value = nonsensitive(data.vault_generic_secret.vault_example.data)
}

resource "vault_generic_secret" "from_terraform" {
  path      = var.new_secret_path
  data_json = jsonencode(var.new_secret_data)
}
```

### 04/vault/providers.tf

```hcl
terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
    }
  }
  required_version = ">= 1.12.0"
}

provider "vault" {
  address         = var.vault_address
  skip_tls_verify = true
  token           = var.vault_token
}
```

### 04/vault/variables.tf

```hcl
variable "vault_address" {
  type        = string
  default     = "http://127.0.0.1:8200"
  description = "Address of the local Vault from docker-compose"
}

variable "vault_token" {
  type        = string
  default     = "education"
  sensitive   = true
  description = "Dev root token of the local Vault, it is public in the task and docker-compose"
}

variable "secret_path" {
  type        = string
  default     = "secret/example"
  description = "Path of the secret created in the web interface"
}

variable "new_secret_path" {
  type        = string
  default     = "secret/from_terraform"
  description = "Path of the secret that Terraform writes itself"
}

variable "new_secret_data" {
  type        = map(string)
  default     = { hello = "written by terraform" }
  description = "Data of the secret that Terraform writes to Vault"
}
```

### 04/vault/docker-compose.yml

```yaml
services:
  vault:
      image: vault:1.13.3
      environment:
        VAULT_ADDR: "http://0.0.0.0:8200"
        VAULT_API_ADDR: "http://0.0.0.0:8200"
        VAULT_DEV_ROOT_TOKEN_ID: "education"
        VAULT_DEV_LISTEN_ADDRESS: "0.0.0.0:8200"
      ports:
        - "8200:8200"
      cap_add:
        - IPC_LOCK
```

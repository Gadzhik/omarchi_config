# GNS3 на Omarchy (Arch + Hyprland)

Подготовлено под эту машину: Intel Core Ultra 5 125H, KVM работает,
QEMU 11.0.2 и Docker уже установлены, `yay` есть.

---

## 1. Установка

В официальных репозиториях Arch GNS3 нет — всё из AUR.

```bash
yay -S gns3-gui-2 gns3-server-2 ubridge vpcs
```

**Почему `-2`.** В AUR лежат два набора пакетов:

| Пакет | Версия | Что это |
|---|---|---|
| `gns3-gui-2` / `gns3-server-2` | 2.2.60 | стабильная ветка 2.2 — рекомендую |
| `gns3-gui` / `gns3-server` | 3.1.0a4 | **альфа** ветки 3.1 |

Ветка 2.2 — то, под что написана вся документация и все шаблоны из
Marketplace. Версии GUI и сервера обязаны совпадать по мажору, смешивать 2.2 и
3.x нельзя.

Опционально, только если у тебя есть **лицензионные** образы Cisco IOS для
классических маршрутизаторов (7200, 3725 и т.п.):

```bash
yay -S dynamips
```

Для образов в формате qcow2 (CSR1000v, Cat8000v, ASAv, vEOS, VyOS) dynamips не
нужен — они запускаются через QEMU/KVM.

---

## 2. Группы

Нужна ровно одна группа. Docker, kvm и libvirt у тебя уже есть.

```bash
sudo usermod -aG wireshark $USER
```

**`wireshark`** — захват пакетов на линке правой кнопкой прямо в GNS3.

Группы `ubridge` в Arch **нет** — это соглашение Debian/Ubuntu, где пакет от
GNS3 создаёт группу и ставит бинарник setuid. Здесь права выданы через
capabilities прямо на файле:

```bash
getcap /usr/bin/ubridge
# /usr/bin/ubridge cap_net_admin,cap_net_raw=ep
```

Этого достаточно для создания интерфейсов и захвата сырых пакетов, причём
привилегии есть только у самого `ubridge`, а не у всех членов какой-то группы.
Добавлять пользователя никуда не нужно.

После этого **перелогиниться** (выйти из сессии Hyprland и войти заново).
`newgrp` в терминале даст группы только этому терминалу, а GUI запускается из
сессии — ему это не поможет.

Проверка после входа:

```bash
id -nG        # должна быть wireshark
ls -l /dev/kvm
getcap /usr/bin/ubridge   # ожидаются cap_net_admin,cap_net_raw
```

---

## 3. Первый запуск

```bash
gns3
```

GUI сам поднимет локальный сервер. В мастере первого запуска выбрать
**"Run appliances on my local computer"** — это правильный режим для ноутбука,
удалённый сервер и GNS3 VM тут не нужны, KVM есть нативно.

Проверить, что виртуализация подхватилась: *Edit → Preferences → QEMU* —
в путях должен быть `/usr/bin/qemu-system-x86_64`, а у шаблонов машин
включается **KVM acceleration**. Без KVM всё поедет на эмуляции и будет
неприлично медленным.

### Если GNS3 ругается на нехватку памяти под узлы

У тебя 16-поточный CPU, но ОЗУ конечна. Для лабы из 6–8 маршрутизаторов ставь
каждому 512 МБ–1 ГБ, иначе qemu начнёт свопиться.

---

## 4. Легальные образы

### Cisco

| Источник | Что даёт | Условия |
|---|---|---|
| [Cisco Modeling Labs (CML) Personal](https://www.cisco.com/go/cml) | IOSv, IOSvL2, IOL, Cat8000v, NX-OSv 9000, ASAv | платно, ~$199/год |
| [Cisco DevNet Sandbox](https://developer.cisco.com/site/sandbox/) | готовые лаборатории с реальным железом и CML | бесплатно, по резервированию |
| [Packet Tracer](https://www.netacad.com/) | собственный симулятор Cisco | бесплатно с аккаунтом NetAcad |
| [software.cisco.com](https://software.cisco.com/) | штатные загрузки образов | нужен контракт поддержки |

CML Personal — единственный легальный способ получить именно те образы, ради
которых обычно идут в пиратские репозитории. Купив подписку, образы можно
выгрузить и запускать в GNS3, а не только в самом CML.

### Свободные и бесплатные образы для GNS3

Эти ставятся штатно и ничего не нарушают:

| Образ | Где брать | Заметки |
|---|---|---|
| **VyOS** | [vyos.net](https://vyos.net/get/nightly-builds/) | полноценный роутер, BGP/OSPF/MPLS/VPN; rolling-сборки бесплатны |
| **FRRouting** | [frrouting.org](https://frrouting.org/) | тот же стек, что в проде у многих вендоров; есть контейнер в Marketplace |
| **Arista vEOS-lab** | [arista.com](https://www.arista.com/en/support/software-download) | бесплатно после регистрации; CLI очень близок к Cisco |
| **Nokia SR Linux** | [github.com/nokia/srlinux-container-image](https://github.com/nokia/srlinux-container-image) | контейнер, свободно |
| **Cumulus VX** | [nvidia.com](https://www.nvidia.com/en-us/networking/ethernet-switching/cumulus-vx/) | Linux-свитч, бесплатно |
| **vJunos-router / vJunos-switch** | [juniper.net/vjunos-labs](https://www.juniper.net/us/en/dm/vjunos-labs.html) | Junos бесплатно для лабораторий |
| **MikroTik CHR** | [mikrotik.com/download](https://mikrotik.com/download) | free-лицензия с лимитом 1 Мбит/с на порт |
| **pfSense / OPNsense** | сайты проектов | межсетевые экраны |
| **Alpine, Debian, Ubuntu cloud** | зеркала дистрибутивов | хосты и серверы в лабе |

**[GNS3 Marketplace](https://www.gns3.com/marketplace/appliances)** — каталог
`.gns3a`-шаблонов. Импортируешь шаблон, GNS3 сам подскажет, какой файл образа
нужен и откуда его качать у вендора. Для свободных образов скачивание идёт
прямо из GUI.

> Ссылки вендоров периодически переезжают — если какая-то не открылась, ищи по
> названию продукта на сайте вендора.

### Чем заменить конкретные железки Cisco

| Хотелось | Свободная замена | Что сохраняется |
|---|---|---|
| IOSv, 7200 | VyOS, FRRouting | OSPF, BGP, статика, VRF, туннели |
| IOSvL2, свитчи | Cumulus VX, vEOS | VLAN, trunk, STP, LACP |
| ASA / FTD | pfSense, OPNsense, VyOS | NAT, зоны, правила, IPsec |
| NX-OS | SR Linux, vEOS | EVPN/VXLAN, фабрики |

Синтаксис команд отличается, но протоколы и топологии — те же. Для подготовки к
сертификации Cisco логичнее взять CML: там образы те самые и с лицензией.

---

## 5. Если что-то не заработало

**GNS3 не видит KVM.** Проверить `ls -l /dev/kvm` и членство в группе `kvm`.
Здесь всё уже настроено, проблема возможна только после смены железа.

**Узлы не соединяются, ошибки ubridge.** Проверь `getcap /usr/bin/ubridge` —
должны быть `cap_net_admin,cap_net_raw=ep`. Capabilities слетают при обновлении
пакета, если сборка их не проставила; вернуть можно так:
`sudo setcap cap_net_admin,cap_net_raw=ep /usr/bin/ubridge`

**Не работает захват пакетов.** Группа `wireshark` плюс перелогин.

**Конфликт с libvirt/virt-manager.** Обе системы используют KVM параллельно без
проблем, но одну и ту же виртуалку одновременно не запустить. Если GNS3 жалуется
на занятые адреса, проверь мосты: `ip link show type bridge`.

**Логи сервера:** `~/.config/GNS3/gns3_server.log` и вывод самого `gns3` в
терминале — при запуске из терминала видны реальные ошибки, а не только
диалоговое окно.

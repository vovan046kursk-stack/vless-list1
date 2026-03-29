import requests
import re
import os
from collections import defaultdict

URL = "https://xn--80awhlbd7d.xn--p1ai/generate"

COUNT = 30
OUTPUT_COUNT = 5

ENDPOINT_IP = "46.243.235.199"

BASE_DIR = os.getcwd()


def fetch():
    try:
        r = requests.post(URL, timeout=10)
        if r.status_code != 200:
            return None

        text = r.text
        start = text.find("[Interface]")
        if start != -1:
            return text[start:].strip()
    except Exception as e:
        print(f"⚠️ fetch error: {e}")

    return None


def fix(cfg):
    # фикс endpoint
    return re.sub(
        r'Endpoint\s*=\s*.*:51820',
        f'Endpoint = {ENDPOINT_IP}:51820',
        cfg
    ).strip()


def get_subnet(cfg):
    match = re.search(r'Address\s*=\s*10\.8\.(\d+)\.', cfg)
    return int(match.group(1)) if match else None


def main():
    print("🚀 Генерация конфигов...")

    subnets = defaultdict(list)

    # сбор конфигов
    for _ in range(COUNT):
        cfg = fetch()
        if not cfg:
            continue

        cfg = fix(cfg)

        subnet = get_subnet(cfg)
        if subnet is not None:
            subnets[subnet].append(cfg)

    # сортировка
    sorted_subnets = sorted(
        subnets.items(),
        key=lambda x: len(x[1]),
        reverse=True
    )

    best_configs = []

    for _, cfgs in sorted_subnets:
        best_configs.extend(cfgs)

    # добивка если мало
    if len(best_configs) < OUTPUT_COUNT:
        for _, cfgs in sorted_subnets:
            for cfg in cfgs:
                if cfg not in best_configs:
                    best_configs.append(cfg)
                    if len(best_configs) >= OUTPUT_COUNT:
                        break
            if len(best_configs) >= OUTPUT_COUNT:
                break

    best_configs = best_configs[:OUTPUT_COUNT]

    if not best_configs:
        print("❌ ничего не найдено")
        return

    print(f"🔥 выбрано {len(best_configs)} конфигов")

    # очистка старых файлов (ВАЖНО для GitHub)
    for file in os.listdir(BASE_DIR):
        if file.endswith(".conf"):
            os.remove(os.path.join(BASE_DIR, file))

    # сохранение
    for i, cfg in enumerate(best_configs, start=1):
        filename = os.path.join(BASE_DIR, f"vpn{i}.conf")

        with open(filename, "w", encoding="utf-8") as f:
            f.write(cfg)

        print(f"✔ {filename}")

    print("💀 Готово")


if __name__ == "__main__":
    main()
    import json
from awg_to_amnezia import parse_wg_config, build_amnezia_json

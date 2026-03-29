import json
import re

def parse_wg_config(cfg):
    data = {}

    def get(key):
        match = re.search(rf"{key}\s*=\s*(.+)", cfg)
        return match.group(1).strip() if match else ""

    data["private_key"] = get("PrivateKey")
    data["address"] = get("Address")
    data["dns"] = get("DNS")
    data["public_key"] = get("PublicKey")
    data["preshared_key"] = get("PresharedKey")
    data["endpoint"] = get("Endpoint")
    data["allowed_ips"] = get("AllowedIPs")
    data["keepalive"] = get("PersistentKeepalive")

    return data


def build_amnezia_json(wg):
    host, port = wg["endpoint"].split(":")

    return {
        "containers": [
            {
                "type": "wireguard",
                "name": "awg-auto",
                "config": {
                    "private_key": wg["private_key"],
                    "address": wg["address"],
                    "dns": wg["dns"].split(","),
                    "peer": {
                        "public_key": wg["public_key"],
                        "preshared_key": wg["preshared_key"],
                        "endpoint": host,
                        "port": int(port),
                        "allowed_ips": wg["allowed_ips"],
                        "persistent_keepalive": int(wg["keepalive"]) if wg["keepalive"] else 25
                    }
                }
            }
        ]
    }


# пример использования
if __name__ == "__main__":
    with open("vpn1.conf", "r", encoding="utf-8") as f:
        cfg = f.read()

    wg = parse_wg_config(cfg)
    amnezia = build_amnezia_json(wg)

    with open("vpn1.json", "w", encoding="utf-8") as f:
        json.dump(amnezia, f, indent=2)

    print("✔ Готово: vpn1.json")

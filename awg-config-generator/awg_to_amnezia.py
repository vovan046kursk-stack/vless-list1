import re


def parse_wg_config(cfg):
    def get(key):
        match = re.search(rf"{key}\s*=\s*(.+)", cfg)
        return match.group(1).strip() if match else ""

    return {
        "private_key": get("PrivateKey"),
        "address": get("Address"),
        "dns": get("DNS"),
        "public_key": get("PublicKey"),
        "preshared_key": get("PresharedKey"),
        "endpoint": get("Endpoint"),
        "allowed_ips": get("AllowedIPs"),
        "keepalive": get("PersistentKeepalive"),
    }


def build_amnezia_json(wg):
    return {
        "version": 1,
        "containers": [
            {
                "type": "awg",
                "name": "awg-auto",
                "awg": {
                    "privateKey": wg["private_key"],
                    "address": wg["address"],
                    "dns": [x.strip() for x in wg["dns"].split(",") if x.strip()],
                    "peers": [
                        {
                            "publicKey": wg["public_key"],
                            "presharedKey": wg["preshared_key"],
                            "endpoint": wg["endpoint"],
                            "allowedIPs": ["0.0.0.0/0", "::/0"],
                            "persistentKeepalive": int(wg["keepalive"]) if wg["keepalive"] else 25
                        }
                    ]
                }
            }
        ]
    }

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

        # 🔥 AWG параметры
        "jc": get("Jc"),
        "jmin": get("Jmin"),
        "jmax": get("Jmax"),
        "s1": get("S1"),
        "s2": get("S2"),
        "h1": get("H1"),
        "h2": get("H2"),
        "h3": get("H3"),
        "h4": get("H4"),
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

                    # 🔥 AWG ОБФУСКАЦИЯ (КРИТИЧНО)
                    "jc": int(wg["jc"]) if wg["jc"] else 4,
                    "jmin": int(wg["jmin"]) if wg["jmin"] else 40,
                    "jmax": int(wg["jmax"]) if wg["jmax"] else 70,
                    "s1": int(wg["s1"]) if wg["s1"] else 29,
                    "s2": int(wg["s2"]) if wg["s2"] else 15,
                    "h1": int(wg["h1"]) if wg["h1"] else 0,
                    "h2": int(wg["h2"]) if wg["h2"] else 0,
                    "h3": int(wg["h3"]) if wg["h3"] else 0,
                    "h4": int(wg["h4"]) if wg["h4"] else 0,

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

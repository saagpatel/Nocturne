#!/usr/bin/env python3
"""Build Nocturne's compact Gaia DR3 display catalog."""

import csv
import io
import os
import sqlite3
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT = os.path.join(ROOT, "Nocturne", "Resources", "gaia_dr3.sqlite")
TAP_URL = "https://gea.esac.esa.int/tap-server/tap/sync"
QUERY = """SELECT source_id, ra, dec, phot_g_mean_mag, bp_rp
FROM gaiadr3.gaia_source
WHERE phot_g_mean_mag <= 7.0 AND ra IS NOT NULL AND dec IS NOT NULL
ORDER BY source_id"""


def download_stars():
    payload = urllib.parse.urlencode(
        {"REQUEST": "doQuery", "LANG": "ADQL", "FORMAT": "csv", "QUERY": QUERY}
    ).encode()
    request = urllib.request.Request(
        TAP_URL, data=payload, headers={"User-Agent": "Nocturne catalog builder/1.0"}
    )
    with urllib.request.urlopen(request, timeout=180) as response:
        rows = csv.DictReader(io.StringIO(response.read().decode("utf-8")))
        stars = [
            (
                int(row["source_id"]),
                float(row["ra"]),
                float(row["dec"]),
                float(row["phot_g_mean_mag"]),
                float(row["bp_rp"]) if row["bp_rp"].strip() else None,
            )
            for row in rows
        ]
    if len(stars) < 20_000:
        raise RuntimeError(f"Gaia query returned only {len(stars):,} rows")
    return stars


def write_database(stars):
    if os.path.exists(OUTPUT):
        os.remove(OUTPUT)
    connection = sqlite3.connect(OUTPUT)
    cursor = connection.cursor()
    cursor.executescript("""
        CREATE TABLE stars (
            id INTEGER PRIMARY KEY, ra REAL NOT NULL, dec REAL NOT NULL,
            vmag REAL NOT NULL, bv REAL
        );
        CREATE INDEX idx_stars_vmag ON stars (vmag);
        CREATE TABLE provenance (
            source TEXT NOT NULL, query TEXT NOT NULL, credit TEXT NOT NULL
        );
    """)
    cursor.executemany(
        "INSERT INTO stars (id, ra, dec, vmag, bv) VALUES (?, ?, ?, ?, ?)", stars
    )
    cursor.execute(
        "INSERT INTO provenance VALUES (?, ?, ?)",
        ("ESA Gaia DR3", QUERY, "ESA/Gaia/DPAC"),
    )
    connection.commit()
    cursor.execute("VACUUM")
    count = cursor.execute("SELECT COUNT(*) FROM stars").fetchone()[0]
    connection.close()
    print(f"Wrote {count:,} stars to {OUTPUT}")


if __name__ == "__main__":
    write_database(download_stars())

#!/usr/bin/env python3
"""
Build the Hipparcos/Tycho-2 star catalog SQLite database for Nocturne.

Primary source: VizieR Tycho-2 catalog (I/259/tyc2)
Fallback: HYG Database from GitHub

Output: Nocturne/Resources/hipparcos_tycho2.sqlite
Schema: stars(id INTEGER PRIMARY KEY, ra REAL, dec REAL, vmag REAL, bv REAL)
"""

import os
import sqlite3
import sys
import urllib.request

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
OUTPUT_PATH = os.path.join(PROJECT_ROOT, "Nocturne", "Resources", "hipparcos_tycho2.sqlite")

VIZIER_URL = (
    "https://vizier.cds.unistra.fr/viz-bin/asu-tsv?"
    "-source=I/259/tyc2&"
    "-out=TYC1,TYC2,TYC3,RAmdeg,DEmdeg,VTmag,BTmag&"
    "VTmag=<=10.0&"
    "-out.max=500000"
)

HYG_URL = (
    "https://raw.githubusercontent.com/astronexus/HYG-Database/"
    "main/hyg/CURRENT/hygdata_v41.csv"
)

MAX_VMAG = 10.0


def download_vizier():
    """Download Tycho-2 catalog from VizieR. Returns list of (id, ra, dec, vmag, bv)."""
    print(f"Downloading Tycho-2 catalog from VizieR (vmag <= {MAX_VMAG})...")
    req = urllib.request.Request(VIZIER_URL, headers={"User-Agent": "Nocturne/1.0"})
    response = urllib.request.urlopen(req, timeout=120)
    data = response.read().decode("utf-8")
    lines = data.strip().split("\n")

    stars = []
    skipped = 0
    for line in lines:
        # Skip comment lines, header lines, and separator lines
        if line.startswith("#") or line.startswith("-") or not line.strip():
            continue
        # Skip the column name and unit header lines
        if "TYC1" in line or "deg" in line:
            continue

        parts = line.split("\t")
        if len(parts) < 6:
            skipped += 1
            continue

        try:
            tyc1 = parts[0].strip()
            tyc2 = parts[1].strip()
            tyc3 = parts[2].strip()
            ra_str = parts[3].strip()
            dec_str = parts[4].strip()
            vmag_str = parts[5].strip()
            btmag_str = parts[6].strip() if len(parts) > 6 else ""

            if not ra_str or not dec_str or not vmag_str:
                skipped += 1
                continue

            ra = float(ra_str)
            dec = float(dec_str)
            vmag = float(vmag_str)

            if vmag > MAX_VMAG:
                skipped += 1
                continue

            # Composite ID from TYC1/TYC2/TYC3
            star_id = int(tyc1) * 100000 + int(tyc2) * 10 + int(tyc3)

            bv = None
            if btmag_str:
                try:
                    bv = float(btmag_str) - vmag
                except ValueError:
                    pass

            stars.append((star_id, ra, dec, vmag, bv))
        except (ValueError, IndexError):
            skipped += 1
            continue

    print(f"  Parsed {len(stars)} stars from VizieR ({skipped} rows skipped)")
    return stars


def download_hyg():
    """Fallback: Download HYG database from GitHub. Returns list of (id, ra, dec, vmag, bv)."""
    print("Falling back to HYG Database from GitHub...")
    req = urllib.request.Request(HYG_URL, headers={"User-Agent": "Nocturne/1.0"})
    response = urllib.request.urlopen(req, timeout=120)
    data = response.read().decode("utf-8")
    lines = data.strip().split("\n")

    stars = []
    # Skip header
    for line in lines[1:]:
        parts = line.split(",")
        if len(parts) < 17:
            continue

        try:
            hyg_id = int(parts[0]) if parts[0] else None
            hip = parts[1].strip()
            ra_str = parts[7].strip()
            dec_str = parts[8].strip()
            mag_str = parts[13].strip()
            ci_str = parts[16].strip()

            if not ra_str or not dec_str or not mag_str:
                continue

            vmag = float(mag_str)
            if vmag > MAX_VMAG:
                continue

            ra = float(ra_str)
            dec = float(dec_str)

            star_id = int(hip) if hip else (hyg_id if hyg_id else 0)
            if star_id == 0:
                continue

            bv = float(ci_str) if ci_str else None

            stars.append((star_id, ra, dec, vmag, bv))
        except (ValueError, IndexError):
            continue

    print(f"  Parsed {len(stars)} stars from HYG Database")
    return stars


def write_sqlite(stars):
    """Write stars to SQLite database."""
    # Remove existing file
    if os.path.exists(OUTPUT_PATH):
        os.remove(OUTPUT_PATH)

    print(f"Writing {len(stars)} stars to {OUTPUT_PATH}...")
    conn = sqlite3.connect(OUTPUT_PATH)
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE stars (
            id INTEGER PRIMARY KEY,
            ra REAL NOT NULL,
            dec REAL NOT NULL,
            vmag REAL NOT NULL,
            bv REAL
        )
    """)

    cursor.execute("CREATE INDEX idx_stars_vmag ON stars (vmag)")

    # Batch insert
    batch_size = 10000
    for i in range(0, len(stars), batch_size):
        batch = stars[i:i + batch_size]
        cursor.executemany(
            "INSERT OR IGNORE INTO stars (id, ra, dec, vmag, bv) VALUES (?, ?, ?, ?, ?)",
            batch
        )

    conn.commit()

    # Verify
    count = cursor.execute("SELECT COUNT(*) FROM stars").fetchone()[0]
    min_vmag = cursor.execute("SELECT MIN(vmag) FROM stars").fetchone()[0]
    max_vmag = cursor.execute("SELECT MAX(vmag) FROM stars").fetchone()[0]

    # Compact
    cursor.execute("VACUUM")
    conn.close()

    file_size_mb = os.path.getsize(OUTPUT_PATH) / (1024 * 1024)

    print(f"\nResults:")
    print(f"  Stars: {count:,}")
    print(f"  Magnitude range: {min_vmag:.2f} to {max_vmag:.2f}")
    print(f"  File size: {file_size_mb:.1f} MB")

    if count < 250_000:
        print(f"\n  WARNING: Row count {count:,} is below target of 250,000")
    if file_size_mb > 18:
        print(f"\n  WARNING: File size {file_size_mb:.1f} MB exceeds 18 MB limit")

    return count


def main():
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)

    stars = None
    try:
        stars = download_vizier()
    except Exception as e:
        print(f"  VizieR download failed: {e}")

    if not stars or len(stars) < 10000:
        try:
            stars = download_hyg()
        except Exception as e:
            print(f"  HYG download also failed: {e}")
            sys.exit(1)

    count = write_sqlite(stars)
    print(f"\nStar catalog built successfully: {count:,} stars")


if __name__ == "__main__":
    main()

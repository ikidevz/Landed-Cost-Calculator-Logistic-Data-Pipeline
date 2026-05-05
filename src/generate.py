import json
import random
import uuid
from datetime import datetime, timedelta
from pathlib import Path

from faker import Faker

fake = Faker()
random.seed(42)

# ---------------------------------------------------------------------------
# SEED DATA — HS Codes with duty rates (CMTA 2016 / AHTN-based sample)
# ---------------------------------------------------------------------------

HS_CODES = [
    # Electronics
    {"hs_code": "84713000", "description": "Laptop computers",
        "category": "Electronics",    "duty_rate": 0.00},
    {"hs_code": "84715000",
        "description": "Processing units (CPUs)",            "category": "Electronics",    "duty_rate": 0.00},
    {"hs_code": "85171200", "description": "Mobile phones / smartphones",
        "category": "Electronics",    "duty_rate": 0.00},
    {"hs_code": "85285200", "description": "LCD monitors",
        "category": "Electronics",    "duty_rate": 0.00},
    {"hs_code": "84733000", "description": "Computer parts and accessories",
        "category": "Electronics",    "duty_rate": 0.00},
    {"hs_code": "85044000", "description": "Power supplies / converters",
        "category": "Electronics",    "duty_rate": 0.01},
    {"hs_code": "85176200", "description": "Networking equipment / routers",
        "category": "Electronics",    "duty_rate": 0.00},
    {"hs_code": "85258000", "description": "Digital cameras",
        "category": "Electronics",    "duty_rate": 0.01},
    # Semiconductors
    {"hs_code": "85423100",
        "description": "Integrated circuits (processors)",   "category": "Semiconductors", "duty_rate": 0.00},
    {"hs_code": "85423900", "description": "Other electronic components",
        "category": "Semiconductors", "duty_rate": 0.00},
    {"hs_code": "85414000", "description": "Photosensitive semiconductors",
        "category": "Semiconductors", "duty_rate": 0.00},
    # Apparel
    {"hs_code": "62034200", "description": "Men's trousers, cotton",
        "category": "Apparel",        "duty_rate": 0.20},
    {"hs_code": "62052000", "description": "Men's shirts, cotton",
        "category": "Apparel",        "duty_rate": 0.20},
    {"hs_code": "62114200", "description": "Women's garments, manmade fibre",
        "category": "Apparel",        "duty_rate": 0.20},
    {"hs_code": "61091000", "description": "T-shirts, cotton, knitted",
        "category": "Apparel",        "duty_rate": 0.20},
    {"hs_code": "62046200", "description": "Women's trousers, cotton",
        "category": "Apparel",        "duty_rate": 0.20},
    # Footwear
    {"hs_code": "64041100", "description": "Sports footwear, rubber/plastic",
        "category": "Footwear",       "duty_rate": 0.25},
    {"hs_code": "64039100", "description": "Leather footwear, other",
        "category": "Footwear",       "duty_rate": 0.20},
    {"hs_code": "64021200", "description": "Ski boots, outer sole rubber",
        "category": "Footwear",       "duty_rate": 0.25},
    # Automotive
    {"hs_code": "87032319",
        "description": "Passenger cars (1500–3000 cc)",      "category": "Automotive",     "duty_rate": 0.30},
    {"hs_code": "87032210",
        "description": "Passenger cars (≤1000 cc)",          "category": "Automotive",     "duty_rate": 0.05},
    {"hs_code": "87089900", "description": "Auto parts and accessories",
        "category": "Automotive",     "duty_rate": 0.10},
    {"hs_code": "87070000", "description": "Vehicle bodies / cabs",
        "category": "Automotive",     "duty_rate": 0.30},
    # Plastics
    {"hs_code": "39011000",
        "description": "Polyethylene, low density (LDPE)",   "category": "Plastics",       "duty_rate": 0.07},
    {"hs_code": "39021000", "description": "Polypropylene",
        "category": "Plastics",       "duty_rate": 0.07},
    {"hs_code": "39031100", "description": "Polystyrene, expandable",
        "category": "Plastics",       "duty_rate": 0.07},
    # Steel
    {"hs_code": "72142000",
        "description": "Steel bars, deformed (rebar)",       "category": "Steel",          "duty_rate": 0.05},
    {"hs_code": "72163200", "description": "I-beams, steel",
        "category": "Steel",          "duty_rate": 0.05},
    {"hs_code": "72104900", "description": "Flat-rolled steel, zinc-coated",
        "category": "Steel",          "duty_rate": 0.05},
    # Food
    {"hs_code": "10063000", "description": "Semi-milled / wholly milled rice",
        "category": "Food",           "duty_rate": 0.35},
    {"hs_code": "17011400", "description": "Raw cane sugar",
        "category": "Food",           "duty_rate": 0.38},
    {"hs_code": "02013000", "description": "Fresh / chilled beef",
        "category": "Food",           "duty_rate": 0.05},
    {"hs_code": "03061700", "description": "Frozen shrimp and prawns",
        "category": "Food",           "duty_rate": 0.07},
    {"hs_code": "07019000", "description": "Potatoes, fresh or chilled",
        "category": "Food",           "duty_rate": 0.30},
    {"hs_code": "08051000", "description": "Oranges, fresh or dried",
        "category": "Food",           "duty_rate": 0.10},
    # Chemicals
    {"hs_code": "29054500", "description": "Glycerol (glycerin)",
     "category": "Chemicals",      "duty_rate": 0.03},
    {"hs_code": "28042100", "description": "Argon gas",
        "category": "Chemicals",      "duty_rate": 0.00},
    {"hs_code": "29053100", "description": "Ethylene glycol",
        "category": "Chemicals",      "duty_rate": 0.03},
    {"hs_code": "38089400", "description": "Disinfectants",
        "category": "Chemicals",      "duty_rate": 0.01},
    # Pharma
    {"hs_code": "30041000", "description": "Medicaments containing penicillin",
        "category": "Pharma",         "duty_rate": 0.00},
    {"hs_code": "30049000",
        "description": "Other medicaments (mixed/unmixed)",  "category": "Pharma",         "duty_rate": 0.00},
    {"hs_code": "30059000", "description": "Medical dressings / bandages",
        "category": "Pharma",         "duty_rate": 0.00},
    # Furniture
    {"hs_code": "94011000", "description": "Aircraft seats",
        "category": "Furniture",      "duty_rate": 0.10},
    {"hs_code": "94036000", "description": "Wooden furniture, other",
        "category": "Furniture",      "duty_rate": 0.25},
    {"hs_code": "94017900", "description": "Upholstered seats, other",
        "category": "Furniture",      "duty_rate": 0.25},
]

PORT_FEES = {
    "Manila":          {"operator": "ICTSI — Manila International Container Terminal", "arrastre_php": 560.00, "wharfage_php": 156.00, "exchange_ref": 55.0},
    "Cebu":            {"operator": "APMC — Asian Pacific Marine Contractors (Cebu South/North Ports)", "arrastre_php": 490.00, "wharfage_php": 130.00, "exchange_ref": 55.0},
    "Davao":           {"operator": "SPIA — Sasa Port International Authority", "arrastre_php": 470.00, "wharfage_php": 120.00, "exchange_ref": 55.0},
    "Cagayan de Oro":  {"operator": "CGDP — Cagayan de Oro Port (PPA-managed)", "arrastre_php": 450.00, "wharfage_php": 115.00, "exchange_ref": 55.0},
    "Subic Bay":       {"operator": "SBMA — Subic Bay Metropolitan Authority / ICTSI subsidiary", "arrastre_php": 520.00, "wharfage_php": 145.00, "exchange_ref": 55.0},
    "Batangas":        {"operator": "BIPI — Batangas International Port Inc. (PPA-managed)", "arrastre_php": 480.00, "wharfage_php": 125.00, "exchange_ref": 55.0},
}

ORIGIN_COUNTRIES = {
    "China": 0.35, "South Korea": 0.12, "Japan": 0.10, "United States": 0.09,
    "Taiwan": 0.07, "Vietnam": 0.06, "Thailand": 0.05, "Germany": 0.04,
    "Indonesia": 0.04, "Malaysia": 0.04, "India": 0.03, "Singapore": 0.01,
}

PORTS_OF_DISCHARGE = list(PORT_FEES.keys())
INCOTERMS = ["FOB", "CIF", "CFR", "EXW", "DDP", "DAP"]


def weighted_choice(weights: dict) -> str:
    keys = list(weights.keys())
    probs = list(weights.values())
    return random.choices(keys, weights=probs, k=1)[0]


def random_date() -> datetime:
    start = datetime(2023, 1, 1)
    end = datetime(2024, 12, 31)
    return start + timedelta(seconds=random.randint(0, int((end - start).total_seconds())))


def compute_landed_cost(
    cif_value_usd: float,
    gross_weight_mt: float,
    duty_rate: float,
    port: str,
    exchange_rate_php: float,
) -> dict:
    port_cfg = PORT_FEES[port]
    insurance_usd = round(cif_value_usd * 0.005, 4)
    dutiable_value_usd = round(cif_value_usd + insurance_usd, 4)
    customs_duty_usd = round(dutiable_value_usd * duty_rate, 4)
    vat_base = dutiable_value_usd + customs_duty_usd
    vat_usd = round(vat_base * 0.12, 4)
    arrastre_usd = round(
        (port_cfg["arrastre_php"] * gross_weight_mt) / port_cfg["exchange_ref"], 4)
    wharfage_usd = round(
        (port_cfg["wharfage_php"] * gross_weight_mt) / port_cfg["exchange_ref"], 4)
    other_fees_usd = round(random.uniform(15, 80), 4)
    landed_cost_usd = round(
        cif_value_usd + insurance_usd + customs_duty_usd + vat_usd
        + arrastre_usd + wharfage_usd + other_fees_usd, 4,
    )
    landed_cost_php = round(landed_cost_usd * exchange_rate_php, 2)

    return {
        "insurance_usd":      insurance_usd,
        "dutiable_value_usd": dutiable_value_usd,
        "customs_duty_usd":   customs_duty_usd,
        "vat_usd":            vat_usd,
        "arrastre_usd":       arrastre_usd,
        "wharfage_usd":       wharfage_usd,
        "other_fees_usd":     other_fees_usd,
        "landed_cost_usd":    landed_cost_usd,
        "landed_cost_php":    landed_cost_php,
        "port_operator":      port_cfg["operator"],
    }


def generate_shipment() -> dict:
    """Generate one synthetic shipment record."""
    hs_entry = random.choice(HS_CODES)
    origin = weighted_choice(ORIGIN_COUNTRIES)
    port = random.choice(PORTS_OF_DISCHARGE)
    shipment_date = random_date()
    exchange_rate = round(random.uniform(55.0, 58.5), 4)

    quantity = random.randint(1, 500)
    unit_price_usd = round(random.uniform(5.0, 4500.0), 4)
    item_cost_usd = round(quantity * unit_price_usd, 4)
    gross_weight_mt = round(
        max(0.01, item_cost_usd / 1200 * random.uniform(0.7, 1.3)), 4)
    freight_cost_usd = round(
        max(50.0, item_cost_usd * random.uniform(0.03, 0.08)), 4)
    cif_value_usd = round(item_cost_usd + freight_cost_usd, 4)

    costs = compute_landed_cost(
        cif_value_usd=cif_value_usd,
        gross_weight_mt=gross_weight_mt,
        duty_rate=hs_entry["duty_rate"],
        port=port,
        exchange_rate_php=exchange_rate,
    )

    cost_ratio = round(costs["landed_cost_usd"] /
                       item_cost_usd, 4) if item_cost_usd > 0 else 0
    is_anomaly = cost_ratio >= 2.0

    return {
        "shipment_id":           str(uuid.uuid4()),
        "shipment_date":         shipment_date.strftime("%Y-%m-%d %H:%M:%S"),
        "ingestion_timestamp":   datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "origin_country":        origin,
        "port_of_discharge":     port,
        "port_operator":         costs["port_operator"],
        "incoterm":              random.choice(INCOTERMS),
        "importer_name":         fake.company(),
        "importer_tin":          fake.numerify("###-###-###-###"),
        "hs_code":               hs_entry["hs_code"],
        "commodity_description": hs_entry["description"],
        "hs_category":           hs_entry["category"],
        "quantity":              quantity,
        "unit_of_measure":       random.choice(["PCS", "KGS", "MT", "SET", "CTN"]),
        "unit_price_usd":        unit_price_usd,
        "item_cost_usd":         item_cost_usd,
        "gross_weight_mt":       gross_weight_mt,
        "freight_cost_usd":      freight_cost_usd,
        "cif_value_usd":         cif_value_usd,
        "insurance_usd":         costs["insurance_usd"],
        "dutiable_value_usd":    costs["dutiable_value_usd"],
        "duty_rate":             hs_entry["duty_rate"],
        "customs_duty_usd":      costs["customs_duty_usd"],
        "vat_usd":               costs["vat_usd"],
        "arrastre_usd":          costs["arrastre_usd"],
        "wharfage_usd":          costs["wharfage_usd"],
        "other_fees_usd":        costs["other_fees_usd"],
        "landed_cost_usd":       costs["landed_cost_usd"],
        "exchange_rate_php":     exchange_rate,
        "landed_cost_php":       costs["landed_cost_php"],
        "cost_ratio":            cost_ratio,
        "is_anomaly":            is_anomaly,
        "data_source":           "synthetic_generator_v1",
    }


# ---------------------------------------------------------------------------
# PUBLIC INTERFACE
# ---------------------------------------------------------------------------

def generate_data(records: int = 5000, output_path: str | None = None) -> Path:
    output_dir = Path("data/generated")
    output_dir.mkdir(parents=True, exist_ok=True)

    if output_path:
        file_path = Path(output_path)
    else:
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        file_path = output_dir / f"shipments_{ts}.json"

    print(f"Generating {records:,} shipment records...")
    print(f"Output → {file_path}")
    print("-" * 50)

    all_records = []
    anomaly_count = 0

    for i in range(records):
        record = generate_shipment()
        all_records.append(record)
        if record["is_anomaly"]:
            anomaly_count += 1
        if (i + 1) % 500 == 0:
            print(f"  Generated {i + 1:,} / {records:,} records...")

    with open(file_path, "w", encoding="utf-8") as f:
        f.write("\n".join(json.dumps(r) for r in all_records))

    total_landed_usd = sum(r["landed_cost_usd"] for r in all_records)
    avg_landed_usd = total_landed_usd / len(all_records)
    avg_duty_rate = sum(r["duty_rate"] for r in all_records) / len(all_records)

    print("-" * 50)
    print(f"Done! {records:,} records written.")
    print(f"  Avg landed cost  : ${avg_landed_usd:,.2f} USD")
    print(f"  Avg duty rate    : {avg_duty_rate:.1%}")
    print(
        f"  Anomaly records  : {anomaly_count:,} ({anomaly_count / records:.1%})")
    print(f"  File size        : {file_path.stat().st_size / 1024:.1f} KB")
    print(f"  Ready for        : producer.produce_to_kafka()")

    return file_path


if __name__ == "__main__":
    generate_data()

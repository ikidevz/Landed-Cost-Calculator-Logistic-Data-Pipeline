import json
import os
import time
from pathlib import Path

from dotenv import load_dotenv
from kafka import KafkaProducer
from kafka.errors import KafkaError

load_dotenv()

BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092")
TOPIC = os.getenv("KAFKA_TOPIC", "shipments")


# ---------------------------------------------------------------------------
# INTERNAL HELPERS
# ---------------------------------------------------------------------------

def _get_latest_file(generated_dir: Path) -> Path:
    """Return the most recently created shipment JSONL file."""
    files = sorted(generated_dir.glob("shipments_*.json"), reverse=True)
    if not files:
        raise FileNotFoundError(
            f"No shipment JSON files found in {generated_dir}. "
            "Run generate.generate_data() first."
        )
    return files[0]


def _build_producer() -> KafkaProducer:
    return KafkaProducer(
        bootstrap_servers=BOOTSTRAP_SERVERS,
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        key_serializer=lambda k: k.encode("utf-8") if k else None,
        acks="all",
        retries=3,
        linger_ms=5,
    )


# ---------------------------------------------------------------------------
# PUBLIC INTERFACE
# ---------------------------------------------------------------------------

def produce_to_kafka(
    file_path: str | Path | None = None,
    delay: float = 0.05,
) -> None:
    if file_path is not None:
        resolved = Path(file_path)
        if not resolved.exists():
            raise FileNotFoundError(f"File not found: {resolved}")
    else:
        resolved = _get_latest_file(Path("data/generated"))

    producer = _build_producer()

    print(f"Connected to Kafka at {BOOTSTRAP_SERVERS}")
    print(f"Publishing to topic  : {TOPIC}")
    print(f"Source file          : {resolved}")
    print(f"Inter-message delay  : {delay}s")
    print("-" * 55)

    sent = 0
    errors = 0

    with open(resolved, "r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue

            try:
                record = json.loads(line)
            except json.JSONDecodeError as e:
                errors += 1
                print(
                    f"  [SKIP] Malformed JSON line: {e} — line preview: {line[:80]!r}")
                continue

            key = record.get("shipment_id")

            try:
                future = producer.send(TOPIC, key=key, value=record)
                future.get(timeout=10)
                sent += 1

                if sent % 500 == 0:
                    print(f"  Sent {sent:,} records...")

                if delay > 0:
                    time.sleep(delay)

            except KafkaError as exc:
                errors += 1
                print(f"  [ERROR] Failed to send {key}: {exc}")

    producer.flush()
    producer.close()

    print("-" * 55)
    print(f"Done. Sent: {sent:,}  |  Errors: {errors}")
    print(f"Next step: consumer.start_consumer()")


if __name__ == "__main__":
    produce_to_kafka()

import json
import os
import tempfile
import urllib.request
from datetime import datetime, timedelta, timezone

ACCOUNT = os.environ["CLOUDFLARE_ACCOUNT_ID"]
TEXTFILE = os.environ["TEXTFILE_PATH"]

# R2 bills by operation class, and the GraphQL API reports the action but not
# its class. https://developers.cloudflare.com/r2/pricing/
CLASSES = {
    "ListBuckets": "A",
    "PutBucket": "A",
    "ListObjects": "A",
    "PutObject": "A",
    "CopyObject": "A",
    "CompleteMultipartUpload": "A",
    "CreateMultipartUpload": "A",
    "LifecycleStorageTierTransition": "A",
    "ListMultipartUploads": "A",
    "UploadPart": "A",
    "UploadPartCopy": "A",
    "ListParts": "A",
    "PutBucketEncryption": "A",
    "PutBucketCors": "A",
    "PutBucketLifecycleConfiguration": "A",
    "HeadBucket": "B",
    "HeadObject": "B",
    "GetObject": "B",
    "UsageSummary": "B",
    "GetBucketEncryption": "B",
    "GetBucketLocation": "B",
    "GetBucketCors": "B",
    "GetBucketLifecycleConfiguration": "B",
    "DeleteObject": "free",
    "DeleteBucket": "free",
    "AbortMultipartUpload": "free",
}

QUERY = """query($account: string!, $storageSince: Time, $monthStart: Time) {
  viewer {
    accounts(filter: { accountTag: $account }) {
      storage: r2StorageAdaptiveGroups(limit: 10000, filter: { datetime_geq: $storageSince }) {
        dimensions { bucketName datetime }
        max { objectCount uploadCount payloadSize metadataSize }
      }
      operations: r2OperationsAdaptiveGroups(limit: 10000, filter: { datetime_geq: $monthStart }) {
        dimensions { bucketName actionType actionStatus }
        sum { requests }
      }
    }
  }
}"""

STORAGE_METRICS = [
    ("payload_bytes", "payloadSize", "Size of the objects held in an R2 bucket."),
    (
        "metadata_bytes",
        "metadataSize",
        "Size of the metadata held alongside the objects in an R2 bucket.",
    ),
    ("objects", "objectCount", "Number of objects in an R2 bucket."),
    ("uploads", "uploadCount", "Number of unfinished multipart uploads in an R2 bucket."),
]


def fetch():
    with open(os.environ["CREDENTIALS_DIRECTORY"] + "/api-token") as f:
        token = f.read().strip()

    now = datetime.now(timezone.utc)
    body = json.dumps(
        {
            "query": QUERY,
            "variables": {
                "account": ACCOUNT,
                # Storage is sampled on its own schedule rather than continuously, so a
                # window short enough to mean "now" can come back empty; a day of samples
                # always has one and the newest is picked below.
                "storageSince": (now - timedelta(hours=24)).strftime("%Y-%m-%dT%H:%M:%SZ"),
                # Operations accumulate from the first of the month so the raw value
                # answers "how much of the free tier is gone", and Prometheus reads the
                # monthly reset as a counter reset, leaving rate() usable too.
                "monthStart": now.strftime("%Y-%m-01T00:00:00Z"),
            },
        }
    ).encode()

    request = urllib.request.Request(
        "https://api.cloudflare.com/client/v4/graphql",
        data=body,
        headers={"Authorization": "Bearer " + token, "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        payload = json.load(response)

    # GraphQL answers 200 with an errors array, so the HTTP status says nothing
    # when the token lacks Account Analytics: Read.
    if payload.get("errors"):
        messages = "; ".join(e["message"] for e in payload["errors"])
        raise SystemExit("Cloudflare GraphQL API returned errors: " + messages)

    # Bailing out keeps the previous file, whose age is what the staleness alert
    # reads; writing an empty one would instead publish zeroes.
    accounts = payload["data"]["viewer"]["accounts"]
    if not accounts:
        raise SystemExit("Cloudflare GraphQL API returned no account matching " + ACCOUNT)
    return accounts[0]


def render(account):
    newest = {}
    for group in account.get("storage") or []:
        bucket = group["dimensions"]["bucketName"]
        if group["dimensions"]["datetime"] > newest.get(bucket, {}).get("datetime", ""):
            newest[bucket] = dict(group["max"], datetime=group["dimensions"]["datetime"])

    lines = []
    for suffix, field, help_text in STORAGE_METRICS:
        name = "cloudflare_r2_bucket_" + suffix
        lines += [f"# HELP {name} {help_text}", f"# TYPE {name} gauge"]
        lines += [f'{name}{{bucket="{b}"}} {v[field]}' for b, v in sorted(newest.items())]

    name = "cloudflare_r2_operations_total"
    lines += [
        f"# HELP {name} Operations against an R2 bucket since the start of the billing month.",
        f"# TYPE {name} counter",
    ]
    for operation in account.get("operations") or []:
        d = operation["dimensions"]
        labels = (
            f'bucket="{d["bucketName"]}",action="{d["actionType"]}",'
            f'class="{CLASSES.get(d["actionType"], "unknown")}",status="{d["actionStatus"]}"'
        )
        lines.append(f"{name}{{{labels}}} {operation['sum']['requests']}")

    return "\n".join(lines) + "\n"


def publish(text):
    # Not named *.prom so the collector skips it until the rename lands.
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(TEXTFILE), suffix=".tmp")
    with os.fdopen(fd, "w") as f:
        f.write(text)
    os.replace(tmp, TEXTFILE)


publish(render(fetch()))

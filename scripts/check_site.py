from html.parser import HTMLParser
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
html = (root / "index.html").read_text(encoding="utf-8")
schema = (root / "supabase" / "schema.sql").read_text(encoding="utf-8")

class Audit(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = []
        self.labels = set()
        self.controls = []
        self.scripts = []
        self.in_inline_script = False
        self.script_parts = []
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "id" in attrs:
            self.ids.append(attrs["id"])
        if tag == "label" and attrs.get("for"):
            self.labels.add(attrs["for"])
        if tag in {"input", "textarea", "select"}:
            self.controls.append((tag, attrs))
        if tag == "script":
            self.in_inline_script = "src" not in attrs
            if self.in_inline_script:
                self.script_parts.append("")
    def handle_data(self, data):
        if self.in_inline_script and self.script_parts:
            self.script_parts[-1] += data
    def handle_endtag(self, tag):
        if tag == "script":
            self.in_inline_script = False

audit = Audit()
audit.feed(html)
duplicates = sorted({item for item in audit.ids if audit.ids.count(item) > 1})
assert not duplicates, f"Duplicate HTML IDs: {duplicates}"
missing = []
for tag, attrs in audit.controls:
    if "hidden" in attrs or attrs.get("type") == "hidden":
        continue
    if not (attrs.get("aria-label") or attrs.get("aria-labelledby") or attrs.get("id") in audit.labels):
        missing.append(attrs.get("id", f"<{tag}>"))
assert not missing, f"Controls missing accessible names: {missing}"
assert not re.search(r"LOCAL_PASS|VAULT_PASS|SURPRISE_CODES|passInput|secretPass", html), "Client-side passcode found"
assert re.search(r"supabase-js@\d+\.\d+\.\d+", html), "Supabase JS CDN must be pinned to an exact version"
assert "function openWhatsApp" in html and "location.href=url" not in html, "WhatsApp fallback must not navigate the current tab"
assert "pendingWrites" in html and "retryPendingWrites" in html, "In-memory failed-write retry queue missing"
assert ".range(offset,offset+pageSize-1)" in html, "Cloud history pagination missing"
assert "alter table public.shared_entries enable row level security" in schema, "Shared entries RLS is not enabled"
assert "lower(cm.display_name) = lower(coalesce(shared_entries.payload->>'by', ''))" in schema, "Sender attribution is not checked by RLS"
assert 'role="dialog" aria-modal="true"' in html, "Login dialog semantics missing"
Path("/tmp/secret-territory-inline.js").write_text("\n".join(audit.script_parts), encoding="utf-8")
print(f"PASS: {len(audit.ids)} unique IDs, {len(audit.controls)} named controls, pinned dependency, privacy, pagination and RLS guards.")

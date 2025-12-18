import re

DISALLOWED = re.compile(
    r"\b(drop|delete|update|insert|alter|truncate|grant|revoke|copy|create)\b",
    re.IGNORECASE,
)

CODE_FENCE = re.compile(r"```(?:sql)?\s*|\s*```", re.IGNORECASE)

def _strip_code_fences(text: str) -> str:
    return CODE_FENCE.sub("", text).strip()

def ensure_read_only_sql(text: str) -> str:
    # 1) remove markdown fences
    s = _strip_code_fences(text).strip()

    if not s:
        raise ValueError("Empty SQL")

    # 2) take ONLY the first SQL statement (up to first semicolon)
    first = s.split(";", 1)[0].strip()

    if not first:
        raise ValueError("Empty SQL statement")

    # 3) block destructive keywords anywhere
    if DISALLOWED.search(first):
        raise ValueError("Unsafe SQL detected (write/destructive keyword).")

    # 4) allow only SELECT/WITH/EXPLAIN
    if not re.match(r"^(select|with|explain)\b", first, re.IGNORECASE):
        raise ValueError("Only SELECT/WITH/EXPLAIN statements are allowed.")

    return first + ";"

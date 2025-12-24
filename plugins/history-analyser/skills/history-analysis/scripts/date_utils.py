#!/usr/bin/env python3
"""
Parse natural language dates to Unix timestamps.

Usage:
    date_utils.py <date-expression> [end-date]

Examples:
    date_utils.py "last week"
    date_utils.py "yesterday"
    date_utils.py "2024-12-01" "2024-12-23"

Output: JSON with start_ts and end_ts in milliseconds
"""

import json
import re
import sys
from datetime import datetime, timedelta

MONTHS = {
    "january": 1, "jan": 1,
    "february": 2, "feb": 2,
    "march": 3, "mar": 3,
    "april": 4, "apr": 4,
    "may": 5,
    "june": 6, "jun": 6,
    "july": 7, "jul": 7,
    "august": 8, "aug": 8,
    "september": 9, "sep": 9,
    "october": 10, "oct": 10,
    "november": 11, "nov": 11,
    "december": 12, "dec": 12,
}


def parse_month_year(month_str: str, year_str: str) -> datetime:
    month = MONTHS.get(month_str.lower())
    if month:
        return datetime(int(year_str), month, 1)
    return None


def parse_natural_date(text: str, end_text: str = None) -> dict:
    text = text.lower().strip()
    now = datetime.now()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)

    patterns = {
        "today": (today_start, now),
        "yesterday": (today_start - timedelta(days=1), today_start),
        "last week": (now - timedelta(days=7), now),
        "last 7 days": (now - timedelta(days=7), now),
        "this week": (today_start - timedelta(days=today_start.weekday()), now),
        "last month": (now - timedelta(days=30), now),
        "last 30 days": (now - timedelta(days=30), now),
        "this month": (today_start.replace(day=1), now),
    }

    if text in patterns:
        start, end = patterns[text]
        return format_result(start, end)

    # "last N days/weeks/months" or "N days/weeks/months ago"
    match = re.match(r"last (\d+) (day|week|month)s?", text)
    if not match:
        match = re.match(r"(\d+) (day|week|month)s? ago", text)
    if match:
        n = int(match.group(1))
        unit = match.group(2)
        if unit == "day":
            delta = timedelta(days=n)
        elif unit == "week":
            delta = timedelta(weeks=n)
        else:  # month
            delta = timedelta(days=n * 30)
        return format_result(now - delta, now)

    # "YYYY-MM-DD to today" or "YYYY-MM-DD to now"
    match = re.match(r"(\d{4}-\d{2}-\d{2})\s+to\s+(today|now)", text)
    if match:
        start_dt = datetime.fromisoformat(match.group(1))
        return format_result(start_dt, now)

    # "YYYY-MM-DD to YYYY-MM-DD"
    match = re.match(r"(\d{4}-\d{2}-\d{2})\s+to\s+(\d{4}-\d{2}-\d{2})", text)
    if match:
        start_dt = datetime.fromisoformat(match.group(1))
        end_dt = datetime.fromisoformat(match.group(2))
        return format_result(start_dt, end_dt)

    # "Month YYYY to Month YYYY" or "Month YYYY to today"
    month_pattern = r"(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|oct|nov|dec)\s+(\d{4})"
    match = re.match(f"{month_pattern}\\s+to\\s+(today|now)", text)
    if match:
        start_dt = parse_month_year(match.group(1), match.group(2))
        if start_dt:
            return format_result(start_dt, now)

    match = re.match(f"{month_pattern}\\s+to\\s+{month_pattern}", text)
    if match:
        start_dt = parse_month_year(match.group(1), match.group(2))
        end_dt = parse_month_year(match.group(3), match.group(4))
        if start_dt and end_dt:
            # End of the end month
            if end_dt.month == 12:
                end_dt = end_dt.replace(year=end_dt.year + 1, month=1)
            else:
                end_dt = end_dt.replace(month=end_dt.month + 1)
            return format_result(start_dt, end_dt)

    # Try ISO date parsing
    try:
        start_dt = datetime.fromisoformat(text)
        if end_text:
            end_dt = datetime.fromisoformat(end_text.strip())
        else:
            end_dt = start_dt + timedelta(days=1)
        return format_result(start_dt, end_dt)
    except ValueError:
        pass

    # Try parsing "December 2024" style
    for fmt in ["%B %Y", "%b %Y", "%Y-%m"]:
        try:
            start_dt = datetime.strptime(text, fmt)
            if start_dt.month == 12:
                end_dt = start_dt.replace(year=start_dt.year + 1, month=1, day=1)
            else:
                end_dt = start_dt.replace(month=start_dt.month + 1, day=1)
            return format_result(start_dt, end_dt)
        except ValueError:
            continue

    return {"error": f"Could not parse date: {text}"}


def format_result(start: datetime, end: datetime) -> dict:
    return {
        "start_ts": int(start.timestamp() * 1000),
        "end_ts": int(end.timestamp() * 1000),
        "start_date": start.isoformat(),
        "end_date": end.isoformat(),
    }


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: date_utils.py <date-expression> [end-date]"}))
        sys.exit(1)

    end_text = sys.argv[2] if len(sys.argv) > 2 else None
    result = parse_natural_date(sys.argv[1], end_text)
    print(json.dumps(result, indent=2))
    sys.exit(0 if "error" not in result else 1)


if __name__ == "__main__":
    main()

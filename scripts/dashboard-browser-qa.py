#!/usr/bin/env python3
"""Headless Wizard HQ browser QA.

This script is intentionally optional. Static shell/dashboard smokes remain the
default CI-safe checks; this script provides repeatable screenshot evidence
when Python Playwright and its Chromium browser are installed locally.
"""

from __future__ import annotations

import argparse
import contextlib
import datetime as dt
import json
import os
import threading
import time
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DASHBOARD_DIR = ROOT / "dashboard"
DEFAULT_ASSET_DIR = ROOT / "docs" / "release" / "evidence" / "assets"
DEFAULT_PORT = 8899
DEFAULT_PROMPT = "Explain what Merlin can do locally right now."


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, format: str, *args: object) -> None:  # noqa: A002
        return


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run headless Wizard HQ desktop/mobile checks and screenshots.",
    )
    parser.add_argument(
        "--url",
        default=os.environ.get("DASHBOARD_QA_URL", f"http://127.0.0.1:{DEFAULT_PORT}/index.html"),
        help="Dashboard URL to test. Defaults to a local static server.",
    )
    parser.add_argument(
        "--serve-static",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Serve dashboard/ locally before opening the browser.",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=DEFAULT_PORT,
        help="Port for the optional local static dashboard server.",
    )
    parser.add_argument(
        "--output-dir",
        default=None,
        help="Screenshot/evidence directory. Defaults to docs/release/evidence/assets/<date>-wizard-hq-browser-qa.",
    )
    parser.add_argument(
        "--prompt",
        default=DEFAULT_PROMPT,
        help="Benign prompt text used to test the composer UI without submitting.",
    )
    parser.add_argument(
        "--check-deps",
        action="store_true",
        help="Only verify Python Playwright can be imported.",
    )
    return parser.parse_args()


def import_playwright() -> Any:
    try:
        from playwright.sync_api import TimeoutError as PlaywrightTimeoutError
        from playwright.sync_api import sync_playwright
    except ModuleNotFoundError as exc:
        raise SystemExit(
            "Python Playwright is not installed.\n"
            "Install it with:\n"
            "  .venv-test/bin/python -m pip install 'playwright>=1.44,<2'\n"
            "  .venv-test/bin/python -m playwright install chromium\n"
            "Then rerun:\n"
            "  .venv-test/bin/python scripts/dashboard-browser-qa.py"
        ) from exc
    return sync_playwright, PlaywrightTimeoutError


def start_static_server(port: int) -> ThreadingHTTPServer:
    handler = partial(QuietHandler, directory=str(DASHBOARD_DIR))
    server = ThreadingHTTPServer(("127.0.0.1", port), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server


def evidence_dir(value: str | None) -> Path:
    if value:
        output = Path(value).expanduser()
    else:
        stamp = dt.datetime.now(dt.UTC).strftime("%Y-%m-%d-wizard-hq-browser-qa")
        output = DEFAULT_ASSET_DIR / stamp
    output.mkdir(parents=True, exist_ok=True)
    return output


def require_visible(page: Any, selector: str, label: str) -> None:
    item = page.locator(selector).first
    if not item.is_visible(timeout=5000):
        raise AssertionError(f"Missing visible UI element: {label} ({selector})")


def run_viewport(
    browser: Any,
    *,
    url: str,
    output: Path,
    name: str,
    width: int,
    height: int,
    prompt: str,
) -> dict[str, Any]:
    context = browser.new_context(viewport={"width": width, "height": height}, device_scale_factor=1)
    page = context.new_page()
    page.goto(url, wait_until="networkidle", timeout=15000)

    require_visible(page, "text=Merlin AI", "Merlin AI brand")
    require_visible(page, "#merlin-chat-input", "Merlin chat input")
    require_visible(page, "#merlin-chat-submit", "Ask Merlin button")
    require_visible(page, ".composer-mode-selector", "mode selector")

    page.screenshot(path=str(output / f"{name}-empty.png"), full_page=True)

    page.locator("#merlin-chat-input").fill(prompt)
    page.wait_for_timeout(150)
    send_opacity = page.locator("#merlin-chat-submit").evaluate("el => getComputedStyle(el).opacity")
    if float(send_opacity) < 0.9:
        raise AssertionError(f"Ask Merlin button should be active after typing; opacity={send_opacity}")

    page.locator('[data-chat-mode="fast"]').last.click()
    require_visible(page, "text=Fast mode. Merlin uses the quickest local model.", "Fast mode status")
    page.locator('[data-chat-mode="smart"]').last.click()
    require_visible(page, "text=Smart mode. Merlin routes to the best available model.", "Smart mode status")

    search_chip = page.locator(".composer-tools .tool-chip.search").first
    search_chip.click()
    if search_chip.get_attribute("aria-pressed") != "true":
        raise AssertionError("Search chip did not toggle on")

    page.screenshot(path=str(output / f"{name}-typed.png"), full_page=True)

    page.locator('[data-tab-target="rooms"]').click()
    require_visible(page, "text=Room Review Table", "Rooms review table heading")
    require_visible(page, "#rooms-review-table", "Rooms review table")
    require_visible(page, "text=whole-Room archive/delete locked", "whole-Room archive/delete lock")
    page.wait_for_timeout(240)
    page.screenshot(path=str(output / f"{name}-rooms.png"), full_page=True)

    page.locator("#rooms-new-room-name").fill("Merlin Build Notes")
    page.get_by_role("button", name="Create Room").click()
    require_visible(page, "text=Similar Room found", "similar Room guard")
    require_visible(page, "text=Use Merlin Build", "similar Room use-existing action")
    page.wait_for_timeout(240)
    page.screenshot(path=str(output / f"{name}-rooms-guard.png"), full_page=True)

    context.close()
    return {
        "viewport": name,
        "width": width,
        "height": height,
        "screenshots": [f"{name}-empty.png", f"{name}-typed.png", f"{name}-rooms.png", f"{name}-rooms-guard.png"],
    }


def main() -> int:
    args = parse_args()
    sync_playwright, playwright_timeout = import_playwright()
    if args.check_deps:
        print("PASS: Python Playwright import is available")
        return 0

    server: ThreadingHTTPServer | None = None
    if args.serve_static:
        server = start_static_server(args.port)
        time.sleep(0.2)

    output = evidence_dir(args.output_dir)
    summary: dict[str, Any] = {
        "generated_at": dt.datetime.now(dt.UTC).isoformat(),
        "url": args.url,
        "output_dir": str(output),
        "checks": [],
        "cloud_calls_expected": False,
        "browser_shell_execution": False,
    }

    try:
        with sync_playwright() as playwright:
            browser = playwright.chromium.launch(headless=True)
            for viewport in (
                {"name": "desktop-1280", "width": 1280, "height": 900},
                {"name": "mobile-375", "width": 375, "height": 812},
            ):
                summary["checks"].append(
                    run_viewport(browser, url=args.url, output=output, prompt=args.prompt, **viewport)
                )
            browser.close()
    except playwright_timeout as exc:
        raise SystemExit(f"Browser QA timed out: {exc}") from exc
    finally:
        if server is not None:
            with contextlib.suppress(Exception):
                server.shutdown()

    summary_path = output / "summary.json"
    summary_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: Wizard HQ browser QA screenshots written to {output}")
    print(f"PASS: Summary written to {summary_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

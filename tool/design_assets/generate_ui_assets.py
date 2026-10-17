"""Generate the Zoom Monitor UI symbol family from the existing brand geometry."""

from pathlib import Path


OUT = Path(__file__).parent / "ui"

INK = "#182640"
BLUE = "#2B4C86"
PALE = "#94B4FA"
WASH = "#E8EEFA"
LINE = "#DCE3EC"


GLYPHS = {
    "nav_dashboard": """
      <rect x="3.2" y="3.2" width="7.1" height="7.1" rx="1.6"/>
      <rect x="13.7" y="3.2" width="7.1" height="7.1" rx="1.6"/>
      <rect x="3.2" y="13.7" width="7.1" height="7.1" rx="1.6"/>
      <circle cx="17.25" cy="17.25" r="3.55"/>
      <circle cx="17.25" cy="17.25" r="0.8" fill="currentColor" stroke="none"/>
    """,
    "nav_search": """
      <circle cx="10.25" cy="10.25" r="6.45"/>
      <circle cx="10.25" cy="10.25" r="1.35"/>
      <path d="M15.1 15.1 20.5 20.5"/>
    """,
    "nav_calendar": """
      <rect x="3.5" y="5.2" width="17" height="15.4" rx="2.4"/>
      <path d="M3.5 10.1h17M8 3.4v3.6M16 3.4v3.6"/>
      <circle cx="12" cy="15.45" r="2.6"/>
      <circle cx="12" cy="15.45" r="0.65" fill="currentColor" stroke="none"/>
    """,
    "nav_recordings": """
      <rect x="4.2" y="3.2" width="15.6" height="17.6" rx="2.5"/>
      <path d="M7.8 6.8h4.1"/>
      <circle cx="12" cy="13.4" r="4.1"/>
      <circle cx="12" cy="13.4" r="1.35" fill="currentColor" stroke="none"/>
    """,
    "nav_accounts": """
      <rect x="3.2" y="4.1" width="17.6" height="15.8" rx="2.5"/>
      <circle cx="9.1" cy="10.1" r="2.15"/>
      <path d="M5.8 16.3c.65-1.9 1.75-2.75 3.3-2.75s2.65.85 3.3 2.75M15.4 9h2.7M15.4 13h2.7"/>
    """,
    "status_available": """
      <circle cx="12" cy="12" r="8.25"/>
      <path d="m8.2 12.2 2.6 2.6 5.4-5.4"/>
    """,
    "status_busy": """
      <circle cx="12" cy="12" r="8.25"/>
      <path d="M12 7.5v4.8l3.25 1.88"/>
    """,
    "status_secure": """
      <path d="M12 2.9 19.4 6v5.8c0 4.25-2.75 7.4-7.4 9.3-4.65-1.9-7.4-5.05-7.4-9.3V6L12 2.9Z"/>
      <circle cx="12" cy="11.8" r="2.65"/>
      <circle cx="12" cy="11.8" r="0.6" fill="currentColor" stroke="none"/>
    """,
    "action_play": """
      <rect x="3.2" y="4.5" width="17.6" height="15" rx="2.5"/>
      <path d="m10 8.77 5.6 3.23-5.6 3.23Z"/>
    """,
    "action_link": """
      <path d="M9.25 15.2 7.8 16.65a3.6 3.6 0 0 1-5.1-5.1L6 8.25a3.6 3.6 0 0 1 5.1 0M14.75 8.8l1.45-1.45a3.6 3.6 0 0 1 5.1 5.1L18 15.75a3.6 3.6 0 0 1-5.1 0M8.6 12h6.8"/>
    """,
}


SCENES = {
    "state_search": f"""
      <rect x="31" y="34" width="218" height="111" rx="16" fill="white" stroke="{LINE}" stroke-width="2"/>
      <path d="M31 61h218" stroke="{LINE}" stroke-width="2"/>
      <circle cx="49" cy="48" r="3" fill="{PALE}"/>
      <circle cx="60" cy="48" r="3" fill="{WASH}"/>
      <rect x="50" y="77" width="77" height="15" rx="7.5" fill="{WASH}"/>
      <rect x="50" y="102" width="102" height="15" rx="7.5" fill="{WASH}"/>
      <path d="M178 103h22" stroke="{PALE}" stroke-width="5" stroke-linecap="round"/>
      <circle cx="184" cy="95" r="35" fill="white" stroke="{BLUE}" stroke-width="5"/>
      <circle cx="184" cy="95" r="22" fill="none" stroke="{INK}" stroke-width="4"/>
      <circle cx="184" cy="95" r="5" fill="{BLUE}"/>
      <path d="m207 118 24 24" stroke="{BLUE}" stroke-width="6" stroke-linecap="round"/>
    """,
    "state_calendar": f"""
      <rect x="47" y="25" width="175" height="132" rx="16" fill="white" stroke="{LINE}" stroke-width="2"/>
      <path d="M47 63h175" stroke="{BLUE}" stroke-width="4"/>
      <path d="M84 18v20M184 18v20" stroke="{INK}" stroke-width="7" stroke-linecap="round"/>
      <rect x="70" y="79" width="27" height="22" rx="5" fill="{WASH}"/>
      <rect x="109" y="79" width="27" height="22" rx="5" fill="{WASH}"/>
      <rect x="148" y="79" width="27" height="22" rx="5" fill="{WASH}"/>
      <rect x="70" y="113" width="27" height="22" rx="5" fill="{WASH}"/>
      <rect x="109" y="113" width="27" height="22" rx="5" fill="{WASH}"/>
      <circle cx="197" cy="119" r="27" fill="{BLUE}"/>
      <circle cx="197" cy="119" r="13" fill="none" stroke="white" stroke-width="4"/>
      <circle cx="197" cy="119" r="3.5" fill="white"/>
    """,
    "state_recordings": f"""
      <rect x="26" y="32" width="228" height="120" rx="16" fill="white" stroke="{LINE}" stroke-width="2"/>
      <rect x="43" y="48" width="194" height="76" rx="11" fill="{WASH}"/>
      <path d="M69 107V83M80 111V79M91 102V88M183 102V88M194 111V79M205 107V83" stroke="{PALE}" stroke-width="5" stroke-linecap="round"/>
      <circle cx="137" cy="86" r="30" fill="{BLUE}"/>
      <path d="m130 73 19 13-19 13Z" fill="white"/>
      <path d="M56 139h125" stroke="{LINE}" stroke-width="5" stroke-linecap="round"/>
      <circle cx="199" cy="139" r="5" fill="{BLUE}"/>
    """,
    "state_accounts": f"""
      <rect x="34" y="43" width="148" height="99" rx="13" fill="{WASH}" stroke="{LINE}" stroke-width="2"/>
      <rect x="77" y="25" width="166" height="119" rx="15" fill="white" stroke="{BLUE}" stroke-width="3"/>
      <path d="M77 55h166" stroke="{LINE}" stroke-width="2"/>
      <circle cx="100" cy="40" r="4" fill="{PALE}"/>
      <circle cx="113" cy="40" r="4" fill="{WASH}"/>
      <circle cx="119" cy="95" r="23" fill="{WASH}"/>
      <circle cx="119" cy="88" r="7" fill="none" stroke="{BLUE}" stroke-width="4"/>
      <path d="M105 108c2.5-7 7.2-10.5 14-10.5s11.5 3.5 14 10.5" fill="none" stroke="{BLUE}" stroke-width="4" stroke-linecap="round"/>
      <path d="M159 81h52M159 96h40M159 111h30" stroke="{LINE}" stroke-width="7" stroke-linecap="round"/>
      <circle cx="216" cy="124" r="15" fill="{BLUE}"/>
      <circle cx="216" cy="124" r="6" fill="none" stroke="white" stroke-width="2.7"/>
    """,
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, body in GLYPHS.items():
        svg = (
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
            'width="24" height="24" fill="none" color="#182640" '
            'stroke="currentColor" stroke-width="1.8" '
            'stroke-linecap="round" stroke-linejoin="round">'
            f'<title>{name.replace("_", " ")}</title>{body}</svg>'
        )
        (OUT / f"{name}.svg").write_text(svg, encoding="utf-8")
    for name, body in SCENES.items():
        svg = (
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 280 170" '
            'width="280" height="170">'
            f'<title>{name.replace("_", " ")}</title>{body}</svg>'
        )
        (OUT / f"{name}.svg").write_text(svg, encoding="utf-8")
    print(f"Wrote {len(GLYPHS) + len(SCENES)} SVG assets to {OUT}")


if __name__ == "__main__":
    main()

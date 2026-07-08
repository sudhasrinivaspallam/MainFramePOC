#!/usr/bin/env python3
"""Generate all PPT diagram PNGs for the MainFramePOC Devin demo deck.

Reproducible: run `python3 tools/demo/gen_images.py` from the repo root.
Outputs land in assets/ppt-images/.

Palette follows a clean Wells Fargo + Mphasis corporate theme. Hex values for
the Wells Fargo brand colours (red #D71E28, gold #FFCD41) are approximations;
replace with the official Wells Fargo brand guide values if available.
"""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Circle, Rectangle
from matplotlib.lines import Line2D
import numpy as np

# ----------------------------------------------------------------------------
# Palette (Wells Fargo + Mphasis corporate)
# ----------------------------------------------------------------------------
WF_RED       = "#D71E28"   # Wells Fargo primary red (approx.)
WF_DARK_RED  = "#A5121B"   # dark-red header bar
WF_GOLD      = "#FFCD41"   # Wells Fargo gold/yellow accent (approx.)
INK          = "#1F2933"   # primary text
SLATE        = "#3E4C59"   # secondary text
STEEL        = "#52606D"
LIGHT        = "#F5F7FA"   # light panel fill
PANEL        = "#FFFFFF"
BORDER       = "#CBD2D9"
GREEN        = "#2F855A"   # verification / success
BLUE         = "#2B6CB0"   # modern stack
AMBER        = "#B7791F"
MAINFRAME    = "#4A5568"   # legacy mainframe grey

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "ppt-images")
OUT = os.path.abspath(OUT)
os.makedirs(OUT, exist_ok=True)

plt.rcParams.update({
    "font.family": "DejaVu Sans",
    "font.size": 12,
})


def _save(fig, name):
    path = os.path.join(OUT, name)
    fig.savefig(path, dpi=170, bbox_inches="tight", facecolor="white",
                pad_inches=0.15)
    plt.close(fig)
    print("wrote", path)


def rbox(ax, x, y, w, h, text, fc, ec=None, tc="white", fs=12, bold=True,
         rounding=0.12, lw=1.6, align="center"):
    ec = ec or fc
    box = FancyBboxPatch((x, y), w, h,
                         boxstyle=f"round,pad=0.02,rounding_size={rounding}",
                         fc=fc, ec=ec, lw=lw, zorder=2)
    ax.add_patch(box)
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center",
            color=tc, fontsize=fs, fontweight="bold" if bold else "normal",
            zorder=3, wrap=True)
    return (x + w / 2, y + h / 2)


def arrow(ax, p1, p2, color=INK, lw=2.2, style="-|>", ms=18, connent=None,
          rad=0.0):
    a = FancyArrowPatch(p1, p2, arrowstyle=style, mutation_scale=ms,
                        color=color, lw=lw, zorder=1,
                        connectionstyle=f"arc3,rad={rad}")
    ax.add_patch(a)


def title_band(ax, text, x0=0.0, x1=1.0, y=0.955, sub=None):
    ax.text((x0 + x1) / 2, y, text, transform=ax.transAxes, ha="center",
            va="top", fontsize=19, fontweight="bold", color=INK)
    if sub:
        ax.text((x0 + x1) / 2, y - 0.055, sub, transform=ax.transAxes,
                ha="center", va="top", fontsize=12, color=SLATE)


# ============================================================================
# 1. devin-workflow-loop.png
# ============================================================================
def fig_workflow_loop():
    fig, ax = plt.subplots(figsize=(11, 7))
    ax.set_xlim(0, 10); ax.set_ylim(0, 7); ax.axis("off")
    title_band(ax, "How Devin Works — the Autonomous Delivery Loop",
               sub="Plan  \u2192  Code  \u2192  Run / Test  \u2192  Verify diffs  \u2192  Open PR  \u2192  iterate")

    cx, cy, R = 5.0, 3.1, 2.35
    steps = [
        ("1  PLAN", "Read repo,\nscope the task", WF_DARK_RED),
        ("2  CODE", "Edit files in a\nreal workspace", WF_RED),
        ("3  RUN / TEST", "Execute build.sh\n& run.sh", AMBER),
        ("4  VERIFY", "Diff outputs vs.\nbaseline", GREEN),
        ("5  OPEN PR", "Commit & raise\npull request", BLUE),
    ]
    n = len(steps)
    angles = [np.pi/2 - i * 2*np.pi/n for i in range(n)]
    pts = []
    bw, bh = 2.05, 1.05
    for ang in angles:
        x = cx + R * np.cos(ang) * 1.55
        y = cy + R * np.sin(ang)
        pts.append((x, y))

    # arrows around the loop
    for i in range(n):
        p1 = pts[i]; p2 = pts[(i + 1) % n]
        arrow(ax, p1, p2, color=STEEL, lw=2.4, rad=-0.28, ms=20)

    for (title, desc, col), (x, y) in zip(steps, pts):
        rbox(ax, x - bw/2, y - bh/2, bw, bh, "", col, rounding=0.18)
        ax.text(x, y + 0.20, title, ha="center", va="center", color="white",
                fontsize=12.5, fontweight="bold")
        ax.text(x, y - 0.24, desc, ha="center", va="center", color="white",
                fontsize=9.2)

    ax.text(cx, cy, "iterate\nuntil green", ha="center", va="center",
            fontsize=13, fontweight="bold", color=WF_DARK_RED)
    circ = Circle((cx, cy), 0.95, fc=WF_GOLD, ec=WF_DARK_RED, lw=2, zorder=0,
                  alpha=0.35)
    ax.add_patch(circ)
    _save(fig, "devin-workflow-loop.png")


# ============================================================================
# 2. devin-vs-others.png
# ============================================================================
def fig_vs_others():
    fig, ax = plt.subplots(figsize=(13, 7.2))
    ax.set_xlim(0, 13); ax.set_ylim(0, 7.4); ax.axis("off")
    ax.text(6.5, 7.15, "Why Devin Is More Efficient Than Autocomplete Assistants",
            ha="center", va="top", fontsize=16.5, fontweight="bold", color=INK)

    rows = [
        ("Scope",
         "Suggests the next line or block",
         "Owns an end-to-end task across many files"),
        ("Execution",
         "Cannot run code \u2014 you run it",
         "Runs builds, jobs & tests on its own machine"),
        ("Verification",
         "No feedback loop; trusts the guess",
         "Diffs real outputs against a baseline oracle"),
        ("Parallelism",
         "One suggestion at a time in your IDE",
         "Many scoped sessions run concurrently"),
        ("Long-running tasks",
         "Loses context; needs constant steering",
         "Checkpoints & pushes multi-hour work to PRs"),
    ]
    x_label, x_a, x_b = 0.3, 3.5, 8.15
    w_label, w_col = 3.0, 4.55
    top = 5.85
    rh = 0.98
    gap = 0.12

    def cell_left(x, y, w, h, sym, sym_col, text, fc, ec, tc, fs):
        rbox(ax, x, y, w, h, "", fc, ec=ec, rounding=0.1, lw=1.6)
        ax.text(x + 0.30, y + h/2, sym, ha="center", va="center",
                color=sym_col, fontsize=15, fontweight="bold")
        ax.text(x + 0.62, y + h/2, text, ha="left", va="center", color=tc,
                fontsize=fs)

    # headers
    rbox(ax, x_label, top, w_label, 0.78, "Dimension", INK, rounding=0.1, fs=13)
    rbox(ax, x_a, top, w_col, 0.78, "Autocomplete-style assistants", STEEL,
         rounding=0.1, fs=12)
    rbox(ax, x_b, top, w_col, 0.78, "Devin", WF_RED, rounding=0.1, fs=13)

    for i, (dim, a, b) in enumerate(rows):
        y = top - (i + 1) * (rh + gap)
        fc = LIGHT if i % 2 == 0 else PANEL
        rbox(ax, x_label, y, w_label, rh, dim, fc, ec=BORDER, tc=INK, fs=12)
        cell_left(x_a, y, w_col, rh, "\u2717", STEEL, a, PANEL, BORDER, SLATE,
                  10.2)
        cell_left(x_b, y, w_col, rh, "\u2713", GREEN, b, "#FCEBEC", WF_RED,
                  WF_DARK_RED, 10.6)
    _save(fig, "devin-vs-others.png")


# ============================================================================
# 3. devin-capability-grid.png
# ============================================================================
def _icon(ax, kind, x, y, r, color):
    """Draw a simple, robust glyph centred on (x, y) within radius ~r."""
    if kind == "plan":
        # checklist clipboard
        ax.add_patch(FancyBboxPatch((x-r*0.7, y-r), r*1.4, r*2,
                     boxstyle="round,pad=0.02,rounding_size=0.06",
                     fc="white", ec=color, lw=2.2))
        for k in range(3):
            yy = y + r*0.5 - k*r*0.55
            ax.plot([x-r*0.55, x-r*0.15], [yy, yy], color=color, lw=2.4)
            ax.plot([x-r*0.02, x+r*0.5], [yy, yy], color=BORDER, lw=2.4)
            ax.plot([x-r*0.42, x-r*0.30, x-r*0.12],
                    [yy, yy-r*0.14, yy+r*0.16], color=GREEN, lw=1.8)
    elif kind == "terminal":
        ax.add_patch(FancyBboxPatch((x-r, y-r*0.78), 2*r, r*1.56,
                     boxstyle="round,pad=0.02,rounding_size=0.08",
                     fc=INK, ec=INK, lw=2))
        ax.text(x, y-r*0.05, ">_", color=WF_GOLD, fontsize=20, va="center",
                ha="center", fontweight="bold")
    elif kind == "browser":
        ax.add_patch(Circle((x, y), r, fc="white", ec=color, lw=2.2))
        ax.plot([x-r*0.92, x+r*0.92], [y, y], color=color, lw=1.6)
        ax.plot([x-r*0.92, x+r*0.92], [y+r*0.5, y+r*0.5], color=color, lw=1.2)
        ax.plot([x-r*0.92, x+r*0.92], [y-r*0.5, y-r*0.5], color=color, lw=1.2)
        ax.add_patch(matplotlib.patches.Ellipse((x, y), r*1.0, r*2,
                     fill=False, ec=color, lw=1.6))
        ax.plot([x, x], [y-r, y+r], color=color, lw=1.6)
    elif kind == "verify":
        ax.add_patch(Circle((x, y), r, fc=GREEN, ec=GREEN, lw=2))
        ax.plot([x-r*0.45, x-r*0.08, x+r*0.55], [y, y-r*0.42, y+r*0.5],
                color="white", lw=3.4, solid_capstyle="round")
    elif kind == "onboard":
        # open book (two filled pages)
        ax.add_patch(matplotlib.patches.Polygon(
            [(x, y-r*0.85), (x-r*1.05, y-r*0.5), (x-r*1.05, y+r*0.75),
             (x, y+r*0.5)], closed=True, fc="#FBEBD2", ec=color, lw=2.2))
        ax.add_patch(matplotlib.patches.Polygon(
            [(x, y-r*0.85), (x+r*1.05, y-r*0.5), (x+r*1.05, y+r*0.75),
             (x, y+r*0.5)], closed=True, fc="white", ec=color, lw=2.2))
        ax.plot([x, x], [y-r*0.85, y+r*0.5], color=color, lw=2.2)
        for s in (-1, 1):
            for k in range(2):
                yy = y + r*0.05 - k*r*0.35
                ax.plot([x+s*r*0.25, x+s*r*0.85], [yy, yy+s*r*0.12],
                        color=color, lw=1.0)
    elif kind == "parallel":
        ax.add_patch(FancyBboxPatch((x-r*0.85, y-r*0.55), r*1.2, r*1.5,
                     boxstyle="round,pad=0.02,rounding_size=0.05",
                     fc=color, ec=INK, lw=1.6))
        ax.add_patch(FancyBboxPatch((x-r*0.2, y-r*0.95), r*1.2, r*1.5,
                     boxstyle="round,pad=0.02,rounding_size=0.05",
                     fc=WF_GOLD, ec=INK, lw=1.6))
    elif kind == "pr":
        # git branch / merge
        rc = r*0.28
        ax.add_patch(Circle((x-r*0.6, y-r*0.6), rc, fc=color, ec=color))
        ax.add_patch(Circle((x-r*0.6, y+r*0.75), rc, fc=color, ec=color))
        ax.add_patch(Circle((x+r*0.7, y+r*0.75), rc, fc=color, ec=color))
        ax.plot([x-r*0.6, x-r*0.6], [y-r*0.6, y+r*0.75], color=color, lw=3)
        ax.plot([x-r*0.6, x+r*0.7], [y+r*0.75, y+r*0.75], color=color, lw=3)
    elif kind == "memory":
        # database cylinder
        w = r*1.4
        ax.add_patch(matplotlib.patches.Ellipse((x, y+r*0.7), w, r*0.5,
                     fc="white", ec=color, lw=2.2, zorder=3))
        ax.add_patch(Rectangle((x-w/2, y-r*0.7), w, r*1.4, fc="white",
                     ec="none", zorder=1))
        ax.plot([x-w/2, x-w/2], [y-r*0.7, y+r*0.7], color=color, lw=2.2)
        ax.plot([x+w/2, x+w/2], [y-r*0.7, y+r*0.7], color=color, lw=2.2)
        ax.add_patch(matplotlib.patches.Arc((x, y-r*0.7), w, r*0.5,
                     theta1=180, theta2=360, ec=color, lw=2.2))
        for k in range(2):
            ax.add_patch(matplotlib.patches.Arc((x, y+r*0.7-(k+1)*r*0.55), w,
                         r*0.5, theta1=180, theta2=360, ec=color, lw=1.4))


def fig_capability_grid():
    fig, ax = plt.subplots(figsize=(12.5, 7))
    ax.set_xlim(0, 12.5); ax.set_ylim(0, 7.4); ax.axis("off")
    ax.text(6.25, 7.15, "Valuable Devin Capabilities", ha="center", va="top",
            fontsize=18, fontweight="bold", color=INK)

    caps = [
        ("plan", "Autonomous\nplanning", "Breaks a goal into\nordered steps"),
        ("terminal", "Real terminal\n& file system", "Edits code, runs\nshell commands"),
        ("browser", "Browser\naccess", "Reads docs, logs in,\nverifies UIs"),
        ("verify", "Verification\nloops", "Re-runs until\noutputs match"),
        ("onboard", "Repo & knowledge\nonboarding", "Learns README /\nRUN_GUIDE"),
        ("parallel", "Parallel\nagents", "Many sessions\nrun at once"),
        ("pr", "PR-native\nworkflow", "Delivers reviewable\npull requests"),
        ("memory", "Knowledge base\n/ memory", "Reuses learned\nconventions"),
    ]
    cols, rows = 4, 2
    cw, ch = 2.75, 2.6
    gx, gy = 0.28, 0.5
    total_w = cols * cw + (cols - 1) * gx
    x0 = (12.5 - total_w) / 2
    y0 = 0.5
    colors = [WF_RED, INK, BLUE, GREEN, AMBER, WF_DARK_RED, BLUE, AMBER]
    for i, (kind, title, desc) in enumerate(caps):
        c = i % cols; r = i // cols
        x = x0 + c * (cw + gx)
        y = y0 + (rows - 1 - r) * (ch + gy)
        ax.add_patch(FancyBboxPatch((x, y), cw, ch,
                     boxstyle="round,pad=0.02,rounding_size=0.08",
                     fc=PANEL, ec=BORDER, lw=1.8, zorder=0))
        _icon(ax, kind, x + cw/2, y + ch - 0.75, 0.44, colors[i])
        ax.text(x + cw/2, y + 0.95, title, ha="center", va="center",
                fontsize=11.5, fontweight="bold", color=INK)
        ax.text(x + cw/2, y + 0.36, desc, ha="center", va="center",
                fontsize=9.2, color=SLATE)
    _save(fig, "devin-capability-grid.png")


# ============================================================================
# 4. devin-parallel-agents.png
# ============================================================================
def fig_parallel_agents():
    fig, ax = plt.subplots(figsize=(12, 7))
    ax.set_xlim(0, 12); ax.set_ylim(0, 7.6); ax.axis("off")
    title_band(ax, "Parallel Devin Sessions Working Independently",
               sub="Two scoped sessions run concurrently, then merge via pull requests")

    lanes = [
        (2.7, WF_RED, "Session A", "Plastic Issuance  /  DB2",
         ["Plan PI scope", "Code PICRD100\u2013400 + PIONL", "Run PI pipeline",
          "Diff CARDRPT baseline"]),
        (9.3, BLUE, "Session B", "Settlement  /  VSAM",
         ["Plan Settlement scope", "Code STLMT100\u2013400", "Run match pipeline",
          "Diff STLRPT baseline"]),
    ]
    top = 5.55
    bw, bh = 3.6, 0.66
    step_gap = 0.34
    for cx, col, name, sub, steps in lanes:
        rbox(ax, cx - bw/2, top, bw, 0.78, f"{name}\n{sub}", col, rounding=0.12,
             fs=11.5)
        prev = (cx, top)
        for i, s in enumerate(steps):
            y = top - (i + 1) * (bh + step_gap)
            rbox(ax, cx - bw/2, y, bw, bh, s, PANEL, ec=col, tc=INK, fs=10.3,
                 bold=False, lw=1.8)
            arrow(ax, (cx, prev[1]), (cx, y + bh), color=col, lw=2)
            prev = (cx, y)
        # arrow down to merge
        arrow(ax, (cx, prev[1]), (6.0, 1.28), color=col, lw=2.2, rad=0.12)

    rbox(ax, 4.3, 0.4, 3.4, 0.85, "Merge via Pull Requests\n\u2192  main branch",
         WF_DARK_RED, rounding=0.14, fs=12)
    ax.text(6.0, 3.3, "independent\nworkspaces", ha="center", va="center",
            fontsize=10.5, color=STEEL, style="italic")
    _save(fig, "devin-parallel-agents.png")


# ============================================================================
# 5. migration-before-after.png
# ============================================================================
def fig_migration():
    fig, ax = plt.subplots(figsize=(12.5, 7))
    ax.set_xlim(0, 12.5); ax.set_ylim(0, 7.6); ax.axis("off")
    title_band(ax, "Modernization: Mainframe \u2192 Modern Stack")

    # LEFT panel - mainframe
    rbox(ax, 0.3, 0.7, 3.9, 5.6, "", "#EDF0F3", ec=MAINFRAME, rounding=0.06,
         lw=2)
    ax.text(2.25, 6.05, "LEGACY MAINFRAME", ha="center", fontsize=13,
            fontweight="bold", color=MAINFRAME)
    left = [
        ("COBOL batch programs", "PICRD / STLMT job chains"),
        ("CICS online (3270)", "PIONL green screens"),
        ("DB2 relational tables", "TB_CARD_MASTER \u2026"),
        ("VSAM KSDS files", "SETTLE.DAILY.TRANS"),
    ]
    for i, (t, s) in enumerate(left):
        y = 5.1 - i * 1.05
        rbox(ax, 0.6, y, 3.3, 0.82, "", PANEL, ec=MAINFRAME, tc=INK, lw=1.5)
        ax.text(2.25, y + 0.52, t, ha="center", fontsize=10.4,
                fontweight="bold", color=INK)
        ax.text(2.25, y + 0.20, s, ha="center", fontsize=8.6, color=SLATE)

    # RIGHT panel - modern
    rbox(ax, 8.3, 0.7, 3.9, 5.6, "", "#EAF2FB", ec=BLUE, rounding=0.06, lw=2)
    ax.text(10.25, 6.05, "MODERN STACK", ha="center", fontsize=13,
            fontweight="bold", color=BLUE)
    right = [
        (".NET microservices", "batch \u2192 background services"),
        ("React UI", "Wells Fargo-themed screens"),
        ("PostgreSQL", "exact DECIMAL precision"),
        ("REST APIs", "stateless, per business area"),
    ]
    for i, (t, s) in enumerate(right):
        y = 5.1 - i * 1.05
        rbox(ax, 8.6, y, 3.3, 0.82, "", PANEL, ec=BLUE, tc=INK, lw=1.5)
        ax.text(10.25, y + 0.52, t, ha="center", fontsize=10.4,
                fontweight="bold", color=INK)
        ax.text(10.25, y + 0.20, s, ha="center", fontsize=8.6, color=SLATE)

    # MIDDLE gate
    rbox(ax, 4.7, 2.5, 3.1, 2.0, "", WF_GOLD, ec=WF_DARK_RED, rounding=0.1,
         lw=2.2)
    ax.text(6.25, 3.95, "PARALLEL-RUN", ha="center", fontsize=12.5,
            fontweight="bold", color=WF_DARK_RED)
    ax.text(6.25, 3.55, "EQUIVALENCE", ha="center", fontsize=12.5,
            fontweight="bold", color=WF_DARK_RED)
    ax.text(6.25, 3.15, "CHECK", ha="center", fontsize=12.5,
            fontweight="bold", color=WF_DARK_RED)
    ax.text(6.25, 2.75, "old outputs  ==  new outputs", ha="center",
            fontsize=9, style="italic", color=INK)

    arrow(ax, (4.2, 3.5), (4.7, 3.5), color=INK, lw=2.6, ms=22)
    arrow(ax, (7.8, 3.5), (8.3, 3.5), color=INK, lw=2.6, ms=22)
    ax.text(2.25, 0.35, "business rules unchanged", ha="center", fontsize=9,
            color=STEEL, style="italic")
    ax.text(10.25, 0.35, "one business area at a time", ha="center",
            fontsize=9, color=STEEL, style="italic")
    _save(fig, "migration-before-after.png")


# ============================================================================
# 6. architecture-diagram.png
# ============================================================================
def fig_architecture():
    fig, ax = plt.subplots(figsize=(13, 7.8))
    ax.set_xlim(0, 13); ax.set_ylim(0, 8.2); ax.axis("off")
    title_band(ax, "Demo Application Architecture", y=0.985)

    # PI subsystem panel
    rbox(ax, 0.3, 3.35, 8.1, 4.05, "", "#FCEBEC", ec=WF_RED, rounding=0.04, lw=2)
    ax.text(4.35, 7.1, "PLASTIC ISSUANCE (PI) SUBSYSTEM", ha="center",
            fontsize=12.5, fontweight="bold", color=WF_DARK_RED)

    # PI batch chain
    pi_batch = ["PICRD100\nIssuance", "PICRD200\nActivation",
                "PICRD300\nStatus", "PICRD400\nRenewal"]
    bw, bh = 1.75, 0.8
    y = 6.05
    prev = None
    for i, t in enumerate(pi_batch):
        x = 0.55 + i * (bw + 0.16)
        rbox(ax, x, y, bw, bh, t, WF_RED, rounding=0.1, fs=9.5)
        if prev:
            arrow(ax, (prev, y + bh/2), (x, y + bh/2), color=WF_DARK_RED, lw=2)
        prev = x + bw
    ax.text(4.05, 5.85, "batch (COBOL + JCL)", ha="center", fontsize=8.4,
            color=SLATE, style="italic")

    # CICS online row
    rbox(ax, 0.55, 4.35, 1.75, 0.8, "PIONL100\nInquiry", AMBER, rounding=0.1,
         fs=9.5)
    rbox(ax, 2.46, 4.35, 1.75, 0.8, "PIONL200\nUpdate", AMBER, rounding=0.1,
         fs=9.5)
    ax.text(1.5, 3.95, "CICS online (3270)", ha="center", fontsize=8.4,
            color=SLATE, style="italic")

    # DB2 tables (right column of PI panel)
    ax.text(6.35, 5.15, "DB2", ha="center", fontsize=10, fontweight="bold",
            color=WF_DARK_RED)
    db_tables = ["TB_CARD_MASTER", "TB_CARD_TRANSACTION",
                 "TB_CARD_STATUS_HISTORY"]
    for i, t in enumerate(db_tables):
        yy = 4.55 - i * 0.55
        cyl = FancyBboxPatch((4.65, yy), 3.4, 0.45,
                             boxstyle="round,pad=0.01,rounding_size=0.22",
                             fc="white", ec=WF_RED, lw=1.6)
        ax.add_patch(cyl)
        ax.text(6.35, yy + 0.225, t, ha="center", va="center", fontsize=8.6,
                color=INK, fontweight="bold")

    # Settlement subsystem panel
    rbox(ax, 8.6, 3.35, 4.1, 4.05, "", "#EAF2FB", ec=BLUE, rounding=0.04, lw=2)
    ax.text(10.65, 7.1, "SETTLEMENT SUBSYSTEM", ha="center", fontsize=12.5,
            fontweight="bold", color=BLUE)
    stl = ["STLMT100  Extract", "STLMT200  Matching",
           "STLMT300  Reconciliation", "STLMT400  Reporting"]
    for i, t in enumerate(stl):
        yy = 6.15 - i * 0.62
        rbox(ax, 8.85, yy, 3.6, 0.48, t, BLUE, rounding=0.12, fs=9.2)
        if i:
            arrow(ax, (10.65, yy + 0.62), (10.65, yy + 0.48), color=BLUE,
                  lw=1.8, ms=13)
    # VSAM store
    arrow(ax, (10.65, 4.29), (10.65, 4.02), color=BLUE, lw=1.8, ms=13)
    cyl = FancyBboxPatch((9.15, 3.55), 3.0, 0.47,
                         boxstyle="round,pad=0.01,rounding_size=0.22",
                         fc="white", ec=BLUE, lw=1.6)
    ax.add_patch(cyl)
    ax.text(10.65, 3.785, "VSAM KSDS \u00b7 SETTLE.DAILY.TRANS", ha="center",
            va="center", fontsize=8, color=INK, fontweight="bold")

    # Batch job flow band at the bottom
    rbox(ax, 0.3, 0.55, 12.4, 2.5, "", LIGHT, ec=BORDER, rounding=0.04, lw=1.5)
    ax.text(6.5, 2.75, "DAILY BATCH JOB FLOW  (CA7 scheduled)", ha="center",
            fontsize=11.5, fontweight="bold", color=INK)
    jobs = ["PICRD10J", "PICRD20J", "PICRD30J", "PICRD40J",
            "STLMT10J", "STLMT20J", "STLMT30J", "STLMT40J"]
    jw = 1.35
    y = 1.35
    prev = None
    for i, j in enumerate(jobs):
        x = 0.62 + i * (jw + 0.11)
        col = WF_RED if j.startswith("PIC") else BLUE
        rbox(ax, x, y, jw, 0.75, j, col, rounding=0.12, fs=9)
        if prev:
            arrow(ax, (prev, y + 0.375), (x, y + 0.375), color=STEEL, lw=1.8,
                  ms=14)
        prev = x + jw
    _save(fig, "architecture-diagram.png")


# ============================================================================
# 7. pipeline-flow.png
# ============================================================================
def fig_pipeline_flow():
    fig, ax = plt.subplots(figsize=(13, 6.5))
    ax.set_xlim(0, 13); ax.set_ylim(0, 6.8); ax.axis("off")
    title_band(ax, "Local Demo Pipeline — End-to-End Execution Order",
               sub="LOCAL/build.sh compiles \u2022 LOCAL/run.sh runs the full chain")

    stages = [
        ("PILOAD0", "Load 10 sample cards", WF_DARK_RED),
        ("GENDATA", "Generate input files", WF_DARK_RED),
        ("PICRD100", "Card issuance", WF_RED),
        ("PICRD200", "Activation", WF_RED),
        ("PICRD300", "Status update", WF_RED),
        ("PICRD400", "Renewal", WF_RED),
        ("PIONL100", "Card inquiry", AMBER),
        ("PIONL200", "Card update", AMBER),
        ("STLMT100", "Network extract", BLUE),
        ("STLSORT", "VSAM \u2192 sequential", BLUE),
        ("STLMT200", "Matching", BLUE),
        ("STLMT300", "Net settlement", BLUE),
        ("STLMT400", "Mgmt report + SAS", BLUE),
    ]
    cols = 5
    bw, bh = 2.15, 0.98
    gx, gy = 0.35, 0.55
    x0, y0 = 0.55, 4.25
    positions = []
    for i, (name, desc, col) in enumerate(stages):
        r = i // cols
        c = i % cols
        # serpentine
        if r % 2 == 1:
            c = cols - 1 - c
        x = x0 + c * (bw + gx)
        y = y0 - r * (bh + gy)
        positions.append((x, y, c, r))
        rbox(ax, x, y, bw, bh, "", col, rounding=0.14)
        ax.text(x + bw/2, y + bh - 0.32, name, ha="center", va="center",
                color="white", fontsize=10.5, fontweight="bold")
        ax.text(x + bw/2, y + 0.30, desc, ha="center", va="center",
                color="white", fontsize=8.3)

    # arrows following serpentine order
    for i in range(len(stages) - 1):
        x1, y1, c1, r1 = positions[i]
        x2, y2, c2, r2 = positions[i + 1]
        if r1 == r2:
            if x2 > x1:
                arrow(ax, (x1 + bw, y1 + bh/2), (x2, y2 + bh/2), color=STEEL,
                      lw=2, ms=15)
            else:
                arrow(ax, (x1, y1 + bh/2), (x2 + bw, y2 + bh/2), color=STEEL,
                      lw=2, ms=15)
        else:
            arrow(ax, (x1 + bw/2, y1), (x2 + bw/2, y2 + bh), color=STEEL,
                  lw=2, ms=15)

    # output note
    rbox(ax, 8.9, 0.35, 3.6, 0.85,
         "Key outputs \u2192 OUTPUT/CARDRPT.txt,\nSTLRPT*.txt, MGTRPT.txt, SASOUT.csv",
         GREEN, rounding=0.12, fs=9.2)
    _save(fig, "pipeline-flow.png")


if __name__ == "__main__":
    fig_workflow_loop()
    fig_vs_others()
    fig_capability_grid()
    fig_parallel_agents()
    fig_migration()
    fig_architecture()
    fig_pipeline_flow()
    print("\nAll images generated in", OUT)

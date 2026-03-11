#!/usr/bin/env python3
"""
Generate a beautiful app icon for Unravel Mental Wellness app.
Design: Soft gradient background (lavender → peach) with an abstract
unraveling spiral/thread that symbolizes mental clarity and peace.
"""

from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 1024
CENTER = SIZE // 2
img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# ─── Background: Rounded square with gradient ───
def lerp_color(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

# Warm lavender to soft peach diagonal gradient
c_top_left = (200, 170, 195)      # warm lavender (#C8AAC3)
c_bottom_right = (240, 195, 170)  # soft peach (#F0C3AA)
c_top_right = (210, 185, 210)     # pale lilac
c_bottom_left = (235, 200, 185)   # cream peach

for y in range(SIZE):
    for x in range(SIZE):
        # Diagonal gradient
        t = (x / SIZE * 0.5 + y / SIZE * 0.5)
        color = lerp_color(c_top_left, c_bottom_right, t)
        img.putpixel((x, y), (*color, 255))

# Round the corners
mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
radius = SIZE // 4  # Standard app icon corner radius
mask_draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=radius, fill=255)

# Apply rounded corners
bg = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
bg.paste(img, mask=mask)
img = bg
draw = ImageDraw.Draw(img)

# ─── Draw abstract unraveling spiral ───
# A calming spiral that "unravels" outward - representing mental clarity

def draw_smooth_spiral(draw, cx, cy, start_r, end_r, turns, width_start, width_end, color_start, color_end, steps=600):
    """Draw a smooth spiral with varying width and color."""
    points = []
    for i in range(steps + 1):
        t = i / steps
        angle = t * turns * 2 * math.pi - math.pi / 2
        r = start_r + (end_r - start_r) * t
        x = cx + r * math.cos(angle)
        y = cy + r * math.sin(angle)
        points.append((x, y, t))

    # Draw spiral as series of circles/lines with varying width
    for i in range(len(points) - 1):
        x1, y1, t1 = points[i]
        x2, y2, t2 = points[i + 1]

        t = (t1 + t2) / 2
        width = width_start + (width_end - width_start) * t
        color = lerp_color(color_start, color_end, t)

        # Add slight transparency
        alpha = int(255 - t * 60)

        draw.line([(x1, y1), (x2, y2)], fill=(*color, alpha), width=max(1, int(width)))

# Main spiral - unraveling from center
spiral_color_start = (255, 255, 255)  # White center
spiral_color_end = (180, 160, 190)    # Soft purple end

draw_smooth_spiral(
    draw, CENTER, CENTER - 20,
    start_r=30, end_r=250,
    turns=3.2,
    width_start=28, width_end=8,
    color_start=spiral_color_start,
    color_end=spiral_color_end,
    steps=800
)

# Second decorative spiral (subtle, offset)
draw_smooth_spiral(
    draw, CENTER + 10, CENTER - 10,
    start_r=50, end_r=200,
    turns=2.5,
    width_start=6, width_end=2,
    color_start=(255, 255, 255),
    color_end=(220, 200, 210),
    steps=500
)

# ─── Central dot (calm center point) ───
dot_r = 22
for r in range(dot_r + 15, dot_r, -1):
    alpha = int(80 * (1 - (r - dot_r) / 15))
    draw.ellipse(
        [CENTER - r, CENTER - 20 - r, CENTER + r, CENTER - 20 + r],
        fill=(255, 255, 255, alpha)
    )
draw.ellipse(
    [CENTER - dot_r, CENTER - 20 - dot_r, CENTER + dot_r, CENTER - 20 + dot_r],
    fill=(255, 255, 255, 230)
)

# ─── Add subtle "U" letterform in the center ───
try:
    # Try to use a nice font
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 90)
except:
    try:
        font = ImageFont.truetype("/usr/share/fonts/TTF/DejaVuSans-Bold.ttf", 90)
    except:
        font = ImageFont.load_default()

# Draw "U" letter in center
text = "U"
bbox = draw.textbbox((0, 0), text, font=font)
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
tx = CENTER - tw // 2
ty = CENTER - 20 - th // 2 - 8

# Subtle shadow
draw.text((tx + 2, ty + 2), text, fill=(150, 130, 150, 60), font=font)
# Main letter
draw.text((tx, ty), text, fill=(120, 90, 120, 200), font=font)

# ─── Add gentle glow overlay ───
glow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
glow_draw = ImageDraw.Draw(glow)
for r in range(200, 0, -2):
    alpha = int(15 * (1 - r / 200))
    glow_draw.ellipse(
        [CENTER - r, CENTER - 20 - r, CENTER + r, CENTER - 20 + r],
        fill=(255, 255, 255, alpha)
    )

img = Image.alpha_composite(img, glow)

# ─── Save ───
img.save('assets/app_icon.png', 'PNG')
print(f"✅ App icon generated: assets/app_icon.png ({SIZE}x{SIZE})")

# Also create an adaptive icon foreground (no rounded corners, with padding)
fg = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
fg_draw = ImageDraw.Draw(fg)

# Redraw everything on transparent background for adaptive icon
# Background layer (solid gradient)
adaptive_bg = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
for y in range(SIZE):
    for x in range(SIZE):
        t = (x / SIZE * 0.5 + y / SIZE * 0.5)
        color = lerp_color(c_top_left, c_bottom_right, t)
        adaptive_bg.putpixel((x, y), (*color, 255))

adaptive_bg.save('assets/app_icon_background.png', 'PNG')
print(f"✅ Adaptive background: assets/app_icon_background.png")

# Foreground layer (just the spiral + letter on transparent)
fg = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
fg_draw = ImageDraw.Draw(fg)

draw_smooth_spiral(
    fg_draw, CENTER, CENTER - 20,
    start_r=30, end_r=250,
    turns=3.2,
    width_start=28, width_end=8,
    color_start=spiral_color_start,
    color_end=spiral_color_end,
    steps=800
)

draw_smooth_spiral(
    fg_draw, CENTER + 10, CENTER - 10,
    start_r=50, end_r=200,
    turns=2.5,
    width_start=6, width_end=2,
    color_start=(255, 255, 255),
    color_end=(220, 200, 210),
    steps=500
)

# Central dot
for r in range(dot_r + 15, dot_r, -1):
    alpha = int(80 * (1 - (r - dot_r) / 15))
    fg_draw.ellipse(
        [CENTER - r, CENTER - 20 - r, CENTER + r, CENTER - 20 + r],
        fill=(255, 255, 255, alpha)
    )
fg_draw.ellipse(
    [CENTER - dot_r, CENTER - 20 - dot_r, CENTER + dot_r, CENTER - 20 + dot_r],
    fill=(255, 255, 255, 230)
)

fg_draw.text((tx + 2, ty + 2), text, fill=(150, 130, 150, 60), font=font)
fg_draw.text((tx, ty), text, fill=(120, 90, 120, 200), font=font)

# Add glow
fg = Image.alpha_composite(fg, glow)
fg.save('assets/app_icon_foreground.png', 'PNG')
print(f"✅ Adaptive foreground: assets/app_icon_foreground.png")


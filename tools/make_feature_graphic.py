# Makes store/graphics/feature_1024x500.png. Usage: python tools/make_feature_graphic.py <project dir>
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter
root = sys.argv[1]
W, H = 1024, 500
# Background: a gameplay board, softly blurred, under a light wash.
shot = Image.open(root + '/store/graphics/source/board_w7.png').convert('RGB')
crop = shot.crop((0, 560, 1080, 560 + int(1080 * H / W)))
bg = crop.resize((W, H)).filter(ImageFilter.GaussianBlur(6))
wash = Image.new('RGB', (W, H), (255, 244, 226))
bg = Image.blend(bg, wash, 0.35)
img = bg.convert('RGBA')
# Icon tile on the right, rounded with a soft shadow.
icon = Image.open(root + '/icons/icon.png').convert('RGBA').resize((380, 380), Image.LANCZOS)
mask = Image.new('L', icon.size, 0)
ImageDraw.Draw(mask).rounded_rectangle((0, 0, 379, 379), radius=72, fill=255)
shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
ImageDraw.Draw(shadow).rounded_rectangle((598, 72, 598 + 380, 72 + 380), radius=72, fill=(46, 42, 74, 110))
img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(14)))
img.paste(icon, (590, 60), mask)
d = ImageDraw.Draw(img)
def font(size, weight):
    f = ImageFont.truetype(root + '/fonts/Nunito.ttf', size)
    try:
        f.set_variation_by_axes([weight])
    except Exception:
        pass
    return f
ink = (46, 42, 74)
size = 112
while True:
    title = font(size, 900)
    l, t, r, b = d.textbbox((0, 0), 'BOOMLETS', font=title, stroke_width=10)
    if r - l <= 500:
        break
    size -= 2
d.text((300, 190), 'BOOMLETS', font=title, fill=(255, 209, 102), anchor='mm', stroke_width=10, stroke_fill=ink)
# Tagline on a cream pill.
tag = font(36, 800)
d.rounded_rectangle((66, 285, 534, 395), radius=30, fill=(255, 244, 226, 235))
d.text((300, 318), 'Pop pods. Blast crates.', font=tag, fill=ink, anchor='mm')
d.text((300, 362), 'Outsmart the critters!', font=tag, fill=ink, anchor='mm')
img.convert('RGB').save(root + '/store/graphics/feature_1024x500.png')

# Makes the 8 Play Store phone screenshots (1080x1920) in store/graphics from
# close-up renders in shots/ (see store/listing.md for the render commands).
# Usage: python tools/make_store_screens.py <project dir>
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

root = sys.argv[1]
W, H, TOP = 1080, 1920, 420
INK = (46, 42, 74)
CREAM = (255, 244, 226)
YELLOW = (255, 209, 102)


def font(size, weight):
    f = ImageFont.truetype(root + '/fonts/Nunito.ttf', size)
    try:
        f.set_variation_by_axes([weight])
    except Exception:
        pass
    return f


def fit(d, text, size, weight, width):
    while True:
        f = font(size, weight)
        l, t, r, b = d.textbbox((0, 0), text, font=f)
        if r - l <= width:
            return f
        size -= 2


def rounded(img, radius):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, img.size[0] - 1, img.size[1] - 1), radius=radius, fill=255)
    return mask


def collage():
    """Six boss portraits with name tags, 1080x1500."""
    bosses = [(2, 'CAPTAIN CLAWDIA'), (3, 'BARON BURROW'), (4, 'BIG BRRR'),
              (7, 'GEODE GOLEM'), (15, 'ORIGAMI DRAGON'), (23, 'SEASON STAG')]
    img = Image.new('RGB', (1080, 1500), CREAM)
    d = ImageDraw.Draw(img)
    tw, th, gap = 510, 466, 20
    tag = font(34, 900)
    for i, (w, name) in enumerate(bosses):
        p = Image.open(f'{root}/shots/p_{w}.png').convert('RGB')
        s = p.resize((tw + 40, tw + 40), Image.LANCZOS)
        s = s.crop((20, 10, 20 + tw, 10 + th))
        x = gap + (i % 2) * (tw + gap)
        y = gap + (i // 2) * (th + gap) + 12
        img.paste(s, (x, y), rounded(s, 36))
        l, t, r, b = d.textbbox((0, 0), name, font=tag)
        pw = r - l + 48
        cx = x + tw // 2
        d.rounded_rectangle((cx - pw // 2, y + th - 74, cx + pw // 2, y + th - 20), radius=27, fill=INK)
        d.text((cx, y + th - 47), name, font=tag, fill=YELLOW, anchor='mm')
    return img


SCREENS = [
    ('f_1', 'Pop pods.', 'Outsmart the critters!'),
    ('f_9', 'Blast your way', 'through boss battles'),
    (None, 'Meet 25 big,', 'silly bosses'),
    ('f_11', '25 worlds, each', 'with its own twist'),
    ('f_5', 'Tap to walk.', 'Double-tap to drop a pod.'),
    ('f_22', '150 levels and', '450 stars to collect'),
    ('f_17', 'Cozy 3D worlds for', 'a quick coffee break'),
    ('f_25', 'Free to play.', 'No account needed.'),
]

for n, (shot, line1, line2) in enumerate(SCREENS, 1):
    game = collage() if shot is None else Image.open(f'{root}/shots/{shot}.png').convert('RGB')
    game = game.resize((W, H - TOP), Image.LANCZOS)
    img = Image.new('RGB', (W, H), CREAM)
    img.paste(game, (0, TOP))
    # A soft shadow where the caption band meets the game.
    shade = Image.new('RGBA', (W, 40), (0, 0, 0, 0))
    ImageDraw.Draw(shade).rectangle((0, 0, W, 14), fill=(46, 42, 74, 70))
    img.paste(Image.new('RGB', (W, 40), INK), (0, TOP), shade.filter(ImageFilter.GaussianBlur(8)).split()[3])
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, W, TOP), fill=CREAM)
    f1 = fit(d, line1, 104, 900, 960)
    f2 = fit(d, line2, 80, 800, 960)
    d.text((W // 2, 150), line1, font=f1, fill=INK, anchor='mm', stroke_width=0)
    # Second line on a yellow pill.
    l, t, r, b = d.textbbox((W // 2, 290), line2, font=f2, anchor='mm')
    d.rounded_rectangle((l - 34, t - 22, r + 34, b + 22), radius=(b - t + 44) // 2, fill=YELLOW)
    d.text((W // 2, 290), line2, font=f2, fill=INK, anchor='mm')
    out = f'{root}/store/graphics/screen_{n}.png'
    img.save(out)
    print(out, img.size)

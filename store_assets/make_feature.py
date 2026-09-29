from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1024, 500
FONT_DIR = "assets/fonts/PlaypenSansArabic/"
DARK = (47, 62, 44)
MUTED = (104, 118, 96)

bg = Image.new("RGB", (W, H), (247, 243, 236))
grad = Image.linear_gradient("L").rotate(90).resize((W, H))
bg = Image.composite(Image.new("RGB", (W, H), (232, 227, 218)), bg, grad)

board = Image.open("store_assets/screenshot_02_gameplay.png").convert("RGB")
pattern = board.crop((60, 440, 1020, 1520)).resize((W, int(W * 1080 / 960)))
pattern = pattern.crop((0, 0, W, H)).convert("L")
bg = Image.composite(Image.new("RGB", (W, H), (226, 221, 211)), bg,
                     pattern.point(lambda p: 90 if p < 120 else 0))
fade = Image.new("L", (W, H), 0)
ImageDraw.Draw(fade).rectangle((0, 0, 640, H), fill=235)
fade = fade.filter(ImageFilter.GaussianBlur(90))
bg = Image.composite(Image.new("RGB", (W, H), (245, 241, 234)), bg, fade)

canvas = bg.convert("RGBA")

phone_h = 560
shot = Image.open("store_assets/screenshot_03_boss_hint.png").convert("RGBA")
pw = int(shot.width * phone_h / shot.height)
shot = shot.resize((pw, phone_h), Image.LANCZOS)
bez = 12
phone = Image.new("RGBA", (pw + bez * 2, phone_h + bez * 2), (0, 0, 0, 0))
ImageDraw.Draw(phone).rounded_rectangle(
    (0, 0, phone.width - 1, phone.height - 1), radius=44, fill=(40, 48, 38, 255))
mask = Image.new("L", shot.size, 0)
ImageDraw.Draw(mask).rounded_rectangle((0, 0, pw - 1, phone_h - 1), radius=34, fill=255)
phone.paste(shot, (bez, bez), mask)
phone = phone.rotate(-8, resample=Image.BICUBIC, expand=True)
shadow = Image.new("RGBA", phone.size, (0, 0, 0, 0))
shadow.putalpha(phone.split()[3].point(lambda a: 70 if a else 0))
shadow = shadow.filter(ImageFilter.GaussianBlur(18))
px, py = 668, 12
canvas.alpha_composite(shadow, (px + 10, py + 16))
canvas.alpha_composite(phone, (px, py))

icon = Image.open("store_assets/icon_512.png").convert("RGBA").resize((132, 132), Image.LANCZOS)
imask = Image.new("L", icon.size, 0)
ImageDraw.Draw(imask).rounded_rectangle((0, 0, 131, 131), radius=30, fill=255)
icon.putalpha(imask)
ishadow = Image.new("RGBA", (172, 172), (0, 0, 0, 0))
ImageDraw.Draw(ishadow).rounded_rectangle((20, 24, 152, 156), radius=30, fill=(0, 0, 0, 60))
ishadow = ishadow.filter(ImageFilter.GaussianBlur(10))
canvas.alpha_composite(ishadow, (48, 48))
canvas.alpha_composite(icon, (68, 68))

d = ImageDraw.Draw(canvas)
title = ImageFont.truetype(FONT_DIR + "PlaypenSansArabic-ExtraBold.ttf", 78)
tag = ImageFont.truetype(FONT_DIR + "PlaypenSansArabic-SemiBold.ttf", 30)
small = ImageFont.truetype(FONT_DIR + "PlaypenSansArabic-Medium.ttf", 24)
d.text((64, 222), "Arrow Escape", font=title, fill=DARK)
d.text((68, 330), "Slide every arrow out of the grid!", font=tag, fill=MUTED)

x, y = 68, 392
for label in ("1000 levels", "Boss battles", "Daily challenge"):
    tw = d.textlength(label, font=small)
    d.rounded_rectangle((x, y, x + tw + 32, y + 44), radius=22, fill=(93, 112, 84))
    d.text((x + 16, y + 5), label, font=small, fill=(255, 255, 255))
    x += tw + 32 + 12

canvas.convert("RGB").save("store_assets/feature_graphic_1024x500.png", optimize=True)

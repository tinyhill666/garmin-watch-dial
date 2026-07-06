#!/usr/bin/env python3
"""TTF -> BMFont (.fnt + .png) 生成器，供 Connect IQ 自定义字体使用。

用法: python3 tools/gen_bmfont.py
按 design/design-v4.md 的字体规格表生成 resources/fonts/ 下的全部字体。
字形为白色+alpha，Connect IQ 渲染时按前景色着色。
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "design", "fonts-src")
OUT = os.path.join(ROOT, "resources", "fonts")
PAD = 2  # 图集内字形间距


SS = 3  # 文字字形超采样倍率：高分辨率渲染再下采样，边缘抗锯齿更平滑


def gen_text_font(ttf, size, charset, name):
    font = ImageFont.truetype(os.path.join(SRC, ttf), size)
    ascent, descent = font.getmetrics()
    hi = ImageFont.truetype(os.path.join(SRC, ttf), size * SS)
    # 每字形: [ch, 记录用xoffset, y0, w, h, xadvance, 高清渲染图]
    glyphs = []
    for ch in charset:
        x0, y0, x1, y1 = font.getbbox(ch)
        w, h = x1 - x0, y1 - y0
        adv = round(font.getlength(ch))
        img = None
        if w > 0 and h > 0:
            # 高清渲染整字，按原生 bbox×SS 裁出字形，再下采样到原生尺寸
            hx0, hy0 = x0 * SS, y0 * SS
            canvas = Image.new("L", ((w + 2) * SS, (h + 2) * SS), 0)
            ImageDraw.Draw(canvas).text((SS - hx0, SS - hy0), ch, font=hi, fill=255)
            img = canvas.resize((w + 2, h + 2), Image.LANCZOS)
        glyphs.append([ch, x0, y0, w, h, adv, img])

    # 数字强制等宽（tabular）：统一步进为数字最大步进，仅调整记录里的 xoffset
    digit_adv = max(g[5] for g in glyphs if g[0].isdigit())
    for g in glyphs:
        if g[0].isdigit():
            g[1] += (digit_adv - g[5]) // 2
            g[5] = digit_adv

    atlas_w = sum(g[3] for g in glyphs) + PAD * (len(glyphs) + 1)
    atlas_h = max((g[4] for g in glyphs), default=1) + PAD * 2
    atlas = Image.new("RGBA", (max(atlas_w, 1), atlas_h), (0, 0, 0, 0))

    chars = []
    cx = PAD
    for ch, xoff, y0, w, h, adv, img in glyphs:
        if img is not None:
            # img 含 1px 余量（上/左各 1），贴入时对齐到 (cx-1, PAD-1)
            white = Image.new("RGBA", img.size, (255, 255, 255, 0))
            white.putalpha(img)
            atlas.alpha_composite(white, (cx - 1, PAD - 1))
        chars.append(
            f"char id={ord(ch)} x={cx} y={PAD} width={w} height={h} "
            f"xoffset={xoff} yoffset={y0} xadvance={adv} page=0 chnl=15"
        )
        cx += w + PAD

    write_fnt(name, ttf, size, ascent + descent, ascent, atlas, chars)


def _fill_bezier(draw, pts_ctrl, scale, fill):
    """采样多段三次贝塞尔为多边形并填充。pts_ctrl: [(p0,c1,c2,p1), ...]"""
    poly = []
    for p0, c1, c2, p1 in pts_ctrl:
        for i in range(25):
            t = i / 24
            mt = 1 - t
            x = mt**3 * p0[0] + 3 * mt**2 * t * c1[0] + 3 * mt * t**2 * c2[0] + t**3 * p1[0]
            y = mt**3 * p0[1] + 3 * mt**2 * t * c1[1] + 3 * mt * t**2 * c2[1] + t**3 * p1[1]
            poly.append((x * scale, y * scale))
    draw.polygon(poly, fill=fill)


def gen_icon_font(name):
    """图标字体：H=心形(18x16) F=足迹(20x24) S=太阳(22x22) C=火焰(20x24)，4x 超采样后缩小。"""
    S = 4
    white = (255, 255, 255, 255)

    # 心形：design-v4.svg 的贝塞尔路径，归一化到 18x15.3
    heart_hi = Image.new("RGBA", (18 * S, 16 * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(heart_hi)
    _fill_bezier(d, [
        ((9, 15.3), (3.6, 10.8), (0, 7.65), (0, 4.32)),
        ((0, 4.32), (0, 1.71), (1.98, 0), (4.32, 0)),
        ((4.32, 0), (6.21, 0), (8.01, 1.08), (9, 2.7)),
        ((9, 2.7), (9.99, 1.08), (11.79, 0), (13.68, 0)),
        ((13.68, 0), (16.02, 0), (18, 1.71), (18, 4.32)),
        ((18, 4.32), (18, 7.65), (14.4, 10.8), (9, 15.3)),
    ], S, white)
    heart = heart_hi.resize((18, 16), Image.LANCZOS)

    # 足迹：两枚斜置胶囊鞋印（无跟点），左低右高，干净可辨
    capsule = Image.new("RGBA", (9 * S, 15 * S), (0, 0, 0, 0))
    dc_ = ImageDraw.Draw(capsule)
    dc_.rounded_rectangle([0, 0, 9 * S - 1, 15 * S - 1], radius=4 * S, fill=white)
    left_p = capsule.rotate(-14, expand=True, resample=Image.BICUBIC)
    right_p = capsule.rotate(14, expand=True, resample=Image.BICUBIC)
    foot_hi = Image.new("RGBA", (22 * S, 24 * S), (0, 0, 0, 0))
    foot_hi.alpha_composite(left_p, (0, 24 * S - left_p.height))
    foot_hi.alpha_composite(right_p, (22 * S - right_p.width, 0))
    foot = foot_hi.resize((22, 24), Image.LANCZOS)

    # 太阳：中心圆 + 8 根细射线，圆与射线留足间隙保证可辨
    import math
    sun_hi = Image.new("RGBA", (22 * S, 22 * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(sun_hi)
    d.ellipse([(11 - 4.5) * S, (11 - 4.5) * S, (11 + 4.5) * S, (11 + 4.5) * S], fill=white)
    for k in range(8):
        ang = math.pi * k / 4
        x1, y1 = 11 + 7.5 * math.cos(ang), 11 + 7.5 * math.sin(ang)
        x2, y2 = 11 + 10.8 * math.cos(ang), 11 + 10.8 * math.sin(ang)
        d.line([x1 * S, y1 * S, x2 * S, y2 * S], fill=white, width=int(1.4 * S))
    sun = sun_hi.resize((22, 22), Image.LANCZOS)

    # 火焰：更尖更右倾的火苗尖 + 底部圆
    flame_hi = Image.new("RGBA", (20 * S, 24 * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(flame_hi)
    d.ellipse([(10.5 - 5.75) * S, (17.7 - 5.75) * S, (10.5 + 5.75) * S, (17.7 + 5.75) * S], fill=white)
    _fill_bezier(d, [
        ((5.0, 17.0), (3.0, 9.0), (9.5, 7.0), (14.0, 0)),
        ((14.0, 0), (12.5, 5.5), (16.2, 9.5), (16.2, 15.0)),
        ((16.2, 15.0), (16.2, 16.0), (16.0, 17.0), (15.5, 18.0)),
    ], S, white)
    flame = flame_hi.resize((20, 24), Image.LANCZOS)

    widths = [18, 22, 22, 20]
    atlas = Image.new("RGBA", (sum(widths) + PAD * 5, 24 + PAD * 2), (0, 0, 0, 0))
    atlas.paste(heart, (PAD, PAD))
    atlas.paste(foot, (PAD * 2 + 18, PAD))
    atlas.paste(sun, (PAD * 3 + 40, PAD + 1))
    atlas.paste(flame, (PAD * 4 + 62, PAD))
    chars = [
        f"char id={ord('H')} x={PAD} y={PAD} width=18 height=16 xoffset=0 yoffset=0 xadvance=20 page=0 chnl=15",
        f"char id={ord('F')} x={PAD * 2 + 18} y={PAD} width=22 height=24 xoffset=0 yoffset=0 xadvance=24 page=0 chnl=15",
        f"char id={ord('S')} x={PAD * 3 + 40} y={PAD + 1} width=22 height=22 xoffset=0 yoffset=0 xadvance=24 page=0 chnl=15",
        f"char id={ord('C')} x={PAD * 4 + 62} y={PAD} width=20 height=24 xoffset=0 yoffset=0 xadvance=22 page=0 chnl=15",
    ]
    write_fnt(name, "icons", 24, 24, 24, atlas, chars)


def gen_material_icons(name, size, mapping):
    """从 Material Symbols Rounded 可变字体渲染图标字形。

    mapping: {目标字符: 图标 codepoint}。FILL=1 实心变体，小尺寸更清晰。
    """
    font = ImageFont.truetype(os.path.join(SRC, "MaterialSymbolsRounded.ttf"), size)
    # 轴顺序固定为 [FILL, GRAD, opsz, wght]（见字体文件名），按序设值取实心变体
    axes = font.get_variation_axes()
    if len(axes) == 4:
        font.set_variation_by_axes([1, 0, 24, 400])
    else:
        print(f"warning: unexpected axes {axes}")

    glyphs = []
    for ch, cp in mapping.items():
        g = chr(cp)
        x0, y0, x1, y1 = font.getbbox(g)
        glyphs.append((ch, g, x0, y0, x1 - x0, y1 - y0))

    max_h = max(g[5] for g in glyphs)
    atlas_w = sum(g[4] for g in glyphs) + PAD * (len(glyphs) + 1)
    atlas = Image.new("RGBA", (atlas_w, max_h + PAD * 2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(atlas)

    chars = []
    cx = PAD
    for ch, g, x0, y0, w, h in glyphs:
        draw.text((cx - x0, PAD - y0), g, font=font, fill=(255, 255, 255, 255))
        chars.append(
            f"char id={ord(ch)} x={cx} y={PAD} width={w} height={h} "
            f"xoffset=0 yoffset=0 xadvance={w + 2} page=0 chnl=15"
        )
        cx += w + PAD

    write_fnt(name, "material-symbols", size, max_h, max_h, atlas, chars)


def quantize_alpha(atlas):
    """量化 alpha 到 4 级（0/85/170/255），忠实就近取整。

    MIP 屏白字黑底的可用灰阶只有 0x00/0x55/0xAA/0xFF；设备本就会把
    其它 alpha 就近映射到这 4 级。这里用同样的就近取整预量化，既与设备
    一致、又**保留抗锯齿过渡像素**（不像收窄过渡带那样把边缘压成硬台阶，
    小字号曲线才不会呈锯齿）。
    """
    r, g, b, a = atlas.split()
    lut = [int(round(v / 85.0)) * 85 for v in range(256)]
    a = a.point(lut)
    return Image.merge("RGBA", (r, g, b, a))


def write_fnt(name, face, size, line_h, base, atlas, chars):
    os.makedirs(OUT, exist_ok=True)
    atlas = quantize_alpha(atlas)
    atlas.save(os.path.join(OUT, f"{name}.png"))
    with open(os.path.join(OUT, f"{name}.fnt"), "w") as f:
        f.write(
            f'info face="{face}" size=-{size} bold=0 italic=0 charset="" unicode=1 '
            f'stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing={PAD},{PAD} outline=0\n'
        )
        f.write(
            f"common lineHeight={line_h} base={base} scaleW={atlas.width} "
            f"scaleH={atlas.height} pages=1 packed=0 alphaChnl=1 redChnl=0 greenChnl=0 blueChnl=0\n"
        )
        f.write(f'page id=0 file="{name}.png"\n')
        f.write(f"chars count={len(chars)}\n")
        f.write("\n".join(chars) + "\n")
    print(f"{name}: {atlas.width}x{atlas.height}, {len(chars)} chars")


if __name__ == "__main__":
    # v6.1: 时间 92px（保证秒不越圆界），秒专用 20px，图标用 Material Symbols
    gen_text_font("BarlowSemiCondensed-Bold.ttf", 92, "0123456789", "tempo-bold-92")
    gen_text_font("TitilliumWeb-SemiBold.ttf", 26,
                  " -/.°0123456789ABCDEFGHIJLMNOPRSTUVWYk", "tempo-semibold-26")
    gen_text_font("TitilliumWeb-SemiBold.ttf", 32, "0123456789", "tempo-semibold-32")
    gen_material_icons("tempo-icons", 22, {
        "H": 0xE87E,  # favorite 心形
        "F": 0xF87D,  # footprint 足迹
        "S": 0xE81A,  # sunny 晴
        "P": 0xF172,  # partly_cloudy_day 少云
        "O": 0xF15C,  # cloud 阴/多云
        "R": 0xF176,  # rainy 雨
        "W": 0xE2CD,  # weather_snowy 雪
        "T": 0xEBDB,  # thunderstorm 雷
        "G": 0xE818,  # foggy 雾霾
        "B": 0xEA0B,  # bolt 身体电量（备用）
        "C": 0xEF55,  # local_fire_department 卡路里（备用）
        # 压力四档表情（随值切换）
        "1": 0xF6A7,  # sentiment_calm 静息 0-25
        "2": 0xE813,  # sentiment_satisfied 低 26-50
        "3": 0xE812,  # sentiment_neutral 中 51-75
        "4": 0xF6A2,  # sentiment_stressed 高 76-100
    })

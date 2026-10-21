// ColorUtils.js
// Ported from Windows PowerToys Color Picker (modules/color_picker/model.rs)
// Pure JavaScript implementation compatible with QML QtQuick / Quickshell runtime.

.pragma library

const PALETTE = [
    ["Alice blue", 240, 248, 255],
    ["Antique white", 250, 235, 215],
    ["Aqua", 0, 255, 255],
    ["Aquamarine", 127, 255, 212],
    ["Azure", 240, 255, 255],
    ["Beige", 245, 245, 220],
    ["Bisque", 255, 228, 196],
    ["Black", 0, 0, 0],
    ["Blanched almond", 255, 235, 205],
    ["Blue", 0, 0, 255],
    ["Blue violet", 138, 43, 226],
    ["Brown", 165, 42, 42],
    ["Burlywood", 222, 184, 135],
    ["Cadet blue", 95, 158, 160],
    ["Chartreuse", 127, 255, 0],
    ["Chocolate", 210, 105, 30],
    ["Coral", 255, 127, 80],
    ["Cornflower blue", 100, 149, 237],
    ["Cornsilk", 255, 248, 220],
    ["Crimson", 220, 20, 60],
    ["Cyan", 0, 255, 255],
    ["Dark blue", 0, 0, 139],
    ["Dark cyan", 0, 139, 139],
    ["Dark goldenrod", 184, 134, 11],
    ["Dark gray", 169, 169, 169],
    ["Dark green", 0, 100, 0],
    ["Dark khaki", 189, 183, 107],
    ["Dark magenta", 139, 0, 139],
    ["Dark olive green", 85, 107, 47],
    ["Dark orange", 255, 140, 0],
    ["Dark orchid", 153, 50, 204],
    ["Dark red", 139, 0, 0],
    ["Dark salmon", 233, 150, 122],
    ["Dark sea green", 143, 188, 143],
    ["Dark slate blue", 72, 61, 139],
    ["Dark slate gray", 47, 79, 79],
    ["Dark turquoise", 0, 206, 209],
    ["Dark violet", 148, 0, 211],
    ["Deep pink", 255, 20, 147],
    ["Deep sky blue", 0, 191, 255],
    ["Dim gray", 105, 105, 105],
    ["Dodger blue", 30, 144, 255],
    ["Firebrick", 178, 34, 34],
    ["Floral white", 255, 250, 240],
    ["Forest green", 34, 139, 34],
    ["Fuchsia", 255, 0, 255],
    ["Gainsboro", 220, 220, 220],
    ["Ghost white", 248, 248, 255],
    ["Gold", 255, 215, 0],
    ["Goldenrod", 218, 165, 32],
    ["Gray", 128, 128, 128],
    ["Green", 0, 128, 0],
    ["Green yellow", 173, 255, 47],
    ["Honeydew", 240, 255, 240],
    ["Hot pink", 255, 105, 180],
    ["Indian red", 205, 92, 92],
    ["Indigo", 75, 0, 130],
    ["Ivory", 255, 255, 240],
    ["Khaki", 240, 230, 140],
    ["Lavender", 230, 230, 250],
    ["Lavender blush", 255, 240, 245],
    ["Lawn green", 124, 252, 0],
    ["Lemon chiffon", 255, 250, 205],
    ["Light blue", 173, 216, 230],
    ["Light coral", 240, 128, 128],
    ["Light cyan", 224, 255, 255],
    ["Light goldenrod yellow", 250, 250, 210],
    ["Light gray", 211, 211, 211],
    ["Light green", 144, 238, 144],
    ["Light pink", 255, 182, 193],
    ["Light salmon", 255, 160, 122],
    ["Light sea green", 32, 178, 170],
    ["Light sky blue", 135, 206, 250],
    ["Light slate gray", 119, 136, 153],
    ["Light steel blue", 176, 196, 222],
    ["Light yellow", 255, 255, 224],
    ["Lime", 0, 255, 0],
    ["Lime green", 50, 205, 50],
    ["Linen", 250, 240, 230],
    ["Magenta", 255, 0, 255],
    ["Maroon", 128, 0, 0],
    ["Medium aquamarine", 102, 205, 170],
    ["Medium blue", 0, 0, 205],
    ["Medium orchid", 186, 85, 211],
    ["Medium purple", 147, 112, 219],
    ["Medium sea green", 60, 179, 113],
    ["Medium slate blue", 123, 104, 238],
    ["Medium spring green", 0, 250, 154],
    ["Medium turquoise", 72, 209, 204],
    ["Medium violet red", 199, 21, 133],
    ["Midnight blue", 25, 25, 112],
    ["Mint cream", 245, 255, 250],
    ["Misty rose", 255, 228, 225],
    ["Moccasin", 255, 228, 181],
    ["Navajo white", 255, 222, 173],
    ["Navy", 0, 0, 128],
    ["Old lace", 253, 245, 230],
    ["Olive", 128, 128, 0],
    ["Olive drab", 107, 142, 35],
    ["Orange", 255, 165, 0],
    ["Orange red", 255, 69, 0],
    ["Orchid", 218, 112, 214],
    ["Pale goldenrod", 238, 232, 170],
    ["Pale green", 152, 251, 152],
    ["Pale turquoise", 175, 238, 238],
    ["Pale violet red", 219, 112, 147],
    ["Papaya whip", 255, 239, 213],
    ["Peach puff", 255, 218, 185],
    ["Peru", 205, 133, 63],
    ["Pink", 255, 192, 203],
    ["Plum", 221, 160, 221],
    ["Powder blue", 176, 224, 230],
    ["Purple", 128, 0, 128],
    ["Rebecca purple", 102, 51, 153],
    ["Red", 255, 0, 0],
    ["Rosy brown", 188, 143, 143],
    ["Royal blue", 65, 105, 225],
    ["Saddle brown", 139, 69, 19],
    ["Salmon", 250, 128, 114],
    ["Sandy brown", 244, 164, 96],
    ["Sea green", 46, 139, 87],
    ["Sea shell", 255, 245, 238],
    ["Sienna", 160, 82, 45],
    ["Silver", 192, 192, 192],
    ["Sky blue", 135, 206, 235],
    ["Slate blue", 106, 90, 205],
    ["Slate gray", 112, 128, 144],
    ["Snow", 255, 250, 250],
    ["Spring green", 0, 255, 127],
    ["Steel blue", 70, 130, 180],
    ["Tan", 210, 180, 140],
    ["Teal", 0, 128, 128],
    ["Thistle", 216, 191, 216],
    ["Tomato", 255, 99, 71],
    ["Turquoise", 64, 224, 208],
    ["Violet", 238, 130, 238],
    ["Wheat", 245, 222, 179],
    ["White", 255, 255, 255],
    ["White smoke", 245, 245, 245],
    ["Yellow", 255, 255, 0],
    ["Yellow green", 154, 205, 50]
];

function extractHex(raw) {
    if (!raw) return null;
    const match = raw.match(/#?([0-9a-fA-F]{6})/);
    return match ? ("#" + match[1].toUpperCase()) : null;
}

function hexToRgb(hex) {
    const clean = hex.replace(/^#/, "");
    if (clean.length !== 6) return null;
    const r = parseInt(clean.substring(0, 2), 16);
    const g = parseInt(clean.substring(2, 4), 16);
    const b = parseInt(clean.substring(4, 6), 16);
    if (isNaN(r) || isNaN(g) || isNaN(b)) return null;
    return { r, g, b };
}

function rgbToHex(r, g, b) {
    const clamp = v => Math.max(0, Math.min(255, Math.round(v)));
    const toHex = v => clamp(v).toString(16).padStart(2, "0").toUpperCase();
    return "#" + toHex(r) + toHex(g) + toHex(b);
}

function rgbToHsl(r, g, b) {
    const rf = r / 255;
    const gf = g / 255;
    const bf = b / 255;
    const max = Math.max(rf, gf, bf);
    const min = Math.min(rf, gf, bf);
    const delta = max - min;
    const l = (max + min) / 2;

    if (delta === 0) {
        return { h: 0, s: 0, l: Math.round(l * 100) };
    }

    const s = l < 0.5 ? delta / (max + min) : delta / (2 - max - min);
    let h;
    if (max === rf) {
        h = (gf - bf) / delta + (gf < bf ? 6 : 0);
    } else if (max === gf) {
        h = (bf - rf) / delta + 2;
    } else {
        h = (rf - gf) / delta + 4;
    }
    h = Math.round(h * 60) % 360;
    return {
        h,
        s: Math.round(s * 100),
        l: Math.round(l * 100)
    };
}

function hslToRgb(h, s, l) {
    const sNorm = s / 100;
    const lNorm = l / 100;
    const c = (1 - Math.abs(2 * lNorm - 1)) * sNorm;
    const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
    const m = lNorm - c / 2;

    let rf = 0, gf = 0, bf = 0;
    if (h >= 0 && h < 60) {
        rf = c; gf = x; bf = 0;
    } else if (h >= 60 && h < 120) {
        rf = x; gf = c; bf = 0;
    } else if (h >= 120 && h < 180) {
        rf = 0; gf = c; bf = x;
    } else if (h >= 180 && h < 240) {
        rf = 0; gf = x; bf = c;
    } else if (h >= 240 && h < 300) {
        rf = x; gf = 0; bf = c;
    } else if (h >= 300 && h < 360) {
        rf = c; gf = 0; bf = x;
    }

    return {
        r: Math.round((rf + m) * 255),
        g: Math.round((gf + m) * 255),
        b: Math.round((bf + m) * 255)
    };
}

function rgbToHsv(r, g, b) {
    const rf = r / 255;
    const gf = g / 255;
    const bf = b / 255;
    const max = Math.max(rf, gf, bf);
    const min = Math.min(rf, gf, bf);
    const delta = max - min;

    let h = 0;
    if (delta !== 0) {
        if (max === rf) {
            h = (gf - bf) / delta + (gf < bf ? 6 : 0);
        } else if (max === gf) {
            h = (bf - rf) / delta + 2;
        } else {
            h = (rf - gf) / delta + 4;
        }
        h = Math.round(h * 60) % 360;
    }

    const s = max === 0 ? 0 : Math.round((delta / max) * 100);
    const v = Math.round(max * 100);

    return { h, s, v };
}

function hsvToRgb(h, s, v) {
    const sNorm = s / 100;
    const vNorm = v / 100;
    const c = vNorm * sNorm;
    const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
    const m = vNorm - c;

    let rf = 0, gf = 0, bf = 0;
    if (h >= 0 && h < 60) {
        rf = c; gf = x; bf = 0;
    } else if (h >= 60 && h < 120) {
        rf = x; gf = c; bf = 0;
    } else if (h >= 120 && h < 180) {
        rf = 0; gf = c; bf = x;
    } else if (h >= 180 && h < 240) {
        rf = 0; gf = x; bf = c;
    } else if (h >= 240 && h < 300) {
        rf = x; gf = 0; bf = c;
    } else if (h >= 300 && h < 360) {
        rf = c; gf = 0; bf = x;
    }

    return {
        r: Math.round((rf + m) * 255),
        g: Math.round((gf + m) * 255),
        b: Math.round((bf + m) * 255)
    };
}

function rgbToCmyk(r, g, b) {
    if (r === 0 && g === 0 && b === 0) {
        return { c: 0, m: 0, y: 0, k: 100 };
    }
    const rf = r / 255;
    const gf = g / 255;
    const bf = b / 255;
    const k = 1 - Math.max(rf, gf, bf);
    const c = (1 - rf - k) / (1 - k);
    const m = (1 - gf - k) / (1 - k);
    const y = (1 - bf - k) / (1 - k);
    return {
        c: Math.round(c * 100),
        m: Math.round(m * 100),
        y: Math.round(y * 100),
        k: Math.round(k * 100)
    };
}

function generateShades(r, g, b) {
    const hsl = rgbToHsl(r, g, b);
    const clamp = (val, min, max) => Math.max(min, Math.min(max, val));

    // PowerToys steps formula: +24, +12, base, -12, -24
    const steps = [
        clamp(hsl.l + 24, 10, 95),
        clamp(hsl.l + 12, 8, 92),
        hsl.l,
        clamp(hsl.l - 12, 5, 90),
        clamp(hsl.l - 24, 5, 85)
    ];

    return steps.map(stepL => {
        const rgb = hslToRgb(hsl.h, hsl.s, stepL);
        return {
            r: rgb.r,
            g: rgb.g,
            b: rgb.b,
            hex: rgbToHex(rgb.r, rgb.g, rgb.b)
        };
    });
}

function getColorName(r, g, b) {
    let bestName = "Custom";
    let minDist = Infinity;

    for (let i = 0; i < PALETTE.length; i++) {
        const item = PALETTE[i];
        const dr = r - item[1];
        const dg = g - item[2];
        const db = b - item[3];
        const dist = dr * dr + dg * dg + db * db;
        if (dist < minDist) {
            minDist = dist;
            bestName = item[0];
        }
    }
    return bestName;
}

function formatColor(hexInput) {
    const hex = extractHex(hexInput);
    if (!hex) return null;
    const rgb = hexToRgb(hex);
    if (!rgb) return null;

    const hsl = rgbToHsl(rgb.r, rgb.g, rgb.b);
    const hsv = rgbToHsv(rgb.r, rgb.g, rgb.b);
    const cmyk = rgbToCmyk(rgb.r, rgb.g, rgb.b);
    const colorName = getColorName(rgb.r, rgb.g, rgb.b);
    const shades = generateShades(rgb.r, rgb.g, rgb.b);

    return {
        hex: hex,
        hexClean: hex.replace(/^#/, "").toLowerCase(),
        colorName: colorName,
        rgb: `rgb(${rgb.r}, ${rgb.g}, ${rgb.b})`,
        hsl: `hsl(${hsl.h}, ${hsl.s}%, ${hsl.l}%)`,
        hsv: `hsv(${hsv.h}, ${hsv.s}%, ${hsv.v}%)`,
        cmyk: `cmyk(${cmyk.c}%, ${cmyk.m}%, ${cmyk.y}%, ${cmyk.k}%)`,
        r: rgb.r,
        g: rgb.g,
        b: rgb.b,
        hDeg: hsv.h,
        sPct: hsv.s,
        vPct: hsv.v,
        shades: shades
    };
}

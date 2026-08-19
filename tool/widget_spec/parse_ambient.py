"""Turn the design's inline CSS ambient layers into a typed model.

Lengths written as `<n>s` are fractions of the tile's reference size; `%`
values resolve against the box itself. Both survive into the model so the
platform renderers can reproduce either.
"""
import json, re

def props(style):
    out = {}
    depth = 0; cur = ''; parts = []
    for ch in style:
        if ch == '(': depth += 1
        if ch == ')': depth -= 1
        if ch == ';' and depth == 0:
            parts.append(cur); cur = ''
        else:
            cur += ch
    if cur.strip(): parts.append(cur)
    for p in parts:
        if ':' in p:
            k, v = p.split(':', 1)
            out[k.strip()] = v.strip()
    return out

def length(v):
    if v is None: return None
    v = v.strip()
    if v.endswith('s'): return {'frac': float(v[:-1])}
    if v.endswith('%'): return {'pct': float(v[:-1]) / 100}
    if v.endswith('px'): return {'px': float(v[:-2])}
    if v == '0': return {'px': 0.0}
    return {'raw': v}

def rgba(v):
    v = v.strip()
    if v == '#fff': return [255, 255, 255, 1.0]
    m = re.match(r'#([0-9a-fA-F]{6})$', v)
    if m:
        h = m.group(1); return [int(h[0:2],16), int(h[2:4],16), int(h[4:6],16), 1.0]
    m = re.match(r'rgba?\(([\d.]+),\s*([\d.]+),\s*([\d.]+)(?:,\s*([\d.]*))?\)', v)
    if m:
        a = m.group(4)
        return [int(float(m.group(1))), int(float(m.group(2))), int(float(m.group(3))),
                float(a) if a not in (None, '') else 1.0]
    raise ValueError(v)

def anim(p):
    a = p.get('animation')
    if not a: return None
    parts = a.split()
    name = parts[0]
    dur = float(parts[1].rstrip('s'))
    delay = 0.0
    for tok in parts[2:]:
        if re.fullmatch(r'-?[\d.]+s', tok): delay = float(tok.rstrip('s'))
    return {'name': name, 'duration': dur, 'delay': delay}

def classify(style):
    p = props(style)
    bg = p.get('background', '')
    layer = {'anim': anim(p)}

    # Full-bleed layers.
    if p.get('inset') == '0':
        if bg.startswith('radial-gradient'):
            stops = re.findall(
                r'radial-gradient\(ellipse ([\d.]+)s ([\d.]+)s at ([\d.]+)% ([\d.]+)%,\s*(rgba?\([^)]*\)),\s*transparent\)',
                bg)
            layer.update(kind='mist', blobs=[
                {'w': float(a), 'h': float(b), 'x': float(c)/100, 'y': float(d)/100, 'color': rgba(e)}
                for a, b, c, d, e in stops])
            return layer
        layer.update(kind='veil', color=rgba(bg))
        return layer

    # The dusk wash across the bottom 52%.
    if p.get('bottom') == '0' and p.get('height', '').endswith('%'):
        m = re.match(r'linear-gradient\(transparent,\s*(rgba?\([^)]*\))\)', bg)
        layer.update(kind='duskVeil', height=float(p['height'].rstrip('%'))/100,
                     color=rgba(m.group(1)))
        return layer

    box = {k: length(p[k]) for k in ('top','left','right','bottom','width','height') if k in p}
    if 'margin-left' in p: box['marginLeft'] = length(p['margin-left'])
    if 'margin' in p:
        parts = p['margin'].split()
        box['marginTop'] = length(parts[0]); box['marginLeft'] = length(parts[3])
    layer['box'] = box
    layer['round'] = p.get('border-radius') == '50%'

    if bg.startswith('radial-gradient'):
        m = re.match(r'radial-gradient\(circle(?: at ([\d.]+)% ([\d.]+)%)?,\s*(.+)\)$', bg)
        at = ([float(m.group(1))/100, float(m.group(2))/100] if m.group(1) else [0.5, 0.5])
        stops = []
        for part in re.findall(r'((?:rgba?\([^)]*\)|#[0-9a-fA-F]{3,6}))(?:\s+([\d.]+)%)?', m.group(3)):
            stops.append({'color': rgba(part[0]),
                          'at': float(part[1])/100 if part[1] else None})
        if 'transparent' in m.group(3):
            stop_at = re.search(r'transparent\s+([\d.]+)%', m.group(3))
            stops.append({'color': [0,0,0,0.0],
                          'at': float(stop_at.group(1))/100 if stop_at else 1.0})
        layer.update(kind='radial', center=at, stops=stops)
    elif p.get('border'):
        m = re.match(r'([\d.]+)px solid (.+)$', p['border'])
        layer.update(kind='ring', strokeWidth=float(m.group(1)), color=rgba(m.group(2)))
    else:
        layer.update(kind='fill', color=rgba(bg))

    if 'box-shadow' in p:
        s = p['box-shadow'].split()
        layer['glow'] = {'blur': length(s[2]),
                         'spread': length(s[3]) if len(s) > 4 else {'px': 0.0},
                         'color': rgba(s[-1] if s[-1].startswith('rgb') else p['box-shadow'][p['box-shadow'].index('rgba'):])}
    return layer

src = json.load(open('ambient.json'))
model = {k: [classify(s) for s in v] for k, v in src.items()}
json.dump(model, open('ambient_model.json', 'w'), indent=1)
import collections
print(collections.Counter(l['kind'] for v in model.values() for l in v))

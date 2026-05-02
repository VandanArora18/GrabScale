from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import JSONResponse
import cv2
import numpy as np
import io
import base64
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4

app = FastAPI(title="ScaleGrab API")

BILATERAL_D = 9
BILATERAL_SIGMA_C = 75
BILATERAL_SIGMA_S = 75
CLAHE_CLIP = 3.0
CLAHE_GRID = (8, 8)
GRABCUT_ITER = 7
MORPH_CLOSE_SIZE = 35
MORPH_OPEN_SIZE = 5
MIN_AREA = 2000
REF_REAL_W_MM = 85.6
REF_REAL_H_MM = 54.0
REF_REAL_ASPECT = REF_REAL_W_MM / REF_REAL_H_MM
REF_ASPECT_TOLERANCE = 0.15
CARD_ASPECT_MIN = 1.2
CARD_ASPECT_MAX = 2.1
CARD_AREA_MIN_FRAC = 0.005
CARD_AREA_MAX_FRAC = 0.30
CARD_RECT_MIN = 0.65
MAX_DISPLAY_W = 1100
MAX_DISPLAY_H = 800


def preprocess(image, tag=""):
    bilateral = cv2.bilateralFilter(image, BILATERAL_D, BILATERAL_SIGMA_C, BILATERAL_SIGMA_S)
    lab = cv2.cvtColor(bilateral, cv2.COLOR_BGR2LAB)
    L, a, b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=CLAHE_CLIP, tileGridSize=CLAHE_GRID)
    L_eq = clahe.apply(L)
    enhanced = cv2.cvtColor(cv2.merge([L_eq, a, b]), cv2.COLOR_LAB2BGR)
    gray = cv2.cvtColor(enhanced, cv2.COLOR_BGR2GRAY)
    return enhanced, gray


def run_grabcut(image, rect_coords):
    x1, y1, x2, y2 = rect_coords
    w = x2 - x1
    h = y2 - y1
    if w < 10 or h < 10:
        return None
    bgd = np.zeros((1, 65), np.float64)
    fgd = np.zeros((1, 65), np.float64)
    msk = np.zeros(image.shape[:2], np.uint8)
    cv2.grabCut(image, msk, (x1, y1, w, h), bgd, fgd, GRABCUT_ITER, cv2.GC_INIT_WITH_RECT)
    fg = np.where((msk == 1) | (msk == 3), 255, 0).astype(np.uint8)
    return fg


def apply_morphology(mask, label="", use_convex_fill=False):
    w0 = cv2.countNonZero(mask)
    k_o = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (MORPH_OPEN_SIZE, MORPH_OPEN_SIZE))
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, k_o)
    k_c = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (MORPH_CLOSE_SIZE, MORPH_CLOSE_SIZE))
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, k_c)
    mask = cv2.GaussianBlur(mask, (5, 5), 0)
    _, mask = cv2.threshold(mask, 127, 255, cv2.THRESH_BINARY)

    if use_convex_fill:
        cnts_cvx, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        if cnts_cvx:
            biggest = max(cnts_cvx, key=cv2.contourArea)
            hull = cv2.convexHull(biggest)
            hull_mask = np.zeros_like(mask)
            cv2.drawContours(hull_mask, [hull], -1, 255, thickness=cv2.FILLED)
            mask = cv2.bitwise_or(mask, hull_mask)

    cnts_tmp, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    w3 = cv2.countNonZero(mask)
    if cnts_tmp:
        biggest = max(cnts_tmp, key=cv2.contourArea)
        M = cv2.moments(biggest)
        if M["m00"] != 0:
            cx = int(M["m10"] / M["m00"])
            cy = int(M["m01"] / M["m00"])
            h_f, w_f = mask.shape
            flood_pad = np.zeros((h_f + 2, w_f + 2), np.uint8)
            if mask[cy, cx] == 255:
                inv = cv2.bitwise_not(mask)
                cv2.floodFill(inv, flood_pad, (cx, cy), 0)
                mask = cv2.bitwise_not(inv)
            else:
                wpts = np.argwhere(mask == 255)
                if len(wpts) > 0:
                    dists = np.abs(wpts[:, 0] - cy) + np.abs(wpts[:, 1] - cx)
                    nearest = wpts[np.argmin(dists)]
                    inv = cv2.bitwise_not(mask)
                    cv2.floodFill(inv, flood_pad, (int(nearest[1]), int(nearest[0])), 0)
                    mask = cv2.bitwise_not(inv)
    return mask


def get_object_info(mask, label=""):
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    valid = [c for c in contours if cv2.contourArea(c) >= MIN_AREA]
    if not valid:
        return None
    main_cnt = max(valid, key=cv2.contourArea)
    contour_area_px = cv2.contourArea(main_cnt)
    hull = cv2.convexHull(main_cnt)
    upright = cv2.boundingRect(hull)
    rotated = cv2.minAreaRect(hull)
    x, y, w, h = upright
    rw_raw = rotated[1][0]
    rh_raw = rotated[1][1]
    angle = rotated[2]
    rw_norm = max(rw_raw, rh_raw)
    rh_norm = min(rw_raw, rh_raw)
    aspect = round(rw_norm / rh_norm, 4) if rh_norm > 0 else 0
    is_portrait = (h > w)
    return {
        "hull": hull, "upright": upright,
        "rotated": rotated, "rw_norm": rw_norm,
        "rh_norm": rh_norm, "aspect": aspect,
        "is_portrait": is_portrait,
        "contour_area_px": contour_area_px,
    }


def compute_calibration(ref_info, ref_rect, tag=""):
    rw_px = ref_info["rw_norm"]
    rh_px = ref_info["rh_norm"]
    detected_aspect = ref_info["aspect"]
    aspect_error = abs(detected_aspect - REF_REAL_ASPECT) / REF_REAL_ASPECT
    use_fallback = aspect_error > REF_ASPECT_TOLERANCE

    if use_fallback:
        x1, y1, x2, y2 = ref_rect
        rect_w = x2 - x1
        rect_h = y2 - y1
        rw_px = max(rect_w, rect_h)
        rh_px = min(rect_w, rect_h)

    scale_W = rw_px / REF_REAL_W_MM
    scale_H = rh_px / REF_REAL_H_MM
    diff_pct = abs(scale_W - scale_H) / max(scale_W, scale_H) * 100
    pcf = REF_REAL_ASPECT / detected_aspect

    if diff_pct < 15:
        ppm = (scale_W + scale_H) / 2.0
    else:
        ppm = scale_W
    return ppm, scale_W, scale_H, pcf, diff_pct


def compute_frontal_dimensions(tgt_info, ppm, scale_W, scale_H, pcf, diff_pct):
    tw_px = tgt_info["rw_norm"]
    th_px = tgt_info["rh_norm"]
    dim_long  = round(tw_px / scale_W, 1)
    dim_short = round(th_px / scale_H, 1)

    if tgt_info["is_portrait"]:
        height_mm, length_mm = dim_long, dim_short
    else:
        length_mm, height_mm = dim_long, dim_short

    bbox_area_mm2 = round(length_mm * height_mm, 1)
    contour_area_px = tgt_info["contour_area_px"]
    contour_area_mm2 = round(contour_area_px / (ppm ** 2), 1)
    fill_pct = round((contour_area_mm2 / bbox_area_mm2) * 100, 1) if bbox_area_mm2 > 0 else 0
    fill_pct = min(fill_pct, 100.0)  
    return length_mm, height_mm, bbox_area_mm2, contour_area_mm2, fill_pct


def compute_side_dimensions(tgt_info, ppm, scale_W, scale_H, pcf, diff_pct):
    tw_px = tgt_info["rw_norm"]
    th_px = tgt_info["rh_norm"]
    dim_long  = round(tw_px / scale_W, 1)
    dim_short = round(th_px / scale_H, 1)

    if tgt_info["is_portrait"]:
        width_mm, height_check_mm = dim_short, dim_long
    else:
        width_mm, height_check_mm = dim_long, dim_short

    contour_area_mm2 = round(tgt_info["contour_area_px"] / (ppm ** 2), 1)
    return width_mm, height_check_mm, contour_area_mm2


def compute_surface_areas(length_mm, height_mm, width_mm, contour_area_f, contour_area_s, shape="box"):
    import math
    
    front = round(length_mm * height_mm, 1)
    side = round(height_mm * width_mm, 1)
    top = round(length_mm * width_mm, 1)
    
    if shape == "sphere":
        radius = length_mm / 2.0
        total_mm2  = 4.0 * math.pi * (radius ** 2)
    elif shape == "cylinder":
        radius = length_mm / 2.0
        total_mm2  = (2.0 * math.pi * radius * height_mm) + (2.0 * math.pi * (radius ** 2))
    else:
        total_mm2 = 2 * front + 2 * side + 2 * top
        
    total_mm2 = round(total_mm2, 1)
    total_cm2 = round(total_mm2 / 100.0, 1)
    
    return {"front_bbox": front, "front_contour": contour_area_f,
            "side": side, "top": top,
            "total_mm2": total_mm2, "total_cm2": total_cm2}


def compute_volume_by_shape(length_mm, height_mm, width_mm, shape):
    import math
    
    if shape == "sphere":
        radius = length_mm / 2.0
        volume_mm3 = (4.0/3.0) * math.pi * (radius ** 3)
        
    elif shape == "cylinder":
        radius = length_mm / 2.0
        volume_mm3 = math.pi * (radius ** 2) * height_mm
        
    else:  
        volume_mm3 = length_mm * height_mm * width_mm
    
    return round(volume_mm3 / 1000.0, 2)  # mm³ → cm³


def draw_arrow_dimension(img, pt1, pt2, label, color):
    cv2.arrowedLine(img, pt1, pt2, color, 2, tipLength=0.04)
    cv2.arrowedLine(img, pt2, pt1, color, 2, tipLength=0.04)
    mx = (pt1[0] + pt2[0]) // 2
    my = (pt1[1] + pt2[1]) // 2
    (tw, th), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 2)
    cv2.rectangle(img, (mx - 4, my - th - 4), (mx + tw + 4, my + 4), (0, 0, 0), -1)
    cv2.putText(img, label, (mx, my), cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)


def draw_detection(image, ref_info, tgt_info, ppm, pcf,
                   dim1_mm, dim2_mm, dim1_label, dim2_label,
                   contour_area_mm2, fill_pct, phase_tag, auto_detected=False):
    display = image.copy()
    ih, iw = display.shape[:2]

    if ref_info:
        x, y, w, h = ref_info["upright"]
        rot_pts = np.intp(cv2.boxPoints(ref_info["rotated"]))
        cv2.drawContours(display, [ref_info["hull"]], -1, (0, 255, 255), 2)
        cv2.rectangle(display, (x, y), (x + w, y + h), (0, 200, 255), 2)
        cv2.drawContours(display, [rot_pts], -1, (0, 140, 255), 2)
        ly = max(y - 55, 60)
        mode = "[AUTO]" if auto_detected else "[MANUAL]"
        cv2.putText(display, f"REF [{phase_tag}] {mode}",
                    (x, ly), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 200, 255), 2)

    if tgt_info:
        x, y, w, h = tgt_info["upright"]
        rot_pts = np.intp(cv2.boxPoints(tgt_info["rotated"]))
        is_portrait = tgt_info["is_portrait"]
        cv2.drawContours(display, [tgt_info["hull"]], -1, (0, 255, 0), 2)
        cv2.rectangle(display, (x, y), (x + w, y + h), (255, 0, 0), 2)
        cv2.drawContours(display, [rot_pts], -1, (0, 0, 255), 2)
        ly = max(y - 110, 120)
        cv2.putText(display, f"TARGET [{phase_tag}]",
                    (x, ly), cv2.FONT_HERSHEY_SIMPLEX, 0.65, (0, 255, 0), 2)
        cv2.putText(display, f"{dim1_label} : {dim1_mm} mm",
                    (x, ly + 46), cv2.FONT_HERSHEY_SIMPLEX, 0.57, (80, 255, 80), 2)
        cv2.putText(display, f"{dim2_label} : {dim2_mm} mm",
                    (x, ly + 68), cv2.FONT_HERSHEY_SIMPLEX, 0.57, (80, 200, 255), 2)

        GAP = 28
        if is_portrait:
            ax = x + w + GAP
            if ax + 10 < iw:
                draw_arrow_dimension(display, (ax, y), (ax, y + h), f"{dim1_mm}mm", (80, 255, 80))
            ay = y + h + GAP
            if ay + 10 < ih:
                draw_arrow_dimension(display, (x, ay), (x + w, ay), f"{dim2_mm}mm", (80, 200, 255))
        else:
            ay = y + h + GAP
            if ay + 10 < ih:
                draw_arrow_dimension(display, (x, ay), (x + w, ay), f"{dim1_mm}mm", (80, 255, 80))
            ax = x + w + GAP
            if ax + 10 < iw:
                draw_arrow_dimension(display, (ax, y), (ax, y + h), f"{dim2_mm}mm", (80, 200, 255))
    return display


def _remove_overlapping(candidates, iou_thresh=0.5):
    if len(candidates) <= 1:
        return candidates
    kept = []
    used = [False] * len(candidates)
    sorted_c = sorted(candidates, key=lambda c: c["score"], reverse=True)
    for i, ci in enumerate(sorted_c):
        if used[i]:
            continue
        kept.append(ci)
        x1i, y1i, x2i, y2i = ci["bbox"]
        for j, cj in enumerate(sorted_c):
            if i == j or used[j]:
                continue
            x1j, y1j, x2j, y2j = cj["bbox"]
            ix1 = max(x1i, x1j)
            iy1 = max(y1i, y1j)
            ix2 = min(x2i, x2j)
            iy2 = min(y2i, y2j)
            inter = max(0, ix2 - ix1) * max(0, iy2 - iy1)
            area_i = (x2i - x1i) * (y2i - y1i)
            area_j = (x2j - x1j) * (y2j - y1j)
            union = area_i + area_j - inter
            iou = inter / union if union > 0 else 0
            if iou > iou_thresh:
                used[j] = True
    return kept


def auto_detect_card(image, enhanced, gray, tag=""):
    img_h, img_w = gray.shape
    img_area = img_h * img_w
    combined_edges = np.zeros_like(gray)
    e1 = cv2.Canny(gray, 20, 60)
    combined_edges = cv2.bitwise_or(combined_edges, e1)
    e2 = cv2.Canny(gray, 50, 150)
    combined_edges = cv2.bitwise_or(combined_edges, e2)
    _, otsu = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    e3 = cv2.Canny(otsu, 10, 50)
    combined_edges = cv2.bitwise_or(combined_edges, e3)
    gray_norm = cv2.normalize(gray, None, 0, 255, cv2.NORM_MINMAX)
    e4 = cv2.Canny(gray_norm, 30, 90)
    combined_edges = cv2.bitwise_or(combined_edges, e4)
    k = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
    combined_edges = cv2.morphologyEx(combined_edges, cv2.MORPH_CLOSE, k)
    contours, _ = cv2.findContours(combined_edges, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    candidates = []
    for cnt in contours:
        area = cv2.contourArea(cnt)
        if area < 100:
            continue
        area_frac = area / img_area
        if area_frac < CARD_AREA_MIN_FRAC or area_frac > CARD_AREA_MAX_FRAC:
            continue
        x, y, w, h = cv2.boundingRect(cnt)
        if w < 20 or h < 20:
            continue
        longer = max(w, h)
        shorter = min(w, h)
        aspect = longer / shorter if shorter > 0 else 0
        if aspect < CARD_ASPECT_MIN or aspect > CARD_ASPECT_MAX:
            continue
        rect_score = area / (w * h) if (w * h) > 0 else 0
        if rect_score < CARD_RECT_MIN:
            continue
        perimeter = cv2.arcLength(cnt, True)
        approx = cv2.approxPolyDP(cnt, 0.04 * perimeter, True)
        n_verts = len(approx)
        aspect_diff = abs(aspect - REF_REAL_ASPECT)
        aspect_score = 1.0 / (1.0 + aspect_diff)
        vert_bonus = 1.2 if n_verts == 4 else (1.0 if n_verts in [3, 5] else 0.7)
        score = aspect_score * rect_score * vert_bonus
        candidates.append({
            "bbox": (x, y, x + w, y + h),
            "area_frac": area_frac,
            "aspect": round(aspect, 3),
            "rect_score": round(rect_score, 3),
            "n_verts": n_verts,
            "score": round(score, 4),
            "cnt": cnt,
        })
    candidates = _remove_overlapping(candidates)
    candidates.sort(key=lambda c: c["score"], reverse=True)
    return candidates, combined_edges


def generate_pdf(length_mm, height_mm, width_mm, volume_cm3, areas, fill_pct, detected_shape, f_img, s_img):
    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=A4)
    w, h = A4
    c.setFont("Helvetica-Bold", 20)
    c.drawString(50, h - 60, "ScaleGrab Measurement Report")
    c.setFont("Helvetica", 12)
    lines = [
        f"Detected Shape : {detected_shape.capitalize()}",
        f"Length  : {length_mm} mm  ({length_mm / 10:.2f} cm)",
        f"Height  : {height_mm} mm  ({height_mm / 10:.2f} cm)",
        f"Width   : {width_mm} mm  ({width_mm / 10:.2f} cm)",
        f"Volume  : {volume_cm3} cm\u00b3",
        f"Surface : {areas['total_cm2']} cm\u00b2  (all 6 faces)",
        f"Front face area  : {areas['front_bbox']} mm\u00b2",
        f"Side face area   : {areas['side']} mm\u00b2",
        f"Top face area    : {areas['top']} mm\u00b2",
        f"Fill ratio       : {fill_pct}%",
    ]
    for i, line in enumerate(lines):
        c.drawString(50, h - 110 - i * 30, line)
        
    try:
        from PIL import Image
        from reportlab.lib.utils import ImageReader
        
        f_rgb = cv2.cvtColor(f_img, cv2.COLOR_BGR2RGB)
        s_rgb = cv2.cvtColor(s_img, cv2.COLOR_BGR2RGB)
        
        pil_f = Image.fromarray(f_rgb)
        pil_s = Image.fromarray(s_rgb)
        
        max_img_w = 200
        max_img_h = 250
        
        c.drawString(50, h - 420, "Frontal View:")
        c.drawImage(ImageReader(pil_f), 50, h - 680, width=max_img_w, height=max_img_h, preserveAspectRatio=True)
        
        c.drawString(300, h - 420, "Side View:")
        c.drawImage(ImageReader(pil_s), 300, h - 680, width=max_img_w, height=max_img_h, preserveAspectRatio=True)
    except Exception as e:
        pass

    c.save()
    buf.seek(0)
    return base64.b64encode(buf.read()).decode()


# ── API ENDPOINTS ──

@app.get("/")
def health():
    return {"status": "ScaleGrab API running", "version": "10.0"}


@app.post("/measure")
async def measure(
    frontal_image: UploadFile = File(...),
    side_image: UploadFile = File(...),
    frontal_ref_bbox: str = Form(...),
    frontal_tgt_bbox: str = Form(...),
    side_ref_bbox: str = Form(...),
    side_tgt_bbox: str = Form(...),
    shape: str = Form(...),
):
    def parse_bbox(s):
        return tuple(map(int, s.strip().split(",")))

    try:
        f_bytes = await frontal_image.read()
        s_bytes = await side_image.read()
        f_np = cv2.imdecode(np.frombuffer(f_bytes, np.uint8), cv2.IMREAD_COLOR)
        s_np = cv2.imdecode(np.frombuffer(s_bytes, np.uint8), cv2.IMREAD_COLOR)

        def resize_img(img):
            h, w = img.shape[:2]
            scale = min(MAX_DISPLAY_W / w, MAX_DISPLAY_H / h, 1.0)
            if scale < 1.0:
                img = cv2.resize(img, (int(w * scale), int(h * scale)), interpolation=cv2.INTER_AREA)
            return img, scale

        f_np, f_scale = resize_img(f_np)
        s_np, s_scale = resize_img(s_np)

        def scale_bbox(bbox, scale, img_w, img_h):
            x1, y1, x2, y2 = [int(round(v * scale)) for v in bbox]
            x1 = max(0, min(x1, img_w - 1))
            y1 = max(0, min(y1, img_h - 1))
            x2 = max(0, min(x2, img_w - 1))
            y2 = max(0, min(y2, img_h - 1))
            if x2 - x1 < 10:
                x2 = min(x1 + 10, img_w - 1)
            if y2 - y1 < 10:
                y2 = min(y1 + 10, img_h - 1)
            return (x1, y1, x2, y2)

        img_h_f, img_w_f = f_np.shape[:2]
        img_h_s, img_w_s = s_np.shape[:2]

        f_ref = scale_bbox(parse_bbox(frontal_ref_bbox), f_scale, img_w_f, img_h_f)
        f_tgt = scale_bbox(parse_bbox(frontal_tgt_bbox), f_scale, img_w_f, img_h_f)
        s_ref = scale_bbox(parse_bbox(side_ref_bbox),    s_scale, img_w_s, img_h_s)
        s_tgt = scale_bbox(parse_bbox(side_tgt_bbox),    s_scale, img_w_s, img_h_s)

        
        f_enhanced, f_gray = preprocess(f_np, tag="frontal")
        f_ref_raw = run_grabcut(f_enhanced, f_ref)
        if f_ref_raw is None: return JSONResponse({"error": "Frontal reference box too small"}, status_code=400)
        f_ref_mask = apply_morphology(f_ref_raw, "Ref frontal", use_convex_fill=False)
        f_ref_info = get_object_info(f_ref_mask, "Ref frontal")
        if not f_ref_info: return JSONResponse({"error": "Could not detect reference object in frontal image"}, status_code=400)
        ppm_f, scW_f, scH_f, pcf_f, diff_f = compute_calibration(f_ref_info, f_ref, "frontal")

        f_tgt_raw = run_grabcut(f_enhanced, f_tgt)
        if f_tgt_raw is None: return JSONResponse({"error": "Frontal target box too small"}, status_code=400)
        f_tgt_mask = apply_morphology(f_tgt_raw, "Tgt frontal", use_convex_fill=True)
        f_tgt_info = get_object_info(f_tgt_mask, "Tgt frontal")
        if not f_tgt_info: return JSONResponse({"error": "Could not detect target object in frontal image"}, status_code=400)
        length_mm, height_mm, bbox_area_f, contour_area_f, fill_f = \
            compute_frontal_dimensions(f_tgt_info, ppm_f, scW_f, scH_f, pcf_f, diff_f)

        
        s_enhanced, s_gray = preprocess(s_np, tag="side")
        s_ref_raw = run_grabcut(s_enhanced, s_ref)
        if s_ref_raw is None: return JSONResponse({"error": "Side reference box too small"}, status_code=400)
        s_ref_mask = apply_morphology(s_ref_raw, "Ref side", use_convex_fill=False)
        s_ref_info = get_object_info(s_ref_mask, "Ref side")
        if not s_ref_info: return JSONResponse({"error": "Could not detect reference object in side image"}, status_code=400)
        ppm_s, scW_s, scH_s, pcf_s, diff_s = compute_calibration(s_ref_info, s_ref, "side")

        s_tgt_raw = run_grabcut(s_enhanced, s_tgt)
        if s_tgt_raw is None: return JSONResponse({"error": "Side target box too small"}, status_code=400)
        s_tgt_mask = apply_morphology(s_tgt_raw, "Tgt side", use_convex_fill=True)
        s_tgt_info = get_object_info(s_tgt_mask, "Tgt side")
        if not s_tgt_info: return JSONResponse({"error": "Could not detect target object in side image"}, status_code=400)
        width_mm, height_check_mm, contour_area_s = \
            compute_side_dimensions(s_tgt_info, ppm_s, scW_s, scH_s, pcf_s, diff_s)

        
        detected_shape = shape.lower()
        if detected_shape == "cylinder":
    
            diameter = (length_mm + width_mm) / 2.0
            length_mm = diameter
            width_mm = diameter  
        elif detected_shape == "sphere":
            diameter = (length_mm + height_mm + width_mm) / 3.0
            length_mm = diameter
            height_mm = diameter
            width_mm = diameter
            
        volume_cm3     = compute_volume_by_shape(length_mm, height_mm, width_mm, detected_shape)
        areas = compute_surface_areas(length_mm, height_mm, width_mm, contour_area_f, contour_area_s, detected_shape)
        if f_tgt_info["is_portrait"]:
            d1, v1, d2, v2 = "HEIGHT", height_mm, "LENGTH", length_mm
        else:
            d1, v1, d2, v2 = "LENGTH", length_mm, "HEIGHT", height_mm

        result_img = draw_detection(
            f_enhanced, f_ref_info, f_tgt_info, ppm_f, pcf_f,
            v1, v2, d1, d2, contour_area_f, fill_f, "FRONTAL")
        _, buf = cv2.imencode(".jpg", result_img)
        result_b64 = base64.b64encode(buf).decode()

        pdf_b64 = generate_pdf(length_mm, height_mm, width_mm, volume_cm3, areas, fill_f, detected_shape, f_enhanced, s_enhanced)

        ppm_ratio = round(max(ppm_f, ppm_s) / min(ppm_f, ppm_s), 3) if min(ppm_f, ppm_s) > 0 else 0
        height_consistency_pct = round(abs(height_mm - height_check_mm) / max(height_mm, 1) * 100, 1)
        width_to_length_ratio = round(width_mm / length_mm, 3) if length_mm > 0 else 0
        
        warnings = []
        if ppm_ratio > 1.30:
            warnings.append(
                f"CALIBRATION WARNING: Card appears at different scale in frontal "
                f"vs side photo (ratio={ppm_ratio:.2f}). Place card at same distance "
                f"as object in both photos."
            )
        if height_consistency_pct > 25:
            warnings.append(
                f"SIDE ANGLE WARNING: Height measured frontally ({height_mm}mm) differs "
                f"from height measured from side ({height_check_mm}mm) by "
                f"{height_consistency_pct:.0f}%. Hold camera perpendicular to the "
                f"SIDE FACE of the object, not at an angle."
            )
        if width_to_length_ratio > 1.5:
            warnings.append(
                f"WIDTH WARNING: Width ({width_mm}mm) is much larger than length "
                f"({length_mm}mm). This usually means the camera was at an angle "
                f"to the thin face. Re-take the side photo looking directly at "
                f"the narrow face of the object."
            )

        return JSONResponse({
            "shape": detected_shape,
            "length_mm": length_mm,
            "height_mm": height_mm,
            "width_mm": width_mm,
            "volume_cm3": volume_cm3,
            "surface_cm2": areas["total_cm2"],
            "front_area_mm2": areas["front_bbox"],
            "side_area_mm2": areas["side"],
            "top_area_mm2": areas["top"],
            "fill_pct": fill_f,
            "scale_ppm_f": round(ppm_f, 4),
            "scale_ppm_s": round(ppm_s, 4),
            "pcf_f": round(pcf_f, 4),
            "pcf_s": round(pcf_s, 4),
            "height_check_mm": height_check_mm,
            "result_image_b64": result_b64,
            "pdf_b64": pdf_b64,
            "warnings": warnings,
            "debug_info": {
                "frontal_bbox_received": frontal_ref_bbox,
                "frontal_ref_bbox_scaled": list(f_ref),
                "side_ref_bbox_scaled": list(s_ref),
                "frontal_tgt_bbox_scaled": list(f_tgt),
                "side_tgt_bbox_scaled": list(s_tgt),
                "f_scale_factor": round(f_scale, 4),
                "s_scale_factor": round(s_scale, 4),
                "ppm_f": round(ppm_f, 4),
                "ppm_s": round(ppm_s, 4),
                "scale_W_f": round(scW_f, 4),
                "scale_H_f": round(scH_f, 4),
                "pcf_f": round(pcf_f, 4),
                "pcf_s": round(pcf_s, 4),
                "diff_pct_f": round(diff_f, 2),
                "diff_pct_s": round(diff_s, 2),
                "detected_shape": detected_shape,
                "f_ref_rw_px": round(f_ref_info["rw_norm"], 1),
                "f_ref_rh_px": round(f_ref_info["rh_norm"], 1),
                "f_tgt_rw_px": round(f_tgt_info["rw_norm"], 1),
                "f_tgt_rh_px": round(f_tgt_info["rh_norm"], 1),
                "ppm_ratio": ppm_ratio,
                "height_consistency_pct": height_consistency_pct,
                "width_to_length_ratio": width_to_length_ratio,
            }
        })
    except Exception as e:
        import traceback
        err_msg = traceback.format_exc()
        return JSONResponse({"error": f"Backend Error: {str(e)}", "traceback": err_msg}, status_code=500)

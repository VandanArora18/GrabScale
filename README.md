<p align="center">
  <h1 align="center">📐 Automated Dimensioning System</h1>

  <p align="center">
    <strong>Camera-Based Automated Object Dimension Measurement Using Classical Computer Vision</strong>
  </p>

  <p align="center">
    <a href="#-overview">Overview</a> •
    <a href="#-system-capabilities">Capabilities</a> •
    <a href="#-processing-architecture">Architecture</a> •
    <a href="#-technology-stack">Tech Stack</a> •
    <a href="#-working-methodology">Methodology</a> •
    <a href="#-performance-analysis">Evaluation</a> •
    <a href="#-constraints">Limitations</a> •
    <a href="#-future-directions">Future Scope</a>
  </p>
</p>

---

## 📘 Overview

**AutoDimenSys** is a computer vision driven measurement system developed to estimate real-world object dimensions using standard imaging devices such as webcams or smartphone cameras.

The system removes dependency on manual measuring tools and expensive industrial scanners by applying geometric analysis and reference-based calibration techniques. By detecting a known reference object placed near the target item, the system converts pixel distances into accurate physical measurements.

🚀 Download Mobile App (APK):
👉 https://github.com/VandanArora18/GrabScale/releases/tag/v1.0

This solution is particularly useful for logistics validation, manufacturing inspection, retail inventory verification, and digital space organization.

---

## 🎯 Motivation

Manual inspection and measurement processes often introduce inconsistencies due to fatigue and estimation errors. Small industries and MSMEs frequently rely on human inspection for parcel sizing or product validation, which reduces efficiency during repetitive operations.

Although automated dimensioning solutions exist, they typically depend on laser sensors or specialized setups that increase operational cost. This project focuses on creating an affordable alternative capable of operating using commonly available cameras.

---

## ✨ System Capabilities

| ✅ Supported Functions | 🚫 Outside Scope |
|---|---|
| Real-world dimension estimation | 3D laser scanning |
| Reference-based calibration | Specialized depth sensors |
| Rotated object measurement | Internal structure analysis |
| Surface irregularity indication | Material composition detection |
| Area and volume approximation | Precision metrology replacement |
| Visual measurement annotation | Permanent cloud storage |

### Measurement Functions

The system enables detection and analysis of:

- Object length and width estimation
- Rotated object boundary handling
- Parcel dimension verification
- Shape consistency monitoring
- Surface deformation indication
- Measurement visualization overlays

---

## 🏗 Processing Architecture


User Interface → Image / Video Capture → Reference Object Detection → Scale Calibration →Image Enhancement → Object Isolation → Dimension Extraction → Defect Analysis → Visualization & Report Output

### Operational Flow

1. **Input Acquisition** — Image captured using camera or uploaded by user  
2. **Reference Identification** — Known object detected for scale estimation  
3. **Calibration Stage** — Pixel-to-real-world conversion calculated  
4. **Image Processing** — Noise reduction and edge enhancement applied  
5. **Object Isolation** — Contours extracted from scene  
6. **Measurement Engine** — Bounding geometry computes dimensions  
7. **Inspection Module** — Detects structural irregularities  
8. **Output Rendering** — Annotated measurements generated

---

## 🛠 Technology Stack

| Component | Tools Used |
|---|---|
| Programming Language | Python |
| Computer Vision | OpenCV |
| Numerical Processing | NumPy |
| Classical ML | Scikit-learn |
| Interface | Streamlit |
| Execution | Local Processing |

---

## 🔬 Working Methodology

### Image Processing Strategy

Instead of relying on complex learning architectures, the system analyzes geometric and visual properties extracted from captured images.

| Stage | Technique Applied |
|---|---|
| Preprocessing | Grayscale conversion, smoothing |
| Edge Detection | Canny Edge Algorithm |
| Object Detection | Contour extraction |
| Calibration | Reference dimension mapping |
| Measurement | Rotated bounding rectangle |
| Defect Detection | Convex hull comparison |

### Measurement Logic

The reference object establishes spatial scale within the image. Once calibrated, object contours are analyzed to determine accurate dimensional boundaries even under rotated placement conditions.

Irregular contour deviations are further analyzed to identify possible dents or deformation.

---

## 📊 Performance Analysis

System validation involves comparison between automated measurements and manual measurements obtained using physical tools.

| Metric | Considered |
|---|---|
| Measurement Accuracy | ✅ |
| Stability Across Frames | ✅ |
| Processing Time | ✅ |
| Error Margin Analysis | ✅ |

Target performance focuses on maintaining reliable results within controlled capture environments.

---

## ⚠️ Constraints

- Sensitive to extreme lighting variations
- Requires visible reference object
- Severe occlusion affects estimation
- Camera angle impacts calibration accuracy

---

## 🔮 Future Directions

- 📦 Conveyor-based industrial inspection
- 📱 Mobile device compatibility
- 🏠 Indoor spatial planning integration
- ⚡ Faster real-time processing
- 📊 Multi-object simultaneous measurement

---

## 🎓 Academic Context

This project demonstrates practical implementation of classical computer vision concepts to solve industrial measurement challenges while maintaining computational efficiency and accessibility.

---

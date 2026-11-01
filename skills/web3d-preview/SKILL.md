# Web3D Interactive Preview Skill

## 🎯 Purpose & Scope
This skill provides patterns and best practices for implementing lightweight, high-performance WebGL/Three.js 3D viewers for CAD and electronics visualizers (such as `board_sketcher.html`). It enables instant spatial verification of 2D dimensional inputs, face projections, component placement, and clearance tolerances without requiring external desktop CAD compilation.

---

## 🛠️ 1. Lightweight Scene Setup Pattern

```javascript
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

function initViewer(containerElement, width = 450, height = 350) {
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0xf1f5f9);

  const camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 1000);
  camera.position.set(60, 80, 100);

  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setSize(width, height);
  renderer.setPixelRatio(window.devicePixelRatio || 1);
  renderer.shadowMap.enabled = true;
  containerElement.appendChild(renderer.domElement);

  const controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.05;

  // Ambient + Directional lighting
  const ambient = new THREE.AmbientLight(0xffffff, 0.7);
  scene.add(ambient);
  const dirLight = new THREE.DirectionalLight(0xffffff, 0.8);
  dirLight.position.set(50, 100, 50);
  scene.add(dirLight);

  return { scene, camera, renderer, controls };
}
```

---

## 📐 2. Parametric PCB & Component Mesh Generation

### Coordinate Conventions:
* $X$: Board width ($0 \dots W$)
* $Y$: Board length ($0 \dots L$, front to back)
* $Z$: Board height/thickness ($0 \dots H$, bottom to top)

### Material Palette for Electronics:
* **FR4 PCB Base:** `MeshStandardMaterial({ color: 0x0f5132, roughness: 0.4 })` (Classic green) or `0x1e293b` (Modern matte black).
* **Metal Ports (USB-A/C):** `MeshStandardMaterial({ color: 0xd1d5db, metalness: 0.85, roughness: 0.2 })`.
* **Glass/OLED Displays:** `MeshStandardMaterial({ color: 0x09090b, roughness: 0.1, metalness: 0.1 })`.
* **Tactile Buttons / LEDs:** `MeshStandardMaterial({ color: 0x2563eb, roughness: 0.3 })` or `0xef4444`.

---

## 🔄 3. Multi-Face Projection Mapping

To align 2D sketch coordinates $(u, v)$ from distinct face projections onto the 3D board:
* **Front Face (`face: "front"`):** $(X = u, Y = 0, Z = v)$
* **Top Face (`face: "top"`):** $(X = u, Y = v, Z = H)$
* **Left Face (`face: "left"`):** $(X = 0, Y = u, Z = v)$
* **Right Face (`face: "right"`):** $(X = W, Y = u, Z = v)$

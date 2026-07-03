import os
import re

filepath = 'web/index.html'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the entire JS block to ensure it's clean and has no syntax errors from the fuzzy replace
new_script = """  <script>
    // ─────────────────────────────────────────────────────────────────────
    // CONTROL DEL BANNER Y CANVAS DE FLUTTER
    // Resuelve dos problemas:
    //   1. El banner no debe tapar el canvas de Flutter (margen inferior).
    //   2. En móvil, cuando el teclado virtual abre, el banner se oculta
    //      automáticamente para no robarle espacio a los formularios.
    // ─────────────────────────────────────────────────────────────────────
    (function() {
      var AD_HEIGHT   = 40;   // px
      var KB_THRESHOLD = 150; // px — cambio mínimo de viewport para detectar teclado

      var adBar       = null;
      var keyboardOpen = false;

      // ── Muestra u oculta el banner ─────────────────────────────────────
      function showBanner(visible) {
        if (!adBar) adBar = document.getElementById('bottom-ad-bar');
        if (!adBar) return;
        adBar.style.display = visible ? 'flex' : 'none';
      }

      // ── Detecta apertura/cierre del teclado virtual via visualViewport ──
      // visualViewport.height baja cuando el teclado sube; window.innerHeight no.
      function onViewportResize() {
        if (!window.visualViewport) return;
        var gap = window.innerHeight - window.visualViewport.height;
        var kbNowOpen = gap > KB_THRESHOLD;
        if (kbNowOpen !== keyboardOpen) {
          keyboardOpen = kbNowOpen;
          showBanner(!keyboardOpen); // oculta banner con teclado abierto
        }
      }

      if (window.visualViewport) {
        window.visualViewport.addEventListener('resize', onViewportResize);
      }
    })();
  </script>
</body>
</html>"""

# We'll use regex to replace from the start of the script to the end of the file
content = re.sub(r'  <script>\n    // ─────────────────────────────────────────────────────────────────────\n    // CONTROL DEL BANNER Y CANVAS DE FLUTTER.*</html>', new_script, content, flags=re.DOTALL)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("HTML script block fixed")

EOF

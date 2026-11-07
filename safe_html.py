import os

filepath = 'web/index.html'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update AD_HEIGHT to 40
content = content.replace("var AD_HEIGHT   = 70;", "var AD_HEIGHT   = 40;")

# 2. Insert user ad unit
t1 = """    <ins class="adsbygoogle"
         style="display:block"
         data-ad-client="ca-pub-7702396954288314"
         data-ad-slot="XXXXXXXXXX"
         data-ad-format="horizontal"
         data-full-width-responsive="true">
    </ins>"""
r1 = """    <ins class="adsbygoogle"
         style="display:block"
         data-ad-format="fluid"
         data-ad-layout-key="-f7+5u+4t-da+6l"
         data-ad-client="ca-pub-7702396954288314"
         data-ad-slot="4531784987"></ins>"""
content = content.replace(t1, r1)

# 3. Change CSS from 70px to 40px, and remove flt-glass-pane bottom
t2 = """    :root {
      --ad-bar-height: 70px;
    }

    flt-glass-pane {
      bottom: var(--ad-bar-height) !important;
    }"""
r2 = """    :root {
      --ad-bar-height: 40px;
    }"""
content = content.replace(t2, r2)

# 4. Remove Javascript manipulation of flt-glass-pane
t3 = """      if (diff > KB_THRESHOLD) {
        // Teclado visible
        adBar.style.display = 'none';
        document.querySelector('flt-glass-pane').style.bottom = '0px';
      } else {
        // Teclado oculto
        adBar.style.display = 'flex';
        document.querySelector('flt-glass-pane').style.bottom = AD_HEIGHT + 'px';
      }"""
r3 = """      if (diff > KB_THRESHOLD) {
        // Teclado visible
        adBar.style.display = 'none';
      } else {
        // Teclado oculto
        adBar.style.display = 'flex';
      }"""
content = content.replace(t3, r3)

# 5. Handle waitForFlutter / applyMargin if it exists
t4 = """      // ── Función para aplicar/quitar el margen en Flutter ──────────
      function applyMargin(bottomPx) {
        if (flutterPane) {
          flutterPane.style.bottom = bottomPx + 'px';
        }
      }

      // ── Espera a que Flutter monte flt-glass-pane ──────────────────────
      function waitForFlutter() {
        flutterPane = document.querySelector('flt-glass-pane');
        if (flutterPane) {
          applyMargin(keyboardOpen ? 0 : AD_HEIGHT);
          return;
        }
        var obs = new MutationObserver(function() {
          flutterPane = document.querySelector('flt-glass-pane');
          if (flutterPane) {
            obs.disconnect();
            applyMargin(keyboardOpen ? 0 : AD_HEIGHT);
          }
        });
        obs.observe(document.body, { childList: true, subtree: true });
      }

      waitForFlutter();"""

content = content.replace(t4, "")


with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("web/index.html fixed")
EOF

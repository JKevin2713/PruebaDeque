# Demo de accesibilidad con Deque 

Calculadora mínima (HTML/CSS/JS) para probar herramientas de accesibilidad de Deque.

- `src/index.html` — versión accesible (debería pasar).
- `src/con-errores.html` — versión con errores intencionales (debería fallar).

## Estructura
```
src/                         sitio de prueba
scripts/
  Invoke-AxeLinter.ps1       análisis estático vía API (axe DevTools Linter)
  Invoke-AxeCoreScan.ps1     análisis en navegador con axe-core (gratis, sin cuenta)
  Invoke-AxeDevToolsCli.ps1  análisis con axe DevTools CLI (comercial)
  Start-LocalServer.ps1      servidor local usado por los dos anteriores
.github/workflows/accessibility.yml
```

## Pasos
1. Crea el repo en GitHub y sube todo (`git init`, `git add .`, `git commit`, `git push`).
2. Ve a **Actions** y ejecuta "Accessibility" (o haz un push). El job `axe-core` funciona sin configurar nada.
3. Para el Linter: **Settings > Secrets and variables > Actions** y crea el secreto `AXE_LINTER_API_KEY`.
4. Para axe DevTools CLI: crea los secretos `AGORA_EMAIL`, `AGORA_IDENTITY_TOKEN`, `AXE_DEVHUB_API_KEY` y la variable `AXE_DEVHUB_PROJECT_ID`; luego ejecuta el workflow manualmente con `run_devtools_cli = true`.
5. Con `fail_on_violations = true` el workflow falla si hay violaciones.

## Probar en local (PowerShell 7+)
```powershell
./scripts/Invoke-AxeCoreScan.ps1                       # requiere Node.js y Chrome + chromedriver
$env:AXE_LINTER_API_KEY = '<tu key>'
./scripts/Invoke-AxeLinter.ps1 -Path ./src
```

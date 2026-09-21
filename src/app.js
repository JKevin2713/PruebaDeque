// Calculadora mínima, sin dependencias.
const display = document.querySelector('[data-display]');
let expr = '';

function render() {
  display.textContent = expr === '' ? '0' : expr;
}

document.querySelectorAll('[data-key]').forEach((btn) => {
  btn.addEventListener('click', () => {
    const key = btn.dataset.key;
    if (key === 'C') {
      expr = '';
    } else if (key === '=') {
      try {
        // Solo dígitos y operadores básicos.
        if (!/^[0-9+\-*/.() ]+$/.test(expr)) throw new Error('Expresión inválida');
        expr = String(Function('"use strict"; return (' + expr + ')')());
      } catch {
        expr = 'Error';
      }
    } else {
      if (expr === 'Error') expr = '';
      expr += key;
    }
    render();
  });
});
render();

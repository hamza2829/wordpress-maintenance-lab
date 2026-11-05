'use strict';
document.querySelectorAll('[data-lab-toggle]').forEach((button) => {
  const panel = document.getElementById(button.getAttribute('aria-controls'));
  if (!panel) return;
  button.addEventListener('click', () => {
    const expanded = button.getAttribute('aria-expanded') === 'true';
    button.setAttribute('aria-expanded', String(!expanded));
    panel.hidden = expanded;
  });
});
if (['#lab-sent', '#lab-error'].includes(window.location.hash)) {
  const notice = document.querySelector(window.location.hash);
  if (notice) notice.hidden = false;
}

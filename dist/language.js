(() => {
  'use strict';
  const supported = ['ru', 'uk', 'el', 'en'];
  const storageKey = 'rodiart.language';
  const script = document.currentScript;
  const root = new URL('.', script.src);
  const url = new URL(location.href);
  const requested = url.searchParams.get('lang');
  const explicit = supported.includes(requested);
  const isRoot = url.pathname === root.pathname || url.pathname === root.pathname + 'index.html';
  let saved;
  try { saved = localStorage.getItem(storageKey); } catch { /* Storage may be disabled. */ }

  function remember(language) {
    try { localStorage.setItem(storageKey, language); } catch { /* Storage may be disabled. */ }
  }

  // A manual selection also applies to future visits to the site's root.
  document.addEventListener('click', (event) => {
    const link = event.target.closest('a[data-lang]');
    if (link && supported.includes(link.dataset.lang)) remember(link.dataset.lang);
  });

  // Direct links to translated pages keep their language.
  if (!explicit && !isRoot) return;
  const browserLanguage = (navigator.languages?.[0] || navigator.language || '').toLowerCase().split(/[-_]/)[0];
  const language = explicit ? requested : supported.includes(saved) ? saved : supported.includes(browserLanguage) ? browserLanguage : 'en';
  if (explicit) remember(language);

  const target = new URL(language === 'ru' ? 'index.html' : language + '/', root);
  if (explicit) url.searchParams.delete('lang');
  target.search = url.search;
  target.hash = url.hash;
  const currentLanguage = isRoot ? 'ru' : url.pathname.slice(root.pathname.length).split('/')[0];
  if (language !== currentLanguage || explicit) location.replace(target.href);
})();

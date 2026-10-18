(() => {
  'use strict';
  const websiteId = '526d0018-589c-4673-867a-f609e24f2c71';
  const trackerUrl = 'https://cloud.umami.is/script.js';
  window['ga-disable-G-SQ4BS4Y6KL'] = true;
  try { localStorage.removeItem('rodiart.analytics-consent.v1'); } catch { /* Storage may be disabled. */ }
  const production = location.protocol === 'https:' && ['rodiart.gr', 'www.rodiart.gr'].includes(location.hostname);
  if (!production) return;
  for (const entry of document.cookie.split(';')) {
    const name = entry.trim().split('=')[0];
    if (name !== '_ga' && !name.startsWith('_ga_')) continue;
    for (const domain of ['', '; Domain=rodiart.gr', '; Domain=.rodiart.gr', '; Domain=' + location.hostname]) {
      document.cookie = name + '=; Max-Age=0; Path=/' + domain + '; SameSite=Lax; Secure';
    }
  }
  if (!websiteId || !trackerUrl) return;
  const source = new URL(trackerUrl);
  if (source.protocol !== 'https:') return;
  const tag = document.createElement('script');
  tag.defer = true;
  tag.src = source.href;
  tag.dataset.websiteId = websiteId;
  tag.dataset.domains = 'rodiart.gr,www.rodiart.gr';
  tag.dataset.excludeSearch = 'true';
  tag.dataset.excludeHash = 'true';
  tag.dataset.doNotTrack = 'true';
  document.head.appendChild(tag);
  document.addEventListener('click', event => {
    const link = event.target.closest('a[href]');
    if (!link || !window.umami || typeof window.umami.track !== 'function') return;
    const url = new URL(link.href, location.href);
    let eventName;
    if (['www.instagram.com', 'instagram.com'].includes(url.hostname)) eventName = 'instagram_click';
    else if (url.hostname === 'maps.app.goo.gl') eventName = 'map_click';
    else return;
    window.umami.track(eventName, {
      page_language: document.documentElement.lang,
      link_placement: link.closest('section')?.id || (link.closest('footer') ? 'footer' : 'hero')
    });
  });
})();

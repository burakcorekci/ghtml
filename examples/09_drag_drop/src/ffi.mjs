// FFI module for Task Manager

export function now() {
  return Date.now();
}

export function getLocalStorage(key) {
  const value = localStorage.getItem(key);
  return value ? { some: value } : { none: true };
}

export function setLocalStorage(key, value) {
  localStorage.setItem(key, value);
  return undefined;
}

export function removeLocalStorage(key) {
  localStorage.removeItem(key);
  return undefined;
}

export function stringContains(haystack, needle) {
  return haystack.includes(needle);
}

export function stringLowercase(s) {
  return s.toLowerCase();
}

export function applyDarkMode(enabled) {
  if (enabled) {
    document.documentElement.classList.add('dark', 'sl-theme-dark');
    document.documentElement.classList.remove('sl-theme-light');
    localStorage.setItem('dark_mode', 'true');
  } else {
    document.documentElement.classList.remove('dark', 'sl-theme-dark');
    document.documentElement.classList.add('sl-theme-light');
    localStorage.setItem('dark_mode', 'false');
  }
  return undefined;
}

export function getDarkModePreference() {
  const stored = localStorage.getItem('dark_mode');
  if (stored !== null) {
    return stored === 'true';
  }
  // Check system preference
  return window.matchMedia('(prefers-color-scheme: dark)').matches;
}

export function clearActiveInput() {
  if (document.activeElement && document.activeElement.value !== undefined) {
    document.activeElement.value = '';
  }
  return undefined;
}

export function getSubtaskInputValue() {
  const input = document.querySelector('.subtask-input');
  if (input) {
    const value = input.value || '';
    input.value = '';
    return value;
  }
  return '';
}

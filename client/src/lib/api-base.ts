const envBase = import.meta.env.VITE_API_BASE_URL?.trim();

function normalizeBaseUrl(baseUrl: string) {
  return baseUrl.endsWith("/") ? baseUrl.slice(0, -1) : baseUrl;
}

export const API_BASE_URL = envBase ? normalizeBaseUrl(envBase) : "";

export function apiUrl(path: string) {
  if (!API_BASE_URL) {
    return path;
  }

  if (path.startsWith("http://") || path.startsWith("https://")) {
    return path;
  }

  return `${API_BASE_URL}${path}`;
}

export type ApiEnvironment = {
  VITE_PROTO_API_BASE_URL?: string
  DEV?: boolean
  PROD?: boolean
}

const DEVELOPMENT_API_ORIGIN = 'http://localhost:3101'
const REQUEST_TIMEOUT_MS = 10_000

/** Only a public API origin belongs in Vite configuration; never put credentials here. */
export function configuredApiOrigin(env: ApiEnvironment): string {
  const value = env.VITE_PROTO_API_BASE_URL?.trim() ||
    (env.DEV && !env.PROD ? DEVELOPMENT_API_ORIGIN : '')
  if (!value) throw new Error('Set VITE_PROTO_API_BASE_URL to use the live catalog in this build.')
  if (!/^https?:\/\/[^/?#\s\\]+\/?$/i.test(value)) {
    throw new Error('VITE_PROTO_API_BASE_URL must be a plain HTTP(S) origin without a path, query, or fragment.')
  }

  let url: URL
  try {
    url = new URL(value)
  } catch {
    throw new Error('VITE_PROTO_API_BASE_URL must be a valid HTTP(S) origin.')
  }
  if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password) {
    throw new Error('VITE_PROTO_API_BASE_URL must be a plain HTTP(S) origin without credentials.')
  }
  if (env.PROD && url.protocol !== 'https:') {
    throw new Error('VITE_PROTO_API_BASE_URL must use HTTPS in a production build.')
  }
  return url.origin
}

/** Fetches public JSON with safe browser-facing errors and the caller's abort signal. */
export async function getJson(
  url: string,
  signal: AbortSignal,
  fetchImpl: typeof fetch = globalThis.fetch,
  timeoutMs = REQUEST_TIMEOUT_MS,
): Promise<unknown> {
  const timeout = AbortSignal.timeout(timeoutMs)
  let response: Response
  try {
    response = await fetchImpl(url, {
      method: 'GET',
      headers: { Accept: 'application/json' },
      cache: 'no-store',
      signal: AbortSignal.any([signal, timeout]),
    })
  } catch (error) {
    if (signal.aborted) throw error
    if (timeout.aborted) throw new Error('The API request timed out. Try again.')
    throw new Error('Cannot reach the API. Check the backend address and browser CORS configuration.')
  }

  if (!response.ok) throw new Error(`The API request failed (HTTP ${response.status}).`)
  try {
    return await response.json()
  } catch {
    if (signal.aborted) throw signal.reason
    if (timeout.aborted) throw new Error('The API request timed out. Try again.')
    throw new Error('The API returned malformed JSON.')
  }
}

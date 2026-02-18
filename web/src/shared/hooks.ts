import { useEffect, useState } from 'react'

interface AsyncState<T> {
  data: T | null
  isLoading: boolean
  error: string | null
  refetch: () => void
}

export function useAsync<T>(fetcher: () => Promise<T>, deps: unknown[] = []): AsyncState<T> {
  const [data, setData] = useState<T | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [refetchKey, setRefetchKey] = useState(0)

  useEffect(() => {
    let cancelled = false
    setIsLoading(true)
    setError(null)

    fetcher()
      .then((result) => {
        if (!cancelled) {
          setData(result)
          setIsLoading(false)
        }
      })
      .catch((e) => {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : 'An error occurred')
          setIsLoading(false)
        }
      })

    return () => { cancelled = true }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [...deps, refetchKey])

  return { data, isLoading, error, refetch: () => setRefetchKey((k) => k + 1) }
}

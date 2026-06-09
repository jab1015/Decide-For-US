import { createContext, useContext, useState, useEffect, useCallback } from 'react'
import { api, setToken, getAuthToken } from '../api/client'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  // Check for existing token on mount
  useEffect(() => {
    const token = getAuthToken()
    if (token) {
      api.getMe()
        .then((data) => {
          setUser(data.user || data)
        })
        .catch(() => {
          setToken(null)
          setUser(null)
        })
        .finally(() => setLoading(false))
    } else {
      setLoading(false)
    }
  }, [])

  const login = useCallback(async (email, password) => {
    const data = await api.login({ email, password })
    setToken(data.token)
    setUser(data.user)
    return data
  }, [])

  const register = useCallback(async (email, password, age) => {
    const data = await api.register({ email, password, age })
    setToken(data.token)
    setUser(data.user)
    return data
  }, [])

  const logout = useCallback(() => {
    setToken(null)
    setUser(null)
  }, [])

  const refreshUser = useCallback(async () => {
    try {
      const data = await api.getMe()
      setUser(data.user || data)
    } catch {
      // silent
    }
  }, [])

  const isPremium = user?.subscription === 'premium' || user?.is_premium
  const ageStatus = user?.age_verification?.status || null // 'pending' | 'approved' | null

  return (
    <AuthContext.Provider value={{
      user,
      loading,
      login,
      register,
      logout,
      refreshUser,
      isPremium,
      ageStatus,
    }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
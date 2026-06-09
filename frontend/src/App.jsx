import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { AuthProvider } from './hooks/useAuth'
import Layout from './components/Layout'
import RequirePremium from './components/RequirePremium'
import Home from './pages/Home'
import Discover from './pages/Discover'
import Auth from './pages/Auth'
import Settings from './pages/Settings'
import Premium from './pages/Premium'
import DateNight from './pages/DateNight'
import TripPlanner from './pages/TripPlanner'

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route element={<Layout />}>
            <Route path="/" element={<Home />} />
            <Route path="/discover" element={<Discover />} />
            <Route path="/auth" element={<Auth />} />
            <Route path="/settings" element={<Settings />} />
            <Route path="/premium" element={<Premium />} />
            <Route
              path="/date-night"
              element={
                <RequirePremium>
                  <DateNight />
                </RequirePremium>
              }
            />
            <Route
              path="/trip-planner"
              element={
                <RequirePremium>
                  <TripPlanner />
                </RequirePremium>
              }
            />
          </Route>
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  )
}

export default App
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { App } from './App'
import { initEngine } from './engine/wasm-engine'
import './index.css'

initEngine().catch((err) => {
  console.warn('[engine] WASM engine failed to load:', err)
})

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)

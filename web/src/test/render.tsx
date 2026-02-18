import { render, type RenderOptions } from '@testing-library/react'
import { MemoryRouter, type MemoryRouterProps } from 'react-router'
import type { ReactElement } from 'react'

interface WrapperOptions extends RenderOptions {
  routerProps?: MemoryRouterProps
}

export function renderWithRouter(ui: ReactElement, options: WrapperOptions = {}) {
  const { routerProps, ...renderOptions } = options
  return render(
    <MemoryRouter {...routerProps}>{ui}</MemoryRouter>,
    renderOptions,
  )
}

/**
 * WASM Engine Wrapper
 *
 * Wraps the Rust cribbage-engine compiled to WASM via wasm-pack.
 * All functions use JSON interchange (strings in, strings out),
 * matching the existing flutter_rust_bridge API.
 *
 * TODO: Replace this stub with actual wasm-pack imports once
 * the engine is rebuilt with wasm-bindgen instead of flutter_rust_bridge.
 * For now, this defines the interface that the rest of the app will use.
 */

export interface WasmEngine {
  engine_new(
    gameId: string,
    player1Id: string,
    player1Name: string,
    player2Id: string,
    player2Name: string,
    seed?: number,
  ): string

  engine_restore(stateJson: string): string
  engine_current_state_json(engineHandle: number): string
  engine_apply_action_json(engineHandle: number, actionJson: string): string
  engine_process_ai_json(
    engineHandle: number,
    aiPlayerId: string,
    difficulty: string,
    maxIterations: number,
  ): string

  analyze_discards_json(handJson: string, isDealer: boolean): string
  calculate_hand_score_json(handJson: string, cutCardJson: string, isCrib: boolean): number
  glicko2_calculate_json(
    playerRating: number,
    playerDeviation: number,
    playerVolatility: number,
    opponentRating: number,
    opponentDeviation: number,
    opponentVolatility: number,
    score: number,
  ): string
}

let wasmModule: WasmEngine | null = null

export async function initEngine(): Promise<void> {
  // TODO: Import from wasm-pack output once engine is rebuilt
  // import init, * as wasm from '../../engine/pkg/cribbage_engine'
  // await init()
  // wasmModule = wasm
  console.log('[engine] WASM engine initialization placeholder — not yet wired up')
}

export function getEngine(): WasmEngine {
  if (!wasmModule) {
    throw new Error('WASM engine not initialized. Call initEngine() first.')
  }
  return wasmModule
}

export function isEngineReady(): boolean {
  return wasmModule != null
}

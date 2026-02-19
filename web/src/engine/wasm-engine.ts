/**
 * WASM Engine Wrapper
 *
 * Wraps the Rust cribbage-engine compiled to WASM via wasm-pack.
 * All functions use JSON interchange (strings in, strings out),
 * matching the existing flutter_rust_bridge API.
 */

import init, * as wasm from 'cribbage-engine'

export interface WasmEngine {
  engine_new(
    gameId: string,
    player1Id: string,
    player1Name: string,
    player2Id: string,
    player2Name: string,
    seed?: number,
  ): number

  engine_restore(stateJson: string): number
  engine_current_state_json(handle: number): string
  engine_apply_action_json(handle: number, actionJson: string): string
  engine_process_ai_json(
    handle: number,
    aiPlayerId: string,
    difficulty: string,
    maxIterations: number,
  ): string
  engine_free(handle: number): void

  analyze_discards_json(handJson: string, isDealer: boolean): string
  explain_keep_json(handJson: string, keepJson: string, isDealer: boolean): string
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
  await init()
  wasmModule = wasm as unknown as WasmEngine
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

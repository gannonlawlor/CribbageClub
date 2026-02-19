declare module 'cribbage-engine' {
  export default function init(): Promise<void>

  export function engine_new(
    game_id: string,
    player1_id: string,
    player1_name: string,
    player2_id: string,
    player2_name: string,
    seed?: number,
  ): number

  export function engine_restore(state_json: string): number
  export function engine_current_state_json(handle: number): string
  export function engine_apply_action_json(handle: number, action_json: string): string
  export function engine_process_ai_json(
    handle: number,
    ai_player_id: string,
    difficulty: string,
    max_iterations: number,
  ): string
  export function engine_free(handle: number): void

  export function analyze_discards_json(hand_json: string, is_dealer: boolean): string
  export function explain_keep_json(hand_json: string, keep_json: string, is_dealer: boolean): string
  export function calculate_hand_score_json(
    hand_json: string,
    cut_card_json: string,
    is_crib: boolean,
  ): number

  export function glicko2_calculate_json(
    player_rating: number,
    player_deviation: number,
    player_volatility: number,
    opponent_rating: number,
    opponent_deviation: number,
    opponent_volatility: number,
    score: number,
  ): string
}

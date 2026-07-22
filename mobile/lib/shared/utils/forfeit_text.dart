/// Wording for a `GameForfeited` event.
///
/// "Forfeit" is the umbrella the model uses for any game that ends before
/// someone pegs out; the `reason` says which kind. Resigning is the only one
/// the player chooses, so that is the word the in-game action uses — the
/// others read as what happened to them.
///
/// The raw reason code is never shown; route it through here instead.
library;

/// Verb phrase for a forfeit reason: "resigned", "ran out of time",
/// "disconnected". Falls back to "forfeited" for a reason we don't know.
String forfeitVerb(String? reason) => switch (reason) {
  'RESIGN' => 'resigned',
  'TIMEOUT' => 'ran out of time',
  'DISCONNECT' => 'disconnected',
  _ => 'forfeited',
};

/// Full sentence for a forfeit: "You resigned", "Opponent ran out of time".
String forfeitSentence(String? reason, {required bool isSelf}) =>
    '${isSelf ? 'You' : 'Opponent'} ${forfeitVerb(reason)}';

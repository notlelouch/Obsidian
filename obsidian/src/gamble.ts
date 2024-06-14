import {
  GameEnded,
  GameStarted,
  OwnershipTransferred,
  PlayerJoined
} from "../generated/Gamble/Gamble"
import {Game} from "../generated/schema"

export function handleGameEnded(event : GameEnded): void {
  let entity = Game.load(event.params.gameId.toString());

  if (!entity) {
    return;
  }

  entity.winner = event.params.winner;
  entity.save();
}

export function handleGameStarted(event : GameStarted): void {
  let entity = Game.load(event.params.gameId.toString());

  if (!entity) {
    entity = new Game(event.params.gameId.toString());
    entity.players  = [];
  }

  entity.maxPlayers = event.params.maxPlayers;
  entity.entryFee = event.params.entryFee;
  entity.save();
}

export function handlePlayerJoined(event : PlayerJoined): void {
  let entity = Game.load(event.params.gameId.toString());

  if (!entity) {
    return;
  }

  let newPlayers = entity.players;
  newPlayers.push(event.params.player);
  entity.players = newPlayers;
  entity.save();
}

export function handleOwnershipTransferred(event : OwnershipTransferred): void {}

<script>
  import { onMount } from 'svelte';
  import api from './js/api.js';
  import PGNViewer from "./lib/PGNViewer.svelte";

  let games = []; // hold the list of available games
  let game = null;
  let backendHost = "";

  onMount( () => {
    api.getGames().then( ( response ) => {
      console.log( 'Response', response.message );
      games = response.points;
      backendHost = response.host;
    })
  })

</script>

<main>
  <h1>Chess Game player</h1>

  <select bind:value={game}>
    {#each games as game}
      <option value={game}>{game.field.fields.Date + ' at '+game.field.fields.Event+' : ' + game.field.fields.Black +' - '+game.field.fields.White}</option>
    {/each}
  </select>

  <PGNViewer game={game} />

  <div id="debug">Host: {backendHost}</div>
</main>

<style>
  select {
    font-size: 1.2rem;
  }
</style>

<script>
    // https://www.npmjs.com/package/@mliebelt/pgn-viewer

    import { onMount } from 'svelte';

    export let game = null; // PGN format

    let mounted = false;

    onMount( () => {
        mounted = true;
        startView();
    })

    $: startView( game );

    function startView() {
        console.log( 'Game', game );
        if( mounted && game ) {
            PGNV.pgnView('board', {pgn: game.moves, pieceStyle: 'merida', width: '600px'});
        }
    }

</script>
<div class='wrapper'>
    {#if game}
        Playing {game.field.fields.Date + ' at '+game.field.fields.Event+' : ' + game.field.fields.Black +' - '+game.field.fields.White}
    {:else}
        ... select game to play ...
    {/if}
    <div id='board'></div>
</div>
<style>
    .wrapper {
        display: flex;
        flex-direction: column;
        align-items: center;
        border: solid burlywood;
        border-radius: 3px;
    }
</style>
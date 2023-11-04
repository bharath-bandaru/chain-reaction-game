import { useEffect } from "react";
import { Player } from "./Actor";

export const Square = ({ id, value, max, hints, currrentPlayer, onClick, canClick, isLive, mainPLayer }) => {
    const player_color = [
        '#00A8CD',
        '#CD00C5',
        '#B0CD00',
        '#CD0000'
    ];
    useEffect(()=>{
        console.log(currrentPlayer)
    },[currrentPlayer])
    return (
        <>
            {
                <button className="square" id={id} onClick={onClick} disabled={!canClick} style={
                    // isLive?{ "color": player_color[mainPLayer] }:
                    { "color": player_color[currrentPlayer] }}>
                    <Player
                        color={value != null ? value.color : ''}
                        state={value != null ? value.state : 0}
                        max={max}
                        hints={hints}
                    />
                </button>
            }
        </>
    );
}
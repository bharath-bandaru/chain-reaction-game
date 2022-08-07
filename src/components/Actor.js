import { One } from "./actors/ActorOne";
import { Three } from "./actors/ActorThree";
import { Two } from "./actors/ActorTwo";

export const Player = ({ state, color, max, hints }) => {
    return (
        <>
            {<>
                <div className='container'>
                    <div className='anim hide atom'>
                        {
                            (max === 1) &&
                            <>
                                <div className="nucleus"></div>
                                <div className="nucleus"></div>
                            </>
                        }
                        {
                            (max === 2) &&
                            <>
                                <div className="nucleus"></div>
                                <div className="nucleus"></div>
                                <div className="nucleus"></div>
                            </>
                        }
                        {
                            (max === 3) &&
                            <>
                                <div className="nucleus"></div>
                                <div className="nucleus"></div>
                                <div className="nucleus"></div>
                                <div className="nucleus"></div>
                            </>
                        }

                    </div>
                    <div style={{ fill: color }}>
                        {(state === 1) &&
                            <One />
                        }
                        {(state === 2) &&
                            <Two />
                        }
                        {(state >= 3) &&
                            <Three />
                        }
                    </div>
                </div>
            </>
            }
        </>
    );
}
import edgeCorner from '../images/edge_corner.png';
import edge from '../images/edge.png';
import inner from '../images/inner.png';
import gif from '../images/ch.gif';
export const HowToPlay = ({ state }) => {
    return (
        <>
            {
                (state === 0) &&
                <div className='loader-center-div' style={{ background: "#000000e3" }}>
                    <div className="loader-center" style={{ marginTop: '8px', width: '100%' }}>
                        <div className="flex" style={{ flexDirection: 'column' }}>
                            <h2 style={{
                                backgroundColor: 'rgb(255 255 9)',
                                color: '#000',
                                padding: '0px 20px'
                            }}>
                                HOW TO PLAY?</h2>
                        </div>
                        <div className="flex" style={{ marginBottom: "10px", flexDirection: 'column' }}>
                            <div className="number" style={{ background: "#05a8cd", color: '#000' }}>1</div>
                            <div className="quote">"A strategy game that can be played online for 2 to 4 players."</div>
                        </div>
                        <div className="flex" style={{ marginBottom: "10px", flexDirection: 'column' }}>
                            <div className="number" style={{ background: "#cd00c5" }}>2</div>
                            <div className="quote">"The objective of the game is to take control of the board by eliminating your opponents' balls. Players take turns to place their balls in a cell."</div>
                        </div>
                        <div className="flex" style={{ marginBottom: "10px", flexDirection: 'column' }}>
                            <div className="number" style={{ background: "rgb(255 255 9)", color: "#000" }}>3</div>
                            <div className="quote">"Once a cell reaches <span style={{ backgroundColor: '#ffff09', color: "#191919" }}>"critical mass"</span> , the balls explode into the surrounding cells adding an extra ball and claiming the cells of the player."</div>
                        </div>
                        <div className="flex" style={{ marginBottom: "10px", flexDirection: 'column' }}>
                            <div className="number" style={{ background: "#cc0100" }}>4</div>
                            <div className="quote">"A player can only place their balls in a Blank cell (or) a cell that contains balls of their Own color. As soon as a player loses all their balls they are out of the game."</div>
                        </div>
                    </div>
                </div>
            }
            {
                (state === 1) &&
                <div className='loader-center-div' style={{ background: "#000000e3" }}>
                    <div className="loader-center" style={{ marginTop: '8px', width: '100%' }}>
                        <div className="flex" style={{ flexDirection: 'column' }}>
                            <h2 style={{
                                backgroundColor: 'rgb(255 255 9)',
                                color: '#000',
                                padding: '0px 20px'
                            }}>
                                critical mass?</h2>
                        </div>
                        <div className="flex" style={{ marginBottom: "10px", flexDirection: 'column' }}>
                            <div className="number" style={{ background: "#05a8cd", color: '#000' }}>1</div>
                        </div>
                        <div className="flex" style={{ marginBottom: "10px", flexDirection: 'column' }}>
                            <img src={edgeCorner} alt="one" width={'300px'}></img>
                        </div>
                        <div className="flex" style={{ marginBottom: "10px", flexDirection: 'column' }}>
                            <div className="quote" style={{ fontWeight: "700", paddingTop: '7px' }}>EDGE CORNERS</div>
                            <div style={{ width: "300px" }} className="quote">"1 explodes to 2!"</div>
                        </div>
                    </div>
                </div>
            }
            {
                (state === 2) &&
                <div className='loader-center-div' style={{ background: "#000000e3" }}>
                    <div className="loader-center" style={{ marginTop: '8px', width: '100%' }}>
                        <div className="flex" style={{ flexDirection: 'column' }}>
                            <h2 style={{
                                backgroundColor: 'rgb(255 255 9)',
                                color: '#000',
                                padding: '0px 20px'
                            }}>
                                critical mass?</h2>
                        </div>
                        <div className="flex" style={{ marginBottom: "10px", flexDirection: 'column' }}>
                            <div className="number" style={{ background: "#cd00c5" }}>2</div>
                        </div>
                        <div className="flex" style={{ marginBottom: "10px", flexDirection: 'column' }}>
                            <img src={edge} alt="one" width={'300px'}></img>
                        </div>
                        <div className="flex" style={{ marginBottom: "10px", flexDirection: 'column' }}>
                            <div className="quote" style={{ fontWeight: "700", paddingTop: '7px' }}>SIDES</div>
                            <div style={{ width: "300px" }} className="quote">"2 explodes to 3!"</div>
                        </div>
                    </div>
                </div>
            }
            {
                (state === 3) &&
                <div className='loader-center-div' style={{ background: "#000000e3" }}>
                    <div className="loader-center" style={{ marginTop: '8px', width: '100%' }}>
                        <div className="flex" style={{ flexDirection: 'column' }}>
                            <h2 style={{
                                backgroundColor: 'rgb(255 255 9)',
                                color: '#000',
                                padding: '0px 20px'
                            }}>
                                critical mass?</h2>
                        </div>
                        <div className="flex" style={{ marginBottom: "10px", flexDirection: 'column' }}>
                            <div className="number" style={{ background: "#cc0100" }}>3</div>
                        </div>
                        <div className="flex" style={{ marginBottom: "10px", flexDirection: 'column' }}>
                            <img src={inner} alt="one" width={'300px'}></img>
                        </div>
                        <div className="flex" style={{ marginBottom: "10px", flexDirection: 'column' }}>
                            <div className="quote" style={{ fontWeight: "700", paddingTop: '7px' }}>INNER CELLS</div>
                            <div style={{ width: "300px" }} className="quote">"3 explodes to 4!"</div>
                        </div>
                    </div>
                </div>
            }
            {
                (state === 4) &&
                <div className='loader-center-div' style={{ background: "#000000e3" }}>
                    <div className="loader-center" style={{ marginTop: '8px', width: '100%' }}>
                        <div className="flex" style={{ flexDirection: 'column' }}>
                            <h2 style={{
                                backgroundColor: 'rgb(255 255 9)',
                                color: '#000',
                                padding: '0px 20px'
                            }}>
                                chain reaction!</h2>
                        </div>
                        <div className="flex" style={{ marginBottom: "10px", flexDirection: 'column' }}>
                            <img src={gif} alt="one" width={'300px'}></img>
                        </div>
                        <div className="flex" style={{ marginBottom: "10px", flexDirection: 'column' }}>
                            <div className="quote">"Now, you can play <span style={{ width: "300px", fontWeight: "bold" }} >ONLINE</span> with your friends!"</div>
                            <div className="quote">"(Click  🚀 on bottom right)"</div>
                        </div>
                    </div>
                </div>
            }
        </>
    )
}
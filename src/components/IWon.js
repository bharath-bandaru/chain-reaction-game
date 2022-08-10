import lose from '../images/lose.gif';
export const IWon = () => {
    return (
        <>
            {
                <div className='loader-center-div' style={{ background: "#000000e3" }}>
                    <div className="loader-center">
                        <img src={lose} alt="won" width={'300px'}></img>
                    </div>
                </div>
            }
        </>
    );
}
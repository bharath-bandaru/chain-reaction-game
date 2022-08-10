import won from '../images/iwon.gif';
export const IWon = () => {
    return (
        <>
            {
                <div className='loader-center-div' style={{ background: "#000000e3" }}>
                    <img src={won} alt="won" width={'300px'}></img>
                </div>
            }
        </>
    );
}
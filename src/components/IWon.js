
import lose from '../images/lose.gif';
import won from '../images/won.gif';

export const IWon = ({ wonStatus, showAboutMe }) => {
    return (
        <>
            {
                <div className='loader-center-div' style={{ background: "#000000e3", zIndex: "1000" }}>
                    <div className="loader-center">
                        <div className="flex" style={{ flexDirection: 'column', marginTop: '440px' }}>
                            <a className='support-btn-2' href='https://www.paypal.com/donate/?business=QTCZHFFF6J6HE&no_recurring=0&currency_code=USD' target={'_blank'} rel="noopener noreferrer">
                                <div className='flex'>
                                    <span className="material-icons noselect" style={{ fontSize: "18px", marginRight: "3px" }}> favorite </span>
                                    <span>Support</span>
                                </div>
                            </a>
                        </div>
                    </div>
                    <div className="loader-center">
                        <div className="flex" style={{ flexDirection: 'column', marginTop: '432px' }}>
                            <a className='support-btn' href='https://www.paypal.com/donate/?business=QTCZHFFF6J6HE&no_recurring=0&currency_code=USD' target={'_blank'} rel="noopener noreferrer">
                                <div className='flex'>
                                    <span className="material-icons noselect" style={{ fontSize: "18px", marginRight: "3px" }}> favorite </span>
                                    <span>Support</span>
                                </div>
                            </a>
                        </div>
                    </div>
                    <div className="loader-center">
                        {(showAboutMe) && <div className={"abme"} style={{ marginBottom: "15px", fontSize: '9px' }}>
                            <span style={{ color: '#6a6a6a', marginBottom: '5px' }}> Designed and Developed by © Bharath Bandaru</span>
                        </div>}
                        <div className="flex img-css">
                            <img src={wonStatus ? won : lose} alt="won" width={'300px'}></img>
                        </div>
                    </div>
                </div>

            }
        </>
    );
}
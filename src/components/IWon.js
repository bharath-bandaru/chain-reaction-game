
import lose from '../images/lose.gif';
import won from '../images/won.gif';

export const IWon = ({ wonStatus, showAboutMe, logEvent }) => {
    return (
        <>
            {
                <div className='loader-center-div' style={{ background: "#000000e3", zIndex: "1000" }}>
                    <div className="loader-center">
                        <div className="flex" style={{ flexDirection: 'column', marginTop: '610px' }}>
                            <a className='support-btn-2' href='https://www.paypal.com/donate/?business=QTCZHFFF6J6HE&no_recurring=0&currency_code=USD' target={'_blank'} rel="noopener noreferrer">
                                <div className='flex'>
                                    <span className="material-icons noselect" style={{ fontSize: "18px", marginRight: "3px" }}> favorite </span>
                                    <span>Support</span>
                                </div>
                            </a>
                        </div>
                    </div>
                    <div className="loader-center">
                        <div className="flex" style={{ flexDirection: 'column', marginTop: '602px' }}>
                            <a className='support-btn' href='https://www.paypal.com/donate/?business=QTCZHFFF6J6HE&no_recurring=0&currency_code=USD' target={'_blank'} rel="noopener noreferrer">
                                <div className='flex'>
                                    <span className="material-icons noselect" style={{ fontSize: "18px", marginRight: "3px" }}> favorite </span>
                                    <span>Support</span>
                                </div>
                            </a>
                        </div>
                    </div>
                    <div className="loader-center">
                        <div className="flex img-css">
                            {(showAboutMe) && <div style={{ marginTop: "0px", fontSize: '9px' }}>
                                <span style={{ color: '#6a6a6a', marginBottom: '110px' }}> Designed and Developed by © Bharath Bandaru</span>
                            </div>}
                            <img style={{marginTop:"5px"}} src={wonStatus ? won : lose} alt="won" width={'300px'}></img>
                        </div>
                        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', marginTop: '50px', width: '100%' }}>
                            <p style={{ marginBottom: "20px", fontSize: "14px", color: "#cecece95"  }}>Check out our new app <b style={{color:"#a1954e"}}>"roamates"</b> <br/>on Play Store now! 😶‍🌫️ 🚀</p>
                            <a href="https://play.google.com/store/apps/details?id=us.ephileo.roamates" target="_blank" rel="noopener noreferrer">
                                <img onClick={()=>logEvent("escape")} src={require('../images/logo-roamates.png')} alt="Play Game" style={{ width: "75px", cursor: "pointer", opacity:"0.9", borderRadius:"20px", boxShadow: "rgb(255 196 58) 0px 3px 25px" }} />
                            </a>
                        </div>
                    </div>
                </div>

            }
        </>
    );
}
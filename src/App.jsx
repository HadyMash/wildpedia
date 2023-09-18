import './App.css'
import PropTypes from "prop-types";
import {Tooltip as ReactTooltip} from "react-tooltip";

function App() {

    return (
        <div className={'home'}>
            <Content/>
            {/* TODO: animate controls in and out based on cursor position on the screen */}
            <Controls/>
        </div>
    )
}

function Content() {
    return <div className={'content'}>hello world from content</div>
}

function Controls(handleGoBack, handleGoForward, handleNew, handleSettings) {
    Controls.propTypes = {
        handleGoBack: PropTypes.func.isRequired,
        handleGoForward: PropTypes.func.isRequired,
        handleNew: PropTypes.func.isRequired,
        handleSettings: PropTypes.func.isRequired
    }

    // TODO: conditionally show forward/new and add disabled style to back when there are no more articles to go back to
    return <div className={'controls'}>
        <div className={'button-group'}>
            <button data-tooltip-id="back" onClick={handleGoBack}>&lt;</button>
            <button data-tooltip-id="forward" onClick={handleGoForward}>&gt;</button>
            <button data-tooltip-id="new" onClick={handleNew}>?</button>
            <button data-tooltip-id="settings" onClick={handleSettings}>Settings</button>
        </div>
        {/* TODO: remove delay if a tooltip is already shown*/}
        <ReactTooltip id="back" place="bottom" effect="solid" content="Previous article" delayShow={1000}/>
        <ReactTooltip id="forward" place="bottom" effect="solid" content="Next article" delayShow={1000}/>
        <ReactTooltip id="new" place="bottom" effect="solid" content="Random article" delayShow={1000}/>
        <ReactTooltip id="settings" place="bottom" effect="solid" content="Settings" delayShow={1000}/>
    </div>
}

export default App;
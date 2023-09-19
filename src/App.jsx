import './App.css';
import { useState, useEffect, useRef } from 'react';
import PropTypes from 'prop-types';
import { Tooltip as ReactTooltip } from 'react-tooltip';

function App() {
  const [uri, setUri] = useState(
    'https://en.wikipedia.org/wiki/Special:Random',
  );

  // TODO: implement functions
  function goBack() {
    console.log('go back');
  }

  // TODO: implement functions
  function goForward() {
    console.log('go forward');
  }

  // TODO: implement functions
  function randomArticle() {
    function randomIntBetweenInclusive(min, max) {
      if (min > max) {
        let tempMin = min;
        min = max;
        max = tempMin;
      }

      min = Math.ceil(min);
      max = Math.floor(max);
      return Math.floor(Math.random() * (max - min + 1)) + min;
    }

    // TODO: implement preferences into uri
    function newUrl(lang, category, depth) {
      let url = new URL(
        `https://tools.wmflabs.org/magnustools/randomarticle.php`,
      );
      url.searchParams.set('lang', lang);
      url.searchParams.set('project', 'wikipedia');
      url.searchParams.set('categories', category);
      url.searchParams.set('d', depth.toString());

      return url;
    }

    const url = newUrl('en', 'Physics', randomIntBetweenInclusive(1, 3));
    console.log(url, url.toString());
    setUri(url.toString());
  }

  // TODO: implement functions
  function showSettings() {
    console.log('show settings');
  }

  return (
    <div className={'home'}>
      <Content uri={uri} />
      {/* TODO: animate controls in and out based on cursor position on the screen */}
      <Controls
        handleGoBack={goBack}
        handleGoForward={goForward}
        handleRandomArticle={randomArticle}
        handleSettings={showSettings}
      />
    </div>
  );
}

function Content({ uri }) {
  Content.propTypes = {
    uri: PropTypes.string.isRequired,
  };

  const progressBarRef = useRef(null);
  const iframeRef = useRef(null);
  const [loading, setLoading] = useState(true);
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const iframe = iframeRef.current;
    if (!iframe) {
      return;
    }
    console.log(iframe);
    const progressBar = progressBarRef.current;
    if (!progressBar) {
      return;
    }
    console.log(progressBar);

    const handleLoadingStarted = () => {
      console.log('loading');
      setLoading(true);
    };

    const handleProgress = (e) => {
      console.log('progress', e);
      if (e.lengthComputable) {
        const percentComplete = (e.loaded / e.total) * 100;
        console.log('progress', `${percentComplete}%`);
        setProgress(percentComplete);
      }
    };

    const handleLoaded = () => {
      console.log('loaded');
      setLoading(false);
      setProgress(0);
    };

    console.log('adding event listeners');
    // TODO: fix loadstart and progress events not firing
    iframe.addEventListener('loadstart', handleLoadingStarted);
    iframe.addEventListener('progress', handleProgress);
    iframe.addEventListener('load', handleLoaded);
    console.log('added event listeners');

    return () => {
      console.log('removing event listeners');
      iframe.removeEventListener('loadstart', handleLoadingStarted);
      iframe.removeEventListener('progress', handleProgress);
      iframe.removeEventListener('load', handleLoaded);
      console.log('removed event listeners');
    };
  }, []);

  return (
    <>
      <ProgressBar
        loading={loading}
        progress={progress}
        progressBarRef={progressBarRef}
      />
      <div className={'content'}>
        <iframe src={uri} title={'Wikipedia article'} ref={iframeRef} />
      </div>
    </>
  );
}

function ProgressBar({ loading, progress, progressBarRef }) {
  ProgressBar.propTypes = {
    loading: PropTypes.bool.isRequired,
    progress: PropTypes.number.isRequired,
    progressBarRef: PropTypes.object.isRequired,
  };

  return (
    <div className={'progress-bar-container'}>
      <div
        className={`progress-bar ${loading ? '' : 'loaded'}`}
        ref={progressBarRef}
        style={{
          width: `${progress}%`,
        }}
      ></div>
    </div>
  );
}

function Controls({
  handleGoBack,
  handleGoForward,
  handleRandomArticle,
  handleSettings,
}) {
  Controls.propTypes = {
    handleGoBack: PropTypes.func.isRequired,
    handleGoForward: PropTypes.func.isRequired,
    handleRandomArticle: PropTypes.func.isRequired,
    handleSettings: PropTypes.func.isRequired,
  };

  // TODO: conditionally show forward/new and add disabled style to back when there are no more articles to go back to
  // TODO: replace with icons
  return (
    <div className={'controls'}>
      <div className={'button-group'}>
        <button data-tooltip-id="back" onClick={handleGoBack}>
          &lt;
        </button>
        <button data-tooltip-id="forward" onClick={handleGoForward}>
          &gt;
        </button>
        <button data-tooltip-id="new" onClick={handleRandomArticle}>
          ?
        </button>
        <button data-tooltip-id="settings" onClick={handleSettings}>
          Settings
        </button>
      </div>
      {/* TODO: remove delay if a tooltip is already shown*/}
      <ReactTooltip
        id="back"
        place="bottom"
        effect="solid"
        content="Previous article"
        delayShow={1000}
      />
      <ReactTooltip
        id="forward"
        place="bottom"
        effect="solid"
        content="Next article"
        delayShow={1000}
      />
      <ReactTooltip
        id="new"
        place="bottom"
        effect="solid"
        content="Random article"
        delayShow={1000}
      />
      <ReactTooltip
        id="settings"
        place="bottom"
        effect="solid"
        content="Settings"
        delayShow={1000}
      />
    </div>
  );
}

export default App;

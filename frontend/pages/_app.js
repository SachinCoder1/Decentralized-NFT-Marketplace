import { MoralisProvider } from "react-moralis";
import "../styles/globals.css";

function MyApp({ Component, pageProps }) {
  const APPID = process.env.NEXT_PUBLIC_SERVER_URL;
  const SERVERURL = process.env.NEXT_PUBLIC_APP_ID;
  return (
    <MoralisProvider appId={APPID} serverUrl={SERVERURL}>
      <Component {...pageProps} />
    </MoralisProvider>
  );
}

export default MyApp;

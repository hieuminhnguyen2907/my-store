import "antd/dist/reset.css";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App as AntdApp } from "antd";
import App from "./App.jsx";

createRoot(document.getElementById("root")).render(
  <StrictMode>
    <AntdApp>
      <App />
    </AntdApp>
  </StrictMode>
);

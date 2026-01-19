import express from "express";
import routes from "./routes/index.js";
const app = express();

// Middleware
app.use(express.json());

app.use("/api", routes);

app.get("/", (req, res) => {
  res.send("API is running...");
});

export default app;

import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key-here";

const authMiddleware = (req, res, next) => {
    try {
        const token = req.headers.authorization?.split(" ")[1];

        if (!token) {
            return res.status(401).json({ message: "No token provided" });
        }

        const decoded = jwt.verify(token, JWT_SECRET);
        req.userId = decoded.userId;
        req.userEmail = decoded.email;
        next();
    } catch (error) {
        res.status(401).json({ message: "Invalid token" });
    }
};

export const requireSelfOrAdmin = (req, res, next) => {
    const targetId = req.params.id;

    if (req.user?.role === "admin" || req.userId === targetId) {
        return next();
    }

    return res.status(403).json({ message: "Forbidden" });
};

export default authMiddleware;

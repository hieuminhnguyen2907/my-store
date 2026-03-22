import jwt from "jsonwebtoken";
import User from "../modules/user/user.model.js";

const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key-here";

const authMiddleware = async (req, res, next) => {
    try {
        const token = req.headers.authorization?.split(" ")[1];

        if (!token) {
            return res.status(401).json({ message: "No token provided" });
        }

        const decoded = jwt.verify(token, JWT_SECRET);
        req.userId = decoded.userId;
        req.userEmail = decoded.email;

        if (decoded.role) {
            req.userRole = decoded.role;
        } else {
            const user = await User.findById(decoded.userId).select("role");
            req.userRole = user?.role || "user";
        }

        next();
    } catch (error) {
        res.status(401).json({ message: "Invalid token" });
    }
};

export const requireSelfOrAdmin = (req, res, next) => {
    const targetId = req.params.id;

    if (req.userRole === "admin" || req.userId === targetId) {
        return next();
    }

    return res.status(403).json({ message: "Forbidden" });
};

export const requireAdmin = (req, res, next) => {
    if (req.userRole !== "admin") {
        return res.status(403).json({ message: "Admin access required" });
    }
    return next();
};

// Admin middleware - no auth required, direct admin access
export const adminMiddleware = (req, res, next) => {
    req.userId = "admin_user";
    req.userRole = "admin";
    req.userEmail = "admin@bigcart.local";
    next();
};

export default authMiddleware;

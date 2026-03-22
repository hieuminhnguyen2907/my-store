import { Router } from "express";
import {
  register,
  login,
  forgotPassword,
  getCurrentUser,
  createUser,
  getUsers,
  getUserById,
  updateUser,
  deleteUser,
} from "./user.controller.js";
import authMiddleware, {
  requireAdmin,
  requireSelfOrAdmin,
  adminMiddleware,
} from "../../middleware/auth.js";

const router = Router();

// Auth routes
router.post("/register", register);
router.post("/login", login);
router.post("/forgot-password", forgotPassword);
router.get("/current", authMiddleware, getCurrentUser);

// CRUD routes
router.post("/", adminMiddleware, createUser);
router.get("/", adminMiddleware, getUsers);
router.get("/:id", authMiddleware, requireSelfOrAdmin, getUserById);
router.put("/:id", authMiddleware, requireSelfOrAdmin, updateUser);
router.delete("/:id", adminMiddleware, deleteUser);

export default router;

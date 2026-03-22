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
import authMiddleware from "../../middleware/auth.js";

const router = Router();

// Auth routes
router.post("/register", register);
router.post("/login", login);
router.post("/forgot-password", forgotPassword);
router.get("/current", authMiddleware, getCurrentUser);

// CRUD routes
router.post("/", createUser);
router.get("/", authMiddleware, getUsers);
router.get("/:id", authMiddleware, getUserById);
router.put("/:id", authMiddleware, updateUser);
router.delete("/:id", authMiddleware, deleteUser);

export default router;

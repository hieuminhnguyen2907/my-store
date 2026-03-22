import { Router } from "express";
import authMiddleware, {
    requireAdmin,
    adminMiddleware,
} from "../../middleware/auth.js";
import {
    createOrder,
    getMyOrders,
    getOrders,
    getOrderById,
    updateOrderStatus,
    updateOrderPayment,
} from "./order.controller.js";

const router = Router();

router.post("/", authMiddleware, createOrder);
router.get("/my", authMiddleware, getMyOrders);
router.get("/", adminMiddleware, getOrders);
router.get("/:id", authMiddleware, getOrderById);
router.patch("/:id/status", adminMiddleware, updateOrderStatus);
router.patch("/:id/payment", adminMiddleware, updateOrderPayment);

export default router;

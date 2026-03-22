import { Router } from "express";
import {
    createMomoPayment,
    getMomoPaymentStatus,
    momoIpnHandler,
    momoReturnHandler,
} from "./payment.controller.js";

const router = Router();

router.post("/momo/create", createMomoPayment);
router.get("/momo/status/:orderId", getMomoPaymentStatus);
router.post("/momo/ipn", momoIpnHandler);
router.get("/momo/return", momoReturnHandler);

export default router;

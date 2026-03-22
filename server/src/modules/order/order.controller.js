import mongoose from "mongoose";
import Order from "./order.model.js";

const toOrderResponse = (order) => ({
    id: order._id,
    user: order.user,
    items: order.items,
    subtotal: order.subtotal,
    shipping: order.shipping,
    total: order.total,
    receiverName: order.receiverName,
    receiverPhone: order.receiverPhone,
    shippingAddress: order.shippingAddress,
    status: order.status,
    paymentMethod: order.paymentMethod,
    paymentStatus: order.paymentStatus,
    paymentGatewayOrderId: order.paymentGatewayOrderId || null,
    createdAt: order.createdAt,
    updatedAt: order.updatedAt,
});

const validateObjectId = (id) => mongoose.Types.ObjectId.isValid(id);

export const createOrder = async (req, res) => {
    try {
        const {
            items,
            subtotal,
            shipping,
            total,
            receiverName,
            receiverPhone,
            shippingAddress,
            status,
            paymentMethod,
            paymentStatus,
            paymentGatewayOrderId,
        } = req.body;

        if (!Array.isArray(items) || items.length === 0) {
            return res.status(400).json({ message: "items are required" });
        }

        const mappedItems = items.map((item) => ({
            productId: validateObjectId(item.productId) ? item.productId : undefined,
            productName: item.productName || "Unknown product",
            productImage: item.productImage || "",
            quantity: Number(item.quantity || 1),
            unitPrice: Number(item.unitPrice || 0),
            subtotal:
                Number(item.subtotal) || Number(item.unitPrice || 0) * Number(item.quantity || 1),
        }));

        const order = await Order.create({
            user: req.userId,
            items: mappedItems,
            subtotal: Number(subtotal || 0),
            shipping: Number(shipping || 0),
            total: Number(total || 0),
            receiverName,
            receiverPhone,
            shippingAddress,
            status: status || "placed",
            paymentMethod: paymentMethod || "cod",
            paymentStatus: paymentStatus || "unpaid",
            paymentGatewayOrderId: paymentGatewayOrderId || null,
        });

        return res.status(201).json(toOrderResponse(order));
    } catch (error) {
        return res.status(400).json({ message: error.message });
    }
};

export const getMyOrders = async (req, res) => {
    try {
        const orders = await Order.find({ user: req.userId }).sort({ createdAt: -1 });
        return res.json(orders.map(toOrderResponse));
    } catch (error) {
        return res.status(500).json({ message: error.message });
    }
};

export const getOrders = async (req, res) => {
    try {
        const { status, paymentStatus, userId, keyword } = req.query;
        const query = {};

        if (status) {
            query.status = status;
        }
        if (paymentStatus) {
            query.paymentStatus = paymentStatus;
        }
        if (userId && validateObjectId(userId)) {
            query.user = userId;
        }

        if (keyword) {
            query.$or = [
                { receiverName: { $regex: keyword, $options: "i" } },
                { receiverPhone: { $regex: keyword, $options: "i" } },
                { shippingAddress: { $regex: keyword, $options: "i" } },
            ];
        }

        const orders = await Order.find(query)
            .populate("user", "name email phone role")
            .sort({ createdAt: -1 });

        return res.json(orders.map(toOrderResponse));
    } catch (error) {
        return res.status(500).json({ message: error.message });
    }
};

export const getOrderById = async (req, res) => {
    try {
        const { id } = req.params;
        if (!validateObjectId(id)) {
            return res.status(400).json({ message: "Invalid order ID" });
        }

        const order = await Order.findById(id).populate("user", "name email phone role");
        if (!order) {
            return res.status(404).json({ message: "Order not found" });
        }

        if (req.userRole !== "admin" && `${order.user?._id || order.user}` !== req.userId) {
            return res.status(403).json({ message: "Forbidden" });
        }

        return res.json(toOrderResponse(order));
    } catch (error) {
        return res.status(500).json({ message: error.message });
    }
};

export const updateOrderStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        if (!validateObjectId(id)) {
            return res.status(400).json({ message: "Invalid order ID" });
        }

        const order = await Order.findById(id);
        if (!order) {
            return res.status(404).json({ message: "Order not found" });
        }

        order.status = status || order.status;
        await order.save();

        return res.json(toOrderResponse(order));
    } catch (error) {
        return res.status(400).json({ message: error.message });
    }
};

export const updateOrderPayment = async (req, res) => {
    try {
        const { id } = req.params;
        const { paymentStatus, paymentGatewayOrderId, status } = req.body;

        if (!validateObjectId(id)) {
            return res.status(400).json({ message: "Invalid order ID" });
        }

        const order = await Order.findById(id);
        if (!order) {
            return res.status(404).json({ message: "Order not found" });
        }

        const isOwner = `${order.user}` === req.userId;
        if (req.userRole !== "admin" && !isOwner) {
            return res.status(403).json({ message: "Forbidden" });
        }

        if (paymentStatus) {
            order.paymentStatus = paymentStatus;
        }
        if (paymentGatewayOrderId !== undefined) {
            order.paymentGatewayOrderId = paymentGatewayOrderId;
        }
        if (status) {
            order.status = status;
        }

        await order.save();
        return res.json(toOrderResponse(order));
    } catch (error) {
        return res.status(400).json({ message: error.message });
    }
};

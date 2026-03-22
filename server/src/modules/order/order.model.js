import mongoose from "mongoose";

const orderItemSchema = new mongoose.Schema(
    {
        productId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Product",
            required: false,
        },
        productName: {
            type: String,
            required: true,
            trim: true,
        },
        productImage: {
            type: String,
            default: "",
        },
        quantity: {
            type: Number,
            required: true,
            min: 1,
        },
        unitPrice: {
            type: Number,
            required: true,
            min: 0,
        },
        subtotal: {
            type: Number,
            required: true,
            min: 0,
        },
    },
    { _id: false }
);

const orderSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true,
        },
        items: {
            type: [orderItemSchema],
            default: [],
        },
        subtotal: {
            type: Number,
            required: true,
            min: 0,
        },
        shipping: {
            type: Number,
            required: true,
            min: 0,
            default: 0,
        },
        total: {
            type: Number,
            required: true,
            min: 0,
        },
        receiverName: {
            type: String,
            default: "",
            trim: true,
        },
        receiverPhone: {
            type: String,
            default: "",
            trim: true,
        },
        shippingAddress: {
            type: String,
            default: "",
            trim: true,
        },
        status: {
            type: String,
            enum: [
                "pending_payment",
                "placed",
                "processing",
                "shipping",
                "completed",
                "cancelled",
                "payment_failed",
            ],
            default: "placed",
            index: true,
        },
        paymentMethod: {
            type: String,
            enum: ["cod", "momo"],
            default: "cod",
        },
        paymentStatus: {
            type: String,
            enum: ["unpaid", "pending", "paid", "failed"],
            default: "unpaid",
            index: true,
        },
        paymentGatewayOrderId: {
            type: String,
            default: null,
        },
    },
    {
        timestamps: true,
    }
);

export default mongoose.model("Order", orderSchema);

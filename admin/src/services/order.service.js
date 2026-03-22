import axiosClient from "../api/axios";

export const orderService = {
    getAll: (params = {}) => axiosClient.get("/orders", { params }),
    updateStatus: (id, status) =>
        axiosClient.patch(`/orders/${id}/status`, { status }),
    updatePayment: (id, payload) =>
        axiosClient.patch(`/orders/${id}/payment`, payload),
};

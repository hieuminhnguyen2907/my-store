import axiosClient from "../api/axios";

export const productService = {
    getAll: (params = {}) => axiosClient.get("/products", { params }),
    getById: (id) => axiosClient.get(`/products/${id}`),
    create: (data) => axiosClient.post("/products", data),
    update: (id, data) => axiosClient.put(`/products/${id}`, data),
    delete: (id) => axiosClient.delete(`/products/${id}`),
};

import axiosClient from "../api/axios";

export const userService = {
    login: (payload) => axiosClient.post("/users/login", payload),
    getAll: () => axiosClient.get("/users"),
    create: (payload) => axiosClient.post("/users", payload),
    update: (id, payload) => axiosClient.put(`/users/${id}`, payload),
    delete: (id) => axiosClient.delete(`/users/${id}`),
};

import { Router } from "express";
import {
  createProduct,
  getProducts,
  getFeaturedProducts,
  getProductsByCategory,
  getProductById,
  updateProduct,
  deleteProduct,
} from "./product.controller.js";

const router = Router();

router.post("/", createProduct);
router.get("/", getProducts);
router.get("/featured", getFeaturedProducts);
router.get("/category/:categoryId", getProductsByCategory);
router.get("/:id", getProductById);
router.put("/:id", updateProduct);
router.delete("/:id", deleteProduct);

export default router;

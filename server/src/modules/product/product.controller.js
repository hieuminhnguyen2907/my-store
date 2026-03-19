import Product from "./product.model.js";
import Category from "../category/category.model.js";

const escapeRegex = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

/**
 * CREATE product
 */
export const createProduct = async (req, res) => {
  try {
    const product = await Product.create(req.body);
    res.status(201).json(product);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

/**
 * GET all products
 */
export const getProducts = async (req, res) => {
  try {
    const { category, search, featured } = req.query;
    const filter = { isActive: true };

    if (featured === "true") {
      filter.stock = { $gt: 0 };
    }

    if (category) {
      const isObjectId = /^[a-fA-F0-9]{24}$/.test(category);
      if (isObjectId) {
        filter.category = category;
      } else {
        const categoryDoc = await Category.findOne({
          name: { $regex: `^${escapeRegex(category)}$`, $options: "i" },
        }).select("_id");
        if (categoryDoc) {
          filter.category = categoryDoc._id;
        }
      }
    }

    if (search) {
      const searchRegex = { $regex: escapeRegex(search), $options: "i" };
      filter.$or = [{ name: searchRegex }, { description: searchRegex }];
    }

    const query = Product.find(filter)
      .populate("category", "name")
      .sort({ createdAt: -1 });

    if (featured === "true") {
      query.limit(8);
    }

    const products = await query;

    res.json(products);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/**
 * GET product by ID
 */
export const getProductById = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id).populate(
      "category",
      "name"
    );

    if (!product)
      return res.status(404).json({ message: "Product not found" });

    res.json(product);
  } catch (error) {
    res.status(400).json({ message: "Invalid ID" });
  }
};

/**
 * GET featured products
 */
export const getFeaturedProducts = async (req, res) => {
  try {
    const products = await Product.find({ isActive: true, stock: { $gt: 0 } })
      .populate("category", "name")
      .sort({ createdAt: -1 })
      .limit(8);

    res.json(products);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/**
 * GET products by category ID
 */
export const getProductsByCategory = async (req, res) => {
  try {
    const products = await Product.find({
      category: req.params.categoryId,
      isActive: true,
    })
      .populate("category", "name")
      .sort({ createdAt: -1 });

    res.json(products);
  } catch (error) {
    res.status(400).json({ message: "Invalid category ID" });
  }
};

/**
 * UPDATE product
 */
export const updateProduct = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product)
      return res.status(404).json({ message: "Product not found" });

    Object.assign(product, req.body);
    await product.save();

    res.json(product);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

/**
 * DELETE product
 */
export const deleteProduct = async (req, res) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product)
      return res.status(404).json({ message: "Product not found" });

    res.json({ message: "Product deleted successfully" });
  } catch (error) {
    res.status(400).json({ message: "Invalid ID" });
  }
};

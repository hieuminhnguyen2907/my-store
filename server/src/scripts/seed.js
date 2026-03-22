import dotenv from "dotenv";
import mongoose from "mongoose";
import connectDB from "../config/db.js";
import Category from "../modules/category/category.model.js";
import Product from "../modules/product/product.model.js";

dotenv.config();

const categorySeeds = [
    {
        key: "women",
        name: "Women",
        description: "Fashion for women: dresses, tops, skirts and accessories.",
        image: "https://picsum.photos/seed/big-cart-women/900/600",
        isActive: true,
    },
    {
        key: "men",
        name: "Men",
        description: "Fashion for men: shirts, hoodies, pants and essentials.",
        image: "https://picsum.photos/seed/big-cart-men/900/600",
        isActive: true,
    },
    {
        key: "accessories",
        name: "Accessories",
        description: "Bags, watches, belts and everyday style add-ons.",
        image: "https://picsum.photos/seed/big-cart-accessories/900/600",
        isActive: true,
    },
    {
        key: "beauty",
        name: "Beauty",
        description: "Skincare, bodycare and beauty essentials.",
        image: "https://picsum.photos/seed/big-cart-beauty/900/600",
        isActive: true,
    },
];

const productSeeds = [
    {
        name: "Elegant Women Dress",
        description: "Soft autumn dress for women, ideal for office and weekend.",
        price: 59.9,
        stock: 35,
        unit: "piece",
        image: "/images/products/women_dress.jpg",
        categoryKey: "women",
        isActive: true,
    },
    {
        name: "Casual Women Blouse",
        description: "Lightweight blouse for daily wear with clean minimal style.",
        price: 34.5,
        stock: 42,
        unit: "piece",
        image: "/images/products/women_blouse.jpg",
        categoryKey: "women",
        isActive: true,
    },
    {
        name: "Men Oxford Shirt",
        description: "Classic men shirt suitable for work and smart-casual outfits.",
        price: 44.9,
        stock: 28,
        unit: "piece",
        image: "/images/products/men_oxford_shirt.jpg",
        categoryKey: "men",
        isActive: true,
    },
    {
        name: "Men Street Hoodie",
        description: "Warm men hoodie with relaxed fit for cool weather.",
        price: 49.0,
        stock: 20,
        unit: "piece",
        image: "/images/products/men_street_hoodie.jpg",
        categoryKey: "men",
        isActive: true,
    },
    {
        name: "Leather Belt Classic",
        description: "Genuine leather belt to match formal and casual looks.",
        price: 22.0,
        stock: 50,
        unit: "piece",
        image: "/images/products/leather_belt.jpg",
        categoryKey: "accessories",
        isActive: true,
    },
    {
        name: "Minimalist Wrist Watch",
        description: "Simple elegant watch with stainless steel case.",
        price: 89.0,
        stock: 18,
        unit: "piece",
        image: "/images/products/minimalist_watch.jpg",
        categoryKey: "accessories",
        isActive: true,
    },
    {
        name: "Hydrating Skin Serum",
        description: "Beauty serum for daily hydration and smoother skin.",
        price: 27.5,
        stock: 36,
        unit: "piece",
        image: "/images/products/skin_serum.jpg",
        categoryKey: "beauty",
        isActive: true,
    },
    {
        name: "Gentle Beauty Cleanser",
        description: "Mild face cleanser for all skin types.",
        price: 19.9,
        stock: 60,
        unit: "piece",
        image: "/images/products/beauty_cleanser.jpg",
        categoryKey: "beauty",
        isActive: true,
    },
    {
        name: "Sold Out Test Product",
        description: "Used to verify featured flow excludes stock zero products.",
        price: 14.0,
        stock: 0,
        unit: "piece",
        image: "/images/products/soldout_test.jpg",
        categoryKey: "accessories",
        isActive: true,
    },
];

const run = async () => {
    const fresh = process.argv.includes("--fresh");

    try {
        await connectDB();

        if (fresh) {
            await Product.deleteMany({});
            await Category.deleteMany({});
            console.log("🧹 Cleared old categories and products");
        }

        const categoryByKey = {};

        for (const categorySeed of categorySeeds) {
            const { key, ...categoryPayload } = categorySeed;
            const category = await Category.findOneAndUpdate(
                { name: categoryPayload.name },
                { $set: categoryPayload },
                { new: true, upsert: true, runValidators: true }
            );
            categoryByKey[key] = category;
        }

        for (const productSeed of productSeeds) {
            const { categoryKey, ...productPayload } = productSeed;
            const category = categoryByKey[categoryKey];

            if (!category) {
                throw new Error(`Missing category for product: ${productPayload.name}`);
            }

            await Product.findOneAndUpdate(
                { name: productPayload.name },
                {
                    $set: {
                        ...productPayload,
                        category: category._id,
                    },
                },
                { new: true, upsert: true, runValidators: true }
            );
        }

        const categoryCount = await Category.countDocuments();
        const productCount = await Product.countDocuments();

        console.log(`✅ Seed completed. Categories: ${categoryCount}, Products: ${productCount}`);
        console.log("💡 Run with --fresh to reset category/product data before seeding");
        await mongoose.connection.close();
        process.exit(0);
    } catch (error) {
        console.error("❌ Seed failed:", error);
        await mongoose.connection.close();
        process.exit(1);
    }
};

run();
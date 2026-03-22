import dotenv from "dotenv";
import mongoose from "mongoose";
import connectDB from "../config/db.js";
import Category from "../modules/category/category.model.js";
import Product from "../modules/product/product.model.js";

dotenv.config();

const categorySeeds = [
    {
        key: "women",
        name: "Thời trang nữ",
        description: "Đầm, áo kiểu, chân váy và sản phẩm thời trang dành cho nữ.",
        image: "https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?q=80&w=1200&auto=format&fit=crop",
        isActive: true,
    },
    {
        key: "men",
        name: "Thời trang nam",
        description: "Áo sơ mi, áo thun, hoodie và phụ kiện phong cách nam.",
        image: "https://images.unsplash.com/photo-1516257984-b1b4d707412e?q=80&w=1200&auto=format&fit=crop",
        isActive: true,
    },
    {
        key: "accessories",
        name: "Phụ kiện",
        description: "Túi, đồng hồ, thắt lưng và phụ kiện hoàn thiện trang phục.",
        image: "https://images.unsplash.com/photo-1523170335258-f5ed11844a49?q=80&w=1200&auto=format&fit=crop",
        isActive: true,
    },
    {
        key: "beauty",
        name: "Chăm sóc cá nhân",
        description: "Serum, sữa rửa mặt và các sản phẩm chăm sóc da hằng ngày.",
        image: "https://images.unsplash.com/photo-1556228720-195a672e8a03?q=80&w=1200&auto=format&fit=crop",
        isActive: true,
    },
];

const productSeeds = [
    {
        name: "Áo dài lụa trắng",
        description: "Áo dài truyền thống chất liệu lụa mềm, phù hợp sự kiện trang trọng.",
        price: 620000,
        stock: 24,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "women",
        isActive: true,
    },
    {
        name: "Váy hoa nhí mùa hè",
        description: "Váy voan nhẹ nhàng, tông hoa nhí phù hợp đi chơi cuối tuần.",
        price: 420000,
        stock: 38,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1496747611176-843222e1e57c?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "women",
        isActive: true,
    },
    {
        name: "Áo sơ mi công sở nữ",
        description: "Phom đứng, chất cotton thoáng mát cho môi trường văn phòng.",
        price: 360000,
        stock: 44,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1554412933-514a83d2f3c8?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "women",
        isActive: true,
    },
    {
        name: "Chân váy xếp ly midi",
        description: "Chân váy xếp ly dài qua gối, dễ phối cùng áo sơ mi hoặc áo thun.",
        price: 390000,
        stock: 32,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "women",
        isActive: true,
    },
    {
        name: "Áo sơ mi nam linen",
        description: "Sơ mi nam chất liệu linen, thấm hút tốt, phù hợp thời tiết nóng.",
        price: 365000,
        stock: 46,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "men",
        isActive: true,
    },
    {
        name: "Áo thun nam cổ tròn",
        description: "Áo thun basic co giãn tốt, mặc hàng ngày thoải mái.",
        price: 220000,
        stock: 65,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1581655353564-df123a1eb820?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "men",
        isActive: true,
    },
    {
        name: "Áo hoodie nỉ nam",
        description: "Giữ ấm tốt, kiểu dáng trẻ trung cho mùa lạnh.",
        price: 480000,
        stock: 34,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1556821840-3a63f95609a7?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "men",
        isActive: true,
    },
    {
        name: "Quần jean nam ống đứng",
        description: "Quần jean xanh đậm, form đứng dễ phối với áo sơ mi và áo thun.",
        price: 510000,
        stock: 29,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1542272604-787c3835535d?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "men",
        isActive: true,
    },
    {
        name: "Túi tote canvas",
        description: "Túi tote vải canvas dày, phù hợp đi học và đi làm.",
        price: 190000,
        stock: 74,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1594223274512-ad4803739b7c?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "accessories",
        isActive: true,
    },
    {
        name: "Túi đeo chéo da",
        description: "Túi da nhỏ gọn, phong cách thanh lịch khi đi chơi hoặc đi làm.",
        price: 540000,
        stock: 27,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1548036328-c9fa89d128fa?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "accessories",
        isActive: true,
    },
    {
        name: "Thắt lưng da bò",
        description: "Bản 3.5cm, khóa kim loại, phù hợp trang phục công sở.",
        price: 260000,
        stock: 58,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1624222247344-550fb60583dc?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "accessories",
        isActive: true,
    },
    {
        name: "Đồng hồ dây da tối giản",
        description: "Mặt đồng hồ thanh mảnh, dây da nâu phong cách cổ điển.",
        price: 890000,
        stock: 19,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1523170335258-f5ed11844a49?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "accessories",
        isActive: true,
    },
    {
        name: "Kính mát gọng tròn",
        description: "Tròng chống UV, kiểu gọng tròn hợp thời trang.",
        price: 340000,
        stock: 41,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1511499767150-a48a237f0083?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "accessories",
        isActive: true,
    },
    {
        name: "Serum vitamin C sáng da",
        description: "Tinh chất vitamin C hỗ trợ làm sáng và đều màu da.",
        price: 345000,
        stock: 52,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1571781926291-c477ebfd024b?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "beauty",
        isActive: true,
    },
    {
        name: "Sữa rửa mặt dịu nhẹ",
        description: "Làm sạch bụi bẩn và dầu thừa, phù hợp da nhạy cảm.",
        price: 165000,
        stock: 86,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "beauty",
        isActive: true,
    },
    {
        name: "Kem chống nắng SPF50",
        description: "Kết cấu mỏng nhẹ, chống nắng phổ rộng UVA/UVB.",
        price: 280000,
        stock: 63,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "beauty",
        isActive: true,
    },
    {
        name: "Son kem lì màu đất",
        description: "Màu đất trendy, lâu trôi và lên màu chuẩn.",
        price: 210000,
        stock: 77,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "beauty",
        isActive: true,
    },
    {
        name: "Nước tẩy trang micellar",
        description: "Làm sạch lớp trang điểm nhẹ nhàng, không gây khô da.",
        price: 195000,
        stock: 68,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1556229010-aa3f7ff66b24?q=80&w=1000&auto=format&fit=crop",
        categoryKey: "beauty",
        isActive: true,
    },
    {
        name: "Sản phẩm mẫu hết hàng",
        description: "Sản phẩm dùng để kiểm tra luồng hiển thị hết hàng trên app.",
        price: 99000,
        stock: 0,
        unit: "piece",
        image: "https://images.unsplash.com/photo-1612423284934-2850a4ea6b0f?q=80&w=1000&auto=format&fit=crop",
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